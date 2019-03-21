#include "oz_store.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    OZ_THREAD_READY = 0,
    OZ_THREAD_RUNNING,
    OZ_THREAD_SUSPENDED,
    OZ_THREAD_TERMINATED
} OzThreadState;

#define OZ_MAX_REGISTERS 256
#define OZ_MAX_CALL_STACK 128
#define OZ_DEFAULT_TIMESLICE 500

typedef struct OzCallFrame {
    uint32_t return_pc;
    uint32_t base_reg;
    OzValue *proc;
} OzCallFrame;

struct OzThread {
    uint32_t thread_id;
    OzThreadState state;
    uint32_t pc;
    int32_t instruction_budget;
    OzValue *registers[OZ_MAX_REGISTERS];
    OzCallFrame call_stack[OZ_MAX_CALL_STACK];
    uint32_t call_depth;
    OzValue *suspended_on;
    struct OzThread *next_run;
};

/* Scheduler Global State */
typedef struct OzScheduler {
    OzThread *run_queue_head;
    OzThread *run_queue_tail;
    OzThread *current_thread;
    uint32_t next_thread_id;
    size_t active_thread_count;
} OzScheduler;

static OzScheduler g_scheduler = { NULL, NULL, NULL, 1, 0 };

void oz_scheduler_enqueue_thread(OzThread *thread) {
    if (!thread || thread->state == OZ_THREAD_TERMINATED) return;
    thread->state = OZ_THREAD_READY;
    thread->next_run = NULL;
    thread->suspended_on = NULL;
    if (!g_scheduler.run_queue_head) {
        g_scheduler.run_queue_head = thread;
        g_scheduler.run_queue_tail = thread;
    } else {
        g_scheduler.run_queue_tail->next_run = thread;
        g_scheduler.run_queue_tail = thread;
    }
}

OzThread *oz_scheduler_dequeue_thread(void) {
    if (!g_scheduler.run_queue_head) return NULL;
    OzThread *t = g_scheduler.run_queue_head;
    g_scheduler.run_queue_head = t->next_run;
    if (!g_scheduler.run_queue_head) {
        g_scheduler.run_queue_tail = NULL;
    }
    t->next_run = NULL;
    return t;
}

OzThread *oz_thread_create(uint32_t entry_pc) {
    OzThread *t = (OzThread *)calloc(1, sizeof(OzThread));
    t->thread_id = g_scheduler.next_thread_id++;
    t->state = OZ_THREAD_READY;
    t->pc = entry_pc;
    t->instruction_budget = OZ_DEFAULT_TIMESLICE;
    g_scheduler.active_thread_count++;
    return t;
}

void oz_thread_destroy(OzThread *t) {
    if (!t) return;
    for (int i = 0; i < OZ_MAX_REGISTERS; ++i) {
        if (t->registers[i]) {
            oz_val_release(t->registers[i]);
            t->registers[i] = NULL;
        }
    }
    free(t);
    if (g_scheduler.active_thread_count > 0) {
        g_scheduler.active_thread_count--;
    }
}

void oz_thread_suspend(OzThread *thread, OzValue *unbound_var) {
    if (!thread || !unbound_var) return;
    OzValue *d = oz_deref(unbound_var);
    if (d->type != OZ_VAL_UNBOUND) {
        /* Already determined; keep ready */
        oz_scheduler_enqueue_thread(thread);
        return;
    }
    thread->state = OZ_THREAD_SUSPENDED;
    thread->suspended_on = d;
    OzSuspension *susp = (OzSuspension *)malloc(sizeof(OzSuspension));
    susp->thread = thread;
    susp->next = d->as.unbound.susp_list;
    d->as.unbound.susp_list = susp;
}

OzThread *oz_scheduler_current(void) {
    return g_scheduler.current_thread;
}

void oz_scheduler_set_current(OzThread *thread) {
    g_scheduler.current_thread = thread;
}

size_t oz_scheduler_runnable_count(void) {
    size_t count = 0;
    OzThread *curr = g_scheduler.run_queue_head;
    while (curr) {
        count++;
        curr = curr->next_run;
    }
    return count;
}
