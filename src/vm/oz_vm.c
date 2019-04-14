#include "oz_vm.h"
#include "oz_builtins.h"
#include "oz_space.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declarations from oz_scheduler.c */
OzThread *oz_thread_create(uint32_t entry_pc);
void oz_thread_destroy(OzThread *t);
void oz_scheduler_enqueue_thread(OzThread *thread);
OzThread *oz_scheduler_dequeue_thread(void);
void oz_scheduler_set_current(OzThread *thread);
size_t oz_scheduler_runnable_count(void);
void oz_thread_suspend(OzThread *thread, OzValue *unbound_var);

/* Forward declaration from oz_unify.c */
bool oz_unify(OzStore *store, OzValue *v1, OzValue *v2);

#define OZ_MAX_REGISTERS 256

struct OzThread {
    uint32_t thread_id;
    int state;
    uint32_t pc;
    int32_t instruction_budget;
    OzValue *registers[OZ_MAX_REGISTERS];
    /* Remaining fields matching oz_scheduler.c */
};

OzVM *oz_vm_create(void) {
    oz_builtins_init();
    OzVM *vm = (OzVM *)calloc(1, sizeof(OzVM));
    vm->store = oz_store_create();
    vm->is_running = false;
    vm->exit_code = 0;
    return vm;
}

void oz_vm_destroy(OzVM *vm) {
    if (!vm) return;
    if (vm->chunk) {
        oz_chunk_destroy(vm->chunk);
    }
    if (vm->store) {
        oz_store_destroy(vm->store);
    }
    free(vm);
}

bool oz_vm_load_chunk(OzVM *vm, OzBytecodeChunk *chunk) {
    if (!vm || !chunk) return false;
    if (vm->chunk) {
        oz_chunk_destroy(vm->chunk);
    }
    vm->chunk = chunk;
    return true;
}

bool oz_vm_step_thread(OzVM *vm, OzThread *thread) {
    if (!vm || !vm->chunk || !thread) return false;

    if (thread->pc >= vm->chunk->code_count) {
        return false; /* Thread reached end of instructions */
    }

    uint32_t instr = vm->chunk->code[thread->pc++];
    OzOpcode op = OZ_INSTR_OP(instr);
    uint8_t a = OZ_INSTR_A(instr);
    uint8_t b = OZ_INSTR_B(instr);
    uint8_t c = OZ_INSTR_C(instr);

    switch (op) {
        case OP_HALT:
            return false;

        case OP_MOVE: {
            if (thread->registers[a]) oz_val_release(thread->registers[a]);
            thread->registers[a] = thread->registers[b];
            if (thread->registers[a]) oz_val_retain(thread->registers[a]);
            break;
        }

        case OP_LOAD_K: {
            if (b < vm->chunk->const_count) {
                if (thread->registers[a]) oz_val_release(thread->registers[a]);
                thread->registers[a] = vm->chunk->constants[b];
                if (thread->registers[a]) oz_val_retain(thread->registers[a]);
            }
            break;
        }

        case OP_MAKE_UNBOUND: {
            if (thread->registers[a]) oz_val_release(thread->registers[a]);
            thread->registers[a] = oz_store_alloc_unbound(vm->store);
            break;
        }

        case OP_UNIFY: {
            OzValue *v1 = thread->registers[a];
            OzValue *v2 = thread->registers[b];
            if (!v1) {
                v1 = oz_store_alloc_unbound(vm->store);
                thread->registers[a] = v1;
            }
            if (!v2) {
                v2 = oz_store_alloc_unbound(vm->store);
                thread->registers[b] = v2;
            }
            if (!oz_unify(vm->store, v1, v2)) {
                fprintf(stderr, "[ozvm] Unification failure in thread #%u\n", thread->thread_id);
                return false;
            }
            break;
        }

        case OP_SUSPEND_IF: {
            OzValue *v = thread->registers[a];
            if (v && !oz_is_determined(v)) {
                oz_thread_suspend(thread, v);
                return true; /* Thread suspended, scheduler will switch */
            }
            break;
        }

        case OP_CALL: {
            OzValue *target = thread->registers[a];
            if (!target) break;
            OzValue *d = oz_deref(target);
            if (d->type == OZ_VAL_ATOM) {
                /* Builtin call */
                const char *name = oz_atom_name(d->as.atom_id);
                OzBuiltinFn fn = oz_builtin_lookup("System", name, b);
                if (fn) {
                    OzValue *args[16];
                    for (uint8_t i = 0; i < b && i < 16; ++i) {
                        args[i] = thread->registers[a + 1 + i];
                    }
                    fn(vm->store, b, args);
                }
            }
            break;
        }

        case OP_SPAWN: {
            OzThread *new_thread = oz_thread_create(thread->pc);
            /* Copy registers */
            for (int i = 0; i < OZ_MAX_REGISTERS; ++i) {
                if (thread->registers[i]) {
                    new_thread->registers[i] = thread->registers[i];
                    oz_val_retain(new_thread->registers[i]);
                }
            }
            oz_scheduler_enqueue_thread(new_thread);
            break;
        }

        case OP_NEW_PORT: {
            OzValue *stream_var = oz_store_alloc_unbound(vm->store);
            OzValue *port_var = oz_store_alloc_unbound(vm->store);
            OzValue *args[2] = { stream_var, port_var };
            oz_builtin_port_new(vm->store, 2, args);
            thread->registers[a] = stream_var;
            thread->registers[b] = port_var;
            break;
        }

        case OP_SEND: {
            OzValue *port = thread->registers[a];
            OzValue *msg = thread->registers[b];
            OzValue *args[2] = { port, msg };
            oz_builtin_port_send(vm->store, 2, args);
            break;
        }

        case OP_SPACE_NEW: {
            OzValue *proc = thread->registers[b];
            OzSpace *sp = oz_space_create(NULL, vm->store, proc);
            OzValue *sp_val = (OzValue *)calloc(1, sizeof(OzValue));
            sp_val->type = OZ_VAL_SPACE;
            sp_val->ref_count = 1;
            sp_val->as.space.space_ptr = sp;
            thread->registers[a] = sp_val;
            break;
        }

        case OP_SPACE_ASK: {
            OzValue *sp_val = oz_deref(thread->registers[a]);
            if (sp_val && sp_val->type == OZ_VAL_SPACE) {
                uint32_t alts = 0;
                OzSpaceStatus stat = oz_space_ask(sp_val->as.space.space_ptr, &alts);
                const char *stat_str = (stat == OZ_SPACE_FAILED) ? "failed" : (stat == OZ_SPACE_SUCCEEDED ? "succeeded" : "alternatives");
                thread->registers[b] = oz_val_create_atom_name(stat_str);
                thread->registers[c] = oz_val_create_int(alts);
            }
            break;
        }

        case OP_SPACE_CLONE: {
            OzValue *sp_val = oz_deref(thread->registers[b]);
            if (sp_val && sp_val->type == OZ_VAL_SPACE) {
                OzSpace *cloned = oz_space_clone(sp_val->as.space.space_ptr);
                OzValue *copy_val = (OzValue *)calloc(1, sizeof(OzValue));
                copy_val->type = OZ_VAL_SPACE;
                copy_val->ref_count = 1;
                copy_val->as.space.space_ptr = cloned;
                thread->registers[a] = copy_val;
            }
            break;
        }

        case OP_SPACE_COMMIT: {
            OzValue *sp_val = oz_deref(thread->registers[a]);
            if (sp_val && sp_val->type == OZ_VAL_SPACE) {
                oz_space_commit(sp_val->as.space.space_ptr, b);
            }
            break;
        }

        default:
            break;
    }

    return true;
}

int oz_vm_run(OzVM *vm) {
    if (!vm || !vm->chunk) return 1;

    OzThread *main_thread = oz_thread_create(0);
    oz_scheduler_enqueue_thread(main_thread);

    vm->is_running = true;

    while (oz_scheduler_runnable_count() > 0 && vm->is_running) {
        OzThread *t = oz_scheduler_dequeue_thread();
        if (!t) break;

        oz_scheduler_set_current(t);
        t->instruction_budget = 500;

        bool active = true;
        while (active && t->instruction_budget-- > 0) {
            active = oz_vm_step_thread(vm, t);
        }

        if (active) {
            /* Still runnable, put back on round-robin queue */
            oz_scheduler_enqueue_thread(t);
        } else {
            /* Terminated */
            oz_thread_destroy(t);
        }
    }

    return vm->exit_code;
}
