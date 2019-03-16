#include "oz_store.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declaration of thread wakeup */
void oz_scheduler_enqueue_thread(OzThread *thread);

void oz_awaken_suspensions(OzValue *var) {
    if (!var || var->type != OZ_VAL_UNBOUND) return;
    OzSuspension *curr = var->as.unbound.susp_list;
    while (curr) {
        OzSuspension *next = curr->next;
        if (curr->thread) {
            oz_scheduler_enqueue_thread(curr->thread);
        }
        free(curr);
        curr = next;
    }
    var->as.unbound.susp_list = NULL;
}

/* Pair comparison entry for cycle detection in rational trees */
typedef struct VisitedPair {
    const OzValue *v1;
    const OzValue *v2;
} VisitedPair;

#define MAX_VISITED_PAIRS 1024
static VisitedPair g_visited[MAX_VISITED_PAIRS];
static size_t g_visited_count = 0;

static bool is_visited(const OzValue *v1, const OzValue *v2) {
    for (size_t i = 0; i < g_visited_count; ++i) {
        if ((g_visited[i].v1 == v1 && g_visited[i].v2 == v2) ||
            (g_visited[i].v1 == v2 && g_visited[i].v2 == v1)) {
            return true;
        }
    }
    return false;
}

static void mark_visited(const OzValue *v1, const OzValue *v2) {
    if (g_visited_count < MAX_VISITED_PAIRS) {
        g_visited[g_visited_count].v1 = v1;
        g_visited[g_visited_count].v2 = v2;
        g_visited_count++;
    }
}

static bool oz_unify_internal(OzStore *store, OzValue *v1, OzValue *v2);

bool oz_unify(OzStore *store, OzValue *v1, OzValue *v2) {
    g_visited_count = 0;
    return oz_unify_internal(store, v1, v2);
}

static bool oz_unify_internal(OzStore *store, OzValue *v1, OzValue *v2) {
    OzValue *d1 = oz_deref(v1);
    OzValue *d2 = oz_deref(v2);

    /* Identical pointers succeed immediately */
    if (d1 == d2) return true;
    if (!d1 || !d2) return false;

    /* Rational tree cycle check */
    if (is_visited(d1, d2)) return true;
    mark_visited(d1, d2);

    /* Case 1: Both unbound variables (Union) */
    if (d1->type == OZ_VAL_UNBOUND && d2->type == OZ_VAL_UNBOUND) {
        if (store) oz_store_trail_push(store, OZ_TRAIL_UNION_VAR, d1);
        d1->as.unbound.forward = d2;

        /* Merge suspension lists */
        if (d1->as.unbound.susp_list) {
            OzSuspension *last = d1->as.unbound.susp_list;
            while (last->next) last = last->next;
            last->next = d2->as.unbound.susp_list;
            d2->as.unbound.susp_list = d1->as.unbound.susp_list;
            d1->as.unbound.susp_list = NULL;
        }
        return true;
    }

    /* Case 2: d1 unbound, d2 determined */
    if (d1->type == OZ_VAL_UNBOUND) {
        if (store) oz_store_trail_push(store, OZ_TRAIL_BIND_VAR, d1);
        d1->as.unbound.forward = d2;
        oz_awaken_suspensions(d1);
        return true;
    }

    /* Case 3: d2 unbound, d1 determined */
    if (d2->type == OZ_VAL_UNBOUND) {
        if (store) oz_store_trail_push(store, OZ_TRAIL_BIND_VAR, d2);
        d2->as.unbound.forward = d1;
        oz_awaken_suspensions(d2);
        return true;
    }

    /* Case 4: Finite Domain Variable */
    if (d1->type == OZ_VAL_FD_VAR && d2->type == OZ_VAL_INT) {
        if (d2->as.int_val >= d1->as.fd_var.min && d2->as.int_val <= d1->as.fd_var.max) {
            if (store) oz_store_trail_push(store, OZ_TRAIL_BIND_VAR, d1);
            d1->as.unbound.forward = d2;
            return true;
        }
        return false;
    }
    if (d2->type == OZ_VAL_FD_VAR && d1->type == OZ_VAL_INT) {
        return oz_unify_internal(store, d2, d1);
    }
    if (d1->type == OZ_VAL_FD_VAR && d2->type == OZ_VAL_FD_VAR) {
        int32_t new_min = d1->as.fd_var.min > d2->as.fd_var.min ? d1->as.fd_var.min : d2->as.fd_var.min;
        int32_t new_max = d1->as.fd_var.max < d2->as.fd_var.max ? d1->as.fd_var.max : d2->as.fd_var.max;
        if (new_min > new_max) return false;
        if (store) oz_store_trail_push(store, OZ_TRAIL_FD_NARROW, d1);
        d1->as.fd_var.min = new_min;
        d1->as.fd_var.max = new_max;
        d2->as.unbound.forward = d1;
        return true;
    }

    /* Case 5: Both determined, different types */
    if (d1->type != d2->type) {
        return false;
    }

    /* Case 6: Both determined, same type */
    switch (d1->type) {
        case OZ_VAL_INT:
            return d1->as.int_val == d2->as.int_val;

        case OZ_VAL_FLOAT:
            return d1->as.float_val == d2->as.float_val;

        case OZ_VAL_ATOM:
            return d1->as.atom_id == d2->as.atom_id;

        case OZ_VAL_STRING:
            if (d1->as.str_val.length != d2->as.str_val.length) return false;
            return memcmp(d1->as.str_val.chars, d2->as.str_val.chars, d1->as.str_val.length) == 0;

        case OZ_VAL_NIL:
            return true;

        case OZ_VAL_PAIR:
            if (!oz_unify_internal(store, d1->as.pair.head, d2->as.pair.head)) {
                return false;
            }
            return oz_unify_internal(store, d1->as.pair.tail, d2->as.pair.tail);

        case OZ_VAL_TUPLE:
            if (d1->as.tuple.label_atom != d2->as.tuple.label_atom) return false;
            if (d1->as.tuple.arity != d2->as.tuple.arity) return false;
            for (uint32_t i = 0; i < d1->as.tuple.arity; ++i) {
                if (!oz_unify_internal(store, d1->as.tuple.elements[i], d2->as.tuple.elements[i])) {
                    return false;
                }
            }
            return true;

        case OZ_VAL_RECORD: {
            if (d1->as.record.label_atom != d2->as.record.label_atom) return false;
            if (d1->as.record.num_features != d2->as.record.num_features) return false;
            for (uint32_t i = 0; i < d1->as.record.num_features; ++i) {
                if (d1->as.record.features[i].key_atom != d2->as.record.features[i].key_atom) {
                    return false;
                }
                if (!oz_unify_internal(store, d1->as.record.features[i].value, d2->as.record.features[i].value)) {
                    return false;
                }
            }
            return true;
        }

        case OZ_VAL_PROC:
            return d1 == d2;

        case OZ_VAL_PORT:
            return d1->as.port.port_id == d2->as.port.port_id;

        default:
            return false;
    }
}
