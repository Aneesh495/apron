#ifndef OZ_STORE_H
#define OZ_STORE_H

#include "oz_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Trail entry type for recording store modifications in computation spaces */
typedef enum {
    OZ_TRAIL_BIND_VAR = 0,
    OZ_TRAIL_UNION_VAR,
    OZ_TRAIL_FD_NARROW
} OzTrailOp;

typedef struct OzTrailEntry {
    OzTrailOp op;
    OzValue *var;
    union {
        OzValue *prev_val;
        struct {
            int32_t prev_min;
            int32_t prev_max;
        } fd_state;
    } saved;
} OzTrailEntry;

/* Trail Stack */
typedef struct OzTrail {
    OzTrailEntry *entries;
    size_t count;
    size_t capacity;
} OzTrail;

/* Single-Assignment Store */
typedef struct OzStore {
    OzValue **all_values;
    size_t count;
    size_t capacity;
    uint32_t next_var_id;
    OzTrail trail;
    bool in_space;
} OzStore;

/* Store Lifecycle */
OzStore *oz_store_create(void);
void oz_store_destroy(OzStore *store);

/* Variable Allocation */
OzValue *oz_store_alloc_unbound(OzStore *store);
OzValue *oz_store_alloc_fd(OzStore *store, int32_t min, int32_t max);

/* Trail Management for Backtracking */
void oz_store_trail_push(OzStore *store, OzTrailOp op, OzValue *var);
size_t oz_store_trail_mark(const OzStore *store);
void oz_store_backtrack(OzStore *store, size_t mark);

/* Garbage Collection / Arena Cleanup */
void oz_store_sweep_unreferenced(OzStore *store);

#ifdef __cplusplus
}
#endif

#endif /* OZ_STORE_H */
