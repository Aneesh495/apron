#ifndef OZ_SPACE_H
#define OZ_SPACE_H

#include "oz_types.h"
#include "oz_store.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    OZ_SPACE_FAILED = 0,
    OZ_SPACE_SUCCEEDED,
    OZ_SPACE_ALTERNATIVES
} OzSpaceStatus;

typedef struct OzSpaceChoice {
    uint32_t num_alternatives;
    uint32_t selected_alternative;
    size_t trail_mark;
} OzSpaceChoice;

struct OzSpace {
    OzSpace *parent;
    OzStore *store;
    size_t base_trail_mark;
    OzSpaceStatus status;
    OzSpaceChoice active_choice;
    OzValue *root_proc;
    OzValue *solution_val;
};

/* Space Lifecycle */
OzSpace *oz_space_create(OzSpace *parent, OzStore *store, OzValue *root_proc);
void oz_space_destroy(OzSpace *space);

/* Space Operations */
OzSpaceStatus oz_space_ask(OzSpace *space, uint32_t *out_alternatives);
OzSpace *oz_space_clone(OzSpace *space);
bool oz_space_commit(OzSpace *space, uint32_t alternative_index);
OzValue *oz_space_merge(OzSpace *space);

#ifdef __cplusplus
}
#endif

#endif /* OZ_SPACE_H */
