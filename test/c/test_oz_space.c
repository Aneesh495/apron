#include "oz_space.h"
#include <stdio.h>
#include <assert.h>

int main(void) {
    printf("[test_oz_space] Initializing computation space test...\n");
    OzStore *store = oz_store_create();

    OzSpace *sp = oz_space_create(NULL, store, NULL);
    assert(sp != NULL);

    uint32_t alts = 0;
    OzSpaceStatus st = oz_space_ask(sp, &alts);
    assert(st == OZ_SPACE_ALTERNATIVES);
    assert(alts == 2);

    /* Clone space */
    OzSpace *clone = oz_space_clone(sp);
    assert(clone != NULL);

    /* Commit branch 1 on sp */
    assert(oz_space_commit(sp, 1));
    assert(sp->active_choice.selected_alternative == 1);

    /* Commit branch 2 on clone */
    assert(oz_space_commit(clone, 2));
    assert(clone->active_choice.selected_alternative == 2);

    oz_space_destroy(sp);
    oz_space_destroy(clone);
    oz_store_destroy(store);

    printf("[test_oz_space] PASS\n");
    return 0;
}
