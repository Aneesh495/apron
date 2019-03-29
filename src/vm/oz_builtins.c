#include "oz_builtins.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

/* Forward declaration */
bool oz_unify(OzStore *store, OzValue *v1, OzValue *v2);

OzValue *oz_builtin_system_show(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc > 0 && argv[0]) {
        oz_val_print(argv[0]);
        printf("\n");
        fflush(stdout);
    }
    return oz_val_create_nil();
}

OzValue *oz_builtin_system_print_info(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc > 0 && argv[0]) {
        printf("[apron-info] ");
        oz_val_print(argv[0]);
        printf("\n");
        fflush(stdout);
    }
    return oz_val_create_nil();
}

OzValue *oz_builtin_app_exit(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    int code = 0;
    if (argc > 0 && argv[0]) {
        OzValue *d = oz_deref(argv[0]);
        if (d->type == OZ_VAL_INT) code = (int)d->as.int_val;
    }
    exit(code);
    return oz_val_create_nil();
}

OzValue *oz_builtin_time_time(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store; (void)argc; (void)argv;
    time_t now = time(NULL);
    return oz_val_create_int((int64_t)now);
}

OzValue *oz_builtin_list_length(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc == 0 || !argv[0]) return oz_val_create_int(0);
    OzValue *curr = oz_deref(argv[0]);
    int64_t count = 0;
    while (curr && curr->type == OZ_VAL_PAIR) {
        count++;
        curr = oz_deref(curr->as.pair.tail);
    }
    return oz_val_create_int(count);
}

OzValue *oz_builtin_list_reverse(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc == 0 || !argv[0]) return oz_val_create_nil();
    OzValue *curr = oz_deref(argv[0]);
    OzValue *acc = oz_val_create_nil();
    while (curr && curr->type == OZ_VAL_PAIR) {
        OzValue *head = oz_deref(curr->as.pair.head);
        acc = oz_val_create_pair(head, acc);
        curr = oz_deref(curr->as.pair.tail);
    }
    return acc;
}

OzValue *oz_builtin_list_append(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc < 2) return oz_val_create_nil();
    OzValue *l1 = oz_deref(argv[0]);
    OzValue *l2 = oz_deref(argv[1]);
    if (!l1 || l1->type == OZ_VAL_NIL) return l2 ? l2 : oz_val_create_nil();

    /* Reverse l1 into temp accumulator */
    OzValue *curr = l1;
    OzValue *rev = oz_val_create_nil();
    while (curr && curr->type == OZ_VAL_PAIR) {
        rev = oz_val_create_pair(oz_deref(curr->as.pair.head), rev);
        curr = oz_deref(curr->as.pair.tail);
    }
    /* Reverse back onto l2 */
    curr = rev;
    OzValue *result = l2 ? l2 : oz_val_create_nil();
    while (curr && curr->type == OZ_VAL_PAIR) {
        result = oz_val_create_pair(oz_deref(curr->as.pair.head), result);
        curr = oz_deref(curr->as.pair.tail);
    }
    return result;
}

OzValue *oz_builtin_record_label(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc == 0 || !argv[0]) return oz_val_create_nil();
    OzValue *d = oz_deref(argv[0]);
    if (d->type == OZ_VAL_RECORD) {
        return oz_val_create_atom(d->as.record.label_atom);
    } else if (d->type == OZ_VAL_TUPLE) {
        return oz_val_create_atom(d->as.tuple.label_atom);
    }
    return oz_val_create_nil();
}

OzValue *oz_builtin_record_arity(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc == 0 || !argv[0]) return oz_val_create_nil();
    OzValue *d = oz_deref(argv[0]);
    if (d->type == OZ_VAL_RECORD) {
        OzValue *list = oz_val_create_nil();
        for (int32_t i = (int32_t)d->as.record.num_features - 1; i >= 0; --i) {
            OzValue *feat_atom = oz_val_create_atom(d->as.record.features[i].key_atom);
            list = oz_val_create_pair(feat_atom, list);
        }
        return list;
    }
    return oz_val_create_nil();
}

static uint32_t g_next_port_id = 1;

OzValue *oz_builtin_port_new(OzStore *store, uint32_t argc, OzValue **argv) {
    if (argc < 2 || !argv[0] || !argv[1]) return oz_val_create_nil();
    OzValue *stream_var = argv[0];
    OzValue *port_var = argv[1];

    OzValue *port = oz_val_create_port(stream_var, g_next_port_id++);
    oz_unify(store, port_var, port);
    return port;
}

OzValue *oz_builtin_port_send(OzStore *store, uint32_t argc, OzValue **argv) {
    if (argc < 2 || !argv[0] || !argv[1]) return oz_val_create_nil();
    OzValue *port = oz_deref(argv[0]);
    OzValue *msg = argv[1];
    if (port->type != OZ_VAL_PORT) return oz_val_create_nil();

    /* Atomically bind tail_var = [msg | NewTail] */
    OzValue *curr_tail = port->as.port.tail_var;
    OzValue *new_tail = oz_store_alloc_unbound(store);
    OzValue *pair = oz_val_create_pair(msg, new_tail);

    oz_unify(store, curr_tail, pair);
    port->as.port.tail_var = new_tail;
    return oz_val_create_nil();
}

OzValue *oz_builtin_math_sqrt(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc == 0 || !argv[0]) return oz_val_create_float(0.0);
    OzValue *d = oz_deref(argv[0]);
    double v = (d->type == OZ_VAL_INT) ? (double)d->as.int_val : (d->type == OZ_VAL_FLOAT ? d->as.float_val : 0.0);
    return oz_val_create_float(sqrt(v));
}

OzValue *oz_builtin_math_abs(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc == 0 || !argv[0]) return oz_val_create_int(0);
    OzValue *d = oz_deref(argv[0]);
    if (d->type == OZ_VAL_INT) {
        return oz_val_create_int(d->as.int_val < 0 ? -d->as.int_val : d->as.int_val);
    } else if (d->type == OZ_VAL_FLOAT) {
        return oz_val_create_float(fabs(d->as.float_val));
    }
    return oz_val_create_int(0);
}

OzValue *oz_builtin_math_min(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc < 2 || !argv[0] || !argv[1]) return oz_val_create_int(0);
    OzValue *a = oz_deref(argv[0]);
    OzValue *b = oz_deref(argv[1]);
    if (a->type == OZ_VAL_INT && b->type == OZ_VAL_INT) {
        return oz_val_create_int(a->as.int_val < b->as.int_val ? a->as.int_val : b->as.int_val);
    }
    double va = (a->type == OZ_VAL_FLOAT) ? a->as.float_val : (double)a->as.int_val;
    double vb = (b->type == OZ_VAL_FLOAT) ? b->as.float_val : (double)b->as.int_val;
    return oz_val_create_float(va < vb ? va : vb);
}

OzValue *oz_builtin_math_max(OzStore *store, uint32_t argc, OzValue **argv) {
    (void)store;
    if (argc < 2 || !argv[0] || !argv[1]) return oz_val_create_int(0);
    OzValue *a = oz_deref(argv[0]);
    OzValue *b = oz_deref(argv[1]);
    if (a->type == OZ_VAL_INT && b->type == OZ_VAL_INT) {
        return oz_val_create_int(a->as.int_val > b->as.int_val ? a->as.int_val : b->as.int_val);
    }
    double va = (a->type == OZ_VAL_FLOAT) ? a->as.float_val : (double)a->as.int_val;
    double vb = (b->type == OZ_VAL_FLOAT) ? b->as.float_val : (double)b->as.int_val;
    return oz_val_create_float(va > vb ? va : vb);
}

static OzBuiltinEntry g_builtins[] = {
    { "System", "show", 1, oz_builtin_system_show },
    { "System", "printInfo", 1, oz_builtin_system_print_info },
    { "Application", "exit", 1, oz_builtin_app_exit },
    { "Time", "time", 0, oz_builtin_time_time },
    { "List", "length", 1, oz_builtin_list_length },
    { "List", "reverse", 1, oz_builtin_list_reverse },
    { "List", "append", 2, oz_builtin_list_append },
    { "Record", "label", 1, oz_builtin_record_label },
    { "Record", "arity", 1, oz_builtin_record_arity },
    { "Port", "new", 2, oz_builtin_port_new },
    { "Port", "send", 2, oz_builtin_port_send },
    { "Math", "sqrt", 1, oz_builtin_math_sqrt },
    { "Math", "abs", 1, oz_builtin_math_abs },
    { "Math", "min", 2, oz_builtin_math_min },
    { "Math", "max", 2, oz_builtin_math_max },
    { NULL, NULL, 0, NULL }
};

void oz_builtins_init(void) {
    /* Intern common built-in module names */
    oz_atom_intern("System");
    oz_atom_intern("Application");
    oz_atom_intern("Time");
    oz_atom_intern("List");
    oz_atom_intern("Record");
    oz_atom_intern("Port");
    oz_atom_intern("Space");
    oz_atom_intern("FD");
    oz_atom_intern("Math");
}

OzBuiltinFn oz_builtin_lookup(const char *module_name, const char *func_name, uint32_t arity) {
    (void)arity;
    for (size_t i = 0; g_builtins[i].module_name != NULL; ++i) {
        if (strcmp(g_builtins[i].module_name, module_name) == 0 &&
            strcmp(g_builtins[i].func_name, func_name) == 0) {
            return g_builtins[i].fn;
        }
    }
    return NULL;
}
