#include "oz_store.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_ATOM_CAPACITY 256
#define INITIAL_STORE_CAPACITY 1024
#define INITIAL_TRAIL_CAPACITY 512

/* Global Interned Atom Table */
static char **g_atom_names = NULL;
static uint32_t g_atom_count = 0;
static uint32_t g_atom_capacity = 0;

uint32_t oz_atom_intern(const char *name) {
    if (!name) return 0;
    for (uint32_t i = 0; i < g_atom_count; ++i) {
        if (strcmp(g_atom_names[i], name) == 0) {
            return i;
        }
    }
    if (g_atom_count >= g_atom_capacity) {
        uint32_t new_cap = g_atom_capacity == 0 ? INITIAL_ATOM_CAPACITY : g_atom_capacity * 2;
        char **new_table = (char **)realloc(g_atom_names, sizeof(char *) * new_cap);
        if (!new_table) {
            fprintf(stderr, "[ozvm] Fatal: Out of memory in atom table\n");
            exit(1);
        }
        g_atom_names = new_table;
        g_atom_capacity = new_cap;
    }
    char *dup = strdup(name);
    uint32_t id = g_atom_count++;
    g_atom_names[id] = dup;
    return id;
}

const char *oz_atom_name(uint32_t atom_id) {
    if (atom_id < g_atom_count) {
        return g_atom_names[atom_id];
    }
    return "<unknown_atom>";
}

/* Value Constructors */
OzValue *oz_val_create_unbound(uint32_t var_id) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_UNBOUND;
    v->ref_count = 1;
    v->as.unbound.forward = NULL;
    v->as.unbound.susp_list = NULL;
    v->as.unbound.var_id = var_id;
    return v;
}

OzValue *oz_val_create_int(int64_t val) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_INT;
    v->ref_count = 1;
    v->as.int_val = val;
    return v;
}

OzValue *oz_val_create_float(double val) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_FLOAT;
    v->ref_count = 1;
    v->as.float_val = val;
    return v;
}

OzValue *oz_val_create_atom(uint32_t atom_id) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_ATOM;
    v->ref_count = 1;
    v->as.atom_id = atom_id;
    return v;
}

OzValue *oz_val_create_atom_name(const char *name) {
    return oz_val_create_atom(oz_atom_intern(name));
}

OzValue *oz_val_create_string(const char *chars, size_t len) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_STRING;
    v->ref_count = 1;
    v->as.str_val.chars = (char *)malloc(len + 1);
    memcpy(v->as.str_val.chars, chars, len);
    v->as.str_val.chars[len] = '\0';
    v->as.str_val.length = len;
    return v;
}

OzValue *oz_val_create_nil(void) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_NIL;
    v->ref_count = 1;
    return v;
}

OzValue *oz_val_create_pair(OzValue *head, OzValue *tail) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_PAIR;
    v->ref_count = 1;
    v->as.pair.head = head;
    v->as.pair.tail = tail;
    if (head) oz_val_retain(head);
    if (tail) oz_val_retain(tail);
    return v;
}

OzValue *oz_val_create_tuple(uint32_t label_atom, uint32_t arity) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_TUPLE;
    v->ref_count = 1;
    v->as.tuple.label_atom = label_atom;
    v->as.tuple.arity = arity;
    if (arity > 0) {
        v->as.tuple.elements = (OzValue **)calloc(arity, sizeof(OzValue *));
    }
    return v;
}

static int feature_comparator(const void *a, const void *b) {
    const OzFeature *fa = (const OzFeature *)a;
    const OzFeature *fb = (const OzFeature *)b;
    return (fa->key_atom < fb->key_atom) ? -1 : ((fa->key_atom > fb->key_atom) ? 1 : 0);
}

OzValue *oz_val_create_record(uint32_t label_atom, uint32_t num_features, const OzFeature *features) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_RECORD;
    v->ref_count = 1;
    v->as.record.label_atom = label_atom;
    v->as.record.num_features = num_features;
    if (num_features > 0 && features) {
        v->as.record.features = (OzFeature *)malloc(sizeof(OzFeature) * num_features);
        memcpy(v->as.record.features, features, sizeof(OzFeature) * num_features);
        for (uint32_t i = 0; i < num_features; ++i) {
            if (v->as.record.features[i].value) {
                oz_val_retain(v->as.record.features[i].value);
            }
        }
        /* Keep features sorted by atom ID for binary search */
        qsort(v->as.record.features, num_features, sizeof(OzFeature), feature_comparator);
    }
    return v;
}

OzValue *oz_val_create_proc(uint32_t entry, uint32_t arity, uint32_t num_captured, const char *name) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_PROC;
    v->ref_count = 1;
    v->as.proc.code_entry = entry;
    v->as.proc.arity = arity;
    v->as.proc.num_captured = num_captured;
    if (num_captured > 0) {
        v->as.proc.captured = (OzValue **)calloc(num_captured, sizeof(OzValue *));
    }
    if (name) {
        v->as.proc.name = strdup(name);
    }
    return v;
}

OzValue *oz_val_create_port(OzValue *stream_var, uint32_t port_id) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_PORT;
    v->ref_count = 1;
    v->as.port.tail_var = stream_var;
    v->as.port.port_id = port_id;
    if (stream_var) oz_val_retain(stream_var);
    return v;
}

OzValue *oz_val_create_fd(int32_t min, int32_t max, uint32_t var_id) {
    OzValue *v = (OzValue *)calloc(1, sizeof(OzValue));
    v->type = OZ_VAL_FD_VAR;
    v->ref_count = 1;
    v->as.fd_var.min = min;
    v->as.fd_var.max = max;
    v->as.fd_var.var_id = var_id;
    return v;
}

/* Dereference variable forward pointers with path compression */
OzValue *oz_deref(OzValue *val) {
    if (!val) return NULL;
    if (val->type != OZ_VAL_UNBOUND) return val;

    OzValue *curr = val;
    while (curr->type == OZ_VAL_UNBOUND && curr->as.unbound.forward != NULL) {
        curr = curr->as.unbound.forward;
    }

    /* Path compression */
    if (val != curr && val->type == OZ_VAL_UNBOUND) {
        val->as.unbound.forward = curr;
    }
    return curr;
}

bool oz_is_determined(OzValue *val) {
    OzValue *d = oz_deref(val);
    return (d != NULL && d->type != OZ_VAL_UNBOUND);
}

void oz_val_retain(OzValue *val) {
    if (val) {
        val->ref_count++;
    }
}

void oz_val_release(OzValue *val) {
    if (!val) return;
    if (val->ref_count > 0) {
        val->ref_count--;
    }
    if (val->ref_count == 0) {
        switch (val->type) {
            case OZ_VAL_STRING:
                free(val->as.str_val.chars);
                break;
            case OZ_VAL_PAIR:
                oz_val_release(val->as.pair.head);
                oz_val_release(val->as.pair.tail);
                break;
            case OZ_VAL_TUPLE:
                for (uint32_t i = 0; i < val->as.tuple.arity; ++i) {
                    oz_val_release(val->as.tuple.elements[i]);
                }
                free(val->as.tuple.elements);
                break;
            case OZ_VAL_RECORD:
                for (uint32_t i = 0; i < val->as.record.num_features; ++i) {
                    oz_val_release(val->as.record.features[i].value);
                }
                free(val->as.record.features);
                break;
            case OZ_VAL_PROC:
                for (uint32_t i = 0; i < val->as.proc.num_captured; ++i) {
                    oz_val_release(val->as.proc.captured[i]);
                }
                free(val->as.proc.captured);
                free(val->as.proc.name);
                break;
            case OZ_VAL_PORT:
                oz_val_release(val->as.port.tail_var);
                break;
            default:
                break;
        }
        free(val);
    }
}

void oz_val_print(const OzValue *val) {
    OzValue *d = oz_deref((OzValue *)val);
    if (!d) {
        printf("<null>");
        return;
    }
    switch (d->type) {
        case OZ_VAL_UNBOUND:
            printf("_<v%u>", d->as.unbound.var_id);
            break;
        case OZ_VAL_INT:
            printf("%lld", (long long)d->as.int_val);
            break;
        case OZ_VAL_FLOAT:
            printf("%f", d->as.float_val);
            break;
        case OZ_VAL_ATOM:
            printf("%s", oz_atom_name(d->as.atom_id));
            break;
        case OZ_VAL_STRING:
            printf("\"%s\"", d->as.str_val.chars);
            break;
        case OZ_VAL_NIL:
            printf("nil");
            break;
        case OZ_VAL_PAIR: {
            printf("[");
            const OzValue *curr = d;
            bool first = true;
            while (curr && curr->type == OZ_VAL_PAIR) {
                if (!first) printf(" ");
                oz_val_print(curr->as.pair.head);
                first = false;
                curr = oz_deref(curr->as.pair.tail);
            }
            if (curr && curr->type != OZ_VAL_NIL) {
                printf(" | ");
                oz_val_print(curr);
            }
            printf("]");
            break;
        }
        case OZ_VAL_TUPLE:
            printf("%s(", oz_atom_name(d->as.tuple.label_atom));
            for (uint32_t i = 0; i < d->as.tuple.arity; ++i) {
                if (i > 0) printf(", ");
                oz_val_print(d->as.tuple.elements[i]);
            }
            printf(")");
            break;
        case OZ_VAL_RECORD:
            printf("%s(", oz_atom_name(d->as.record.label_atom));
            for (uint32_t i = 0; i < d->as.record.num_features; ++i) {
                if (i > 0) printf(" ");
                printf("%s:", oz_atom_name(d->as.record.features[i].key_atom));
                oz_val_print(d->as.record.features[i].value);
            }
            printf(")");
            break;
        case OZ_VAL_PROC:
            printf("<proc %s/%u>", d->as.proc.name ? d->as.proc.name : "anon", d->as.proc.arity);
            break;
        case OZ_VAL_PORT:
            printf("<port #%u>", d->as.port.port_id);
            break;
        case OZ_VAL_SPACE:
            printf("<space>");
            break;
        case OZ_VAL_FD_VAR:
            printf("FD#%u[%d..%d]", d->as.fd_var.var_id, d->as.fd_var.min, d->as.fd_var.max);
            break;
    }
}

/* Store Lifecycle */
OzStore *oz_store_create(void) {
    OzStore *store = (OzStore *)calloc(1, sizeof(OzStore));
    store->capacity = INITIAL_STORE_CAPACITY;
    store->all_values = (OzValue **)malloc(sizeof(OzValue *) * store->capacity);
    store->next_var_id = 1;
    store->trail.capacity = INITIAL_TRAIL_CAPACITY;
    store->trail.entries = (OzTrailEntry *)malloc(sizeof(OzTrailEntry) * store->trail.capacity);
    store->trail.count = 0;
    store->in_space = false;
    return store;
}

void oz_store_destroy(OzStore *store) {
    if (!store) return;
    for (size_t i = 0; i < store->count; ++i) {
        oz_val_release(store->all_values[i]);
    }
    free(store->all_values);
    free(store->trail.entries);
    free(store);
}

OzValue *oz_store_alloc_unbound(OzStore *store) {
    OzValue *v = oz_val_create_unbound(store->next_var_id++);
    if (store->count >= store->capacity) {
        store->capacity *= 2;
        store->all_values = (OzValue **)realloc(store->all_values, sizeof(OzValue *) * store->capacity);
    }
    store->all_values[store->count++] = v;
    oz_val_retain(v);
    return v;
}

OzValue *oz_store_alloc_fd(OzStore *store, int32_t min, int32_t max) {
    OzValue *v = oz_val_create_fd(min, max, store->next_var_id++);
    if (store->count >= store->capacity) {
        store->capacity *= 2;
        store->all_values = (OzValue **)realloc(store->all_values, sizeof(OzValue *) * store->capacity);
    }
    store->all_values[store->count++] = v;
    oz_val_retain(v);
    return v;
}

void oz_store_trail_push(OzStore *store, OzTrailOp op, OzValue *var) {
    if (!store->in_space) return;
    if (store->trail.count >= store->trail.capacity) {
        store->trail.capacity *= 2;
        store->trail.entries = (OzTrailEntry *)realloc(store->trail.entries, sizeof(OzTrailEntry) * store->trail.capacity);
    }
    OzTrailEntry *entry = &store->trail.entries[store->trail.count++];
    entry->op = op;
    entry->var = var;
    oz_val_retain(var);
    if (op == OZ_TRAIL_FD_NARROW) {
        entry->saved.fd_state.prev_min = var->as.fd_var.min;
        entry->saved.fd_state.prev_max = var->as.fd_var.max;
    } else {
        entry->saved.prev_val = var->as.unbound.forward;
    }
}

size_t oz_store_trail_mark(const OzStore *store) {
    return store->trail.count;
}

void oz_store_backtrack(OzStore *store, size_t mark) {
    while (store->trail.count > mark) {
        OzTrailEntry *entry = &store->trail.entries[--store->trail.count];
        if (entry->op == OZ_TRAIL_BIND_VAR || entry->op == OZ_TRAIL_UNION_VAR) {
            entry->var->as.unbound.forward = entry->saved.prev_val;
        } else if (entry->op == OZ_TRAIL_FD_NARROW) {
            entry->var->as.fd_var.min = entry->saved.fd_state.prev_min;
            entry->var->as.fd_var.max = entry->saved.fd_state.prev_max;
        }
        oz_val_release(entry->var);
    }
}
