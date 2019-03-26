#include "oz_space.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

OzSpace *oz_space_create(OzSpace *parent, OzStore *store, OzValue *root_proc) {
    OzSpace *s = (OzSpace *)calloc(1, sizeof(OzSpace));
    s->parent = parent;
    s->store = store;
    s->root_proc = root_proc;
    if (root_proc) oz_val_retain(root_proc);
    if (store) {
        store->in_space = true;
        s->base_trail_mark = oz_store_trail_mark(store);
    }
    s->status = OZ_SPACE_ALTERNATIVES;
    s->active_choice.num_alternatives = 2; /* Default binary choice point */
    s->active_choice.selected_alternative = 0;
    s->active_choice.trail_mark = s->base_trail_mark;
    return s;
}

void oz_space_destroy(OzSpace *space) {
    if (!space) return;
    if (space->root_proc) {
        oz_val_release(space->root_proc);
    }
    if (space->solution_val) {
        oz_val_release(space->solution_val);
    }
    free(space);
}

OzSpaceStatus oz_space_ask(OzSpace *space, uint32_t *out_alternatives) {
    if (!space) return OZ_SPACE_FAILED;

    /* If status is already resolved, return it */
    if (space->status == OZ_SPACE_FAILED) {
        if (out_alternatives) *out_alternatives = 0;
        return OZ_SPACE_FAILED;
    }
    if (space->status == OZ_SPACE_SUCCEEDED) {
        if (out_alternatives) *out_alternatives = 0;
        return OZ_SPACE_SUCCEEDED;
    }

    /* Evaluates choice points */
    if (out_alternatives) {
        *out_alternatives = space->active_choice.num_alternatives;
    }
    return OZ_SPACE_ALTERNATIVES;
}

OzSpace *oz_space_clone(OzSpace *space) {
    if (!space) return NULL;
    OzSpace *clone = (OzSpace *)calloc(1, sizeof(OzSpace));
    clone->parent = space->parent;
    clone->store = space->store;
    clone->base_trail_mark = space->base_trail_mark;
    clone->status = space->status;
    clone->active_choice = space->active_choice;
    clone->root_proc = space->root_proc;
    if (clone->root_proc) oz_val_retain(clone->root_proc);
    clone->solution_val = space->solution_val;
    if (clone->solution_val) oz_val_retain(clone->solution_val);
    return clone;
}

bool oz_space_commit(OzSpace *space, uint32_t alternative_index) {
    if (!space) return false;
    if (alternative_index == 0 || alternative_index > space->active_choice.num_alternatives) {
        space->status = OZ_SPACE_FAILED;
        return false;
    }
    space->active_choice.selected_alternative = alternative_index;
    return true;
}

OzValue *oz_space_merge(OzSpace *space) {
    if (!space) return NULL;
    if (space->solution_val) {
        oz_val_retain(space->solution_val);
        return space->solution_val;
    }
    return oz_val_create_nil();
}
