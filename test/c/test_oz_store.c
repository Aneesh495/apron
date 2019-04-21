#include "oz_store.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

int main(void) {
    printf("[test_oz_store] Initializing single-assignment store test...\n");

    /* Test atom interning */
    uint32_t a1 = oz_atom_intern("runway");
    uint32_t a2 = oz_atom_intern("taxiway");
    uint32_t a3 = oz_atom_intern("runway");
    assert(a1 == a3);
    assert(a1 != a2);
    assert(strcmp(oz_atom_name(a1), "runway") == 0);
    assert(strcmp(oz_atom_name(a2), "taxiway") == 0);

    /* Test store creation and variable allocation */
    OzStore *store = oz_store_create();
    assert(store != NULL);

    OzValue *u1 = oz_store_alloc_unbound(store);
    OzValue *u2 = oz_store_alloc_unbound(store);
    assert(!oz_is_determined(u1));
    assert(!oz_is_determined(u2));
    assert(oz_deref(u1) == u1);

    /* Test integer scalar */
    OzValue *i1 = oz_val_create_int(42);
    assert(oz_is_determined(i1));
    assert(i1->as.int_val == 42);

    /* Test list pairs */
    OzValue *nil = oz_val_create_nil();
    OzValue *p1 = oz_val_create_pair(i1, nil);
    assert(p1->type == OZ_VAL_PAIR);
    assert(oz_deref(p1->as.pair.head)->as.int_val == 42);

    /* Test trail and backtracking */
    store->in_space = true;
    size_t mark = oz_store_trail_mark(store);
    oz_store_trail_push(store, OZ_TRAIL_BIND_VAR, u1);
    u1->as.unbound.forward = i1;
    assert(oz_is_determined(u1));
    assert(oz_deref(u1)->as.int_val == 42);

    /* Backtrack */
    oz_store_backtrack(store, mark);
    assert(!oz_is_determined(u1));

    oz_val_release(p1);
    oz_val_release(nil);
    oz_val_release(i1);
    oz_store_destroy(store);

    printf("[test_oz_store] PASS\n");
    return 0;
}
