#include "oz_store.h"
#include <stdio.h>
#include <assert.h>

/* Forward declaration */
bool oz_unify(OzStore *store, OzValue *v1, OzValue *v2);

int main(void) {
    printf("[test_oz_unify] Initializing unification test...\n");
    OzStore *store = oz_store_create();

    /* Unbound to unbound */
    OzValue *u1 = oz_store_alloc_unbound(store);
    OzValue *u2 = oz_store_alloc_unbound(store);
    assert(oz_unify(store, u1, u2));
    assert(oz_deref(u1) == oz_deref(u2));
    (void)u1; (void)u2;

    /* Unbound to integer */
    OzValue *val100 = oz_val_create_int(100);
    assert(oz_unify(store, u1, val100));
    assert(oz_deref(u1)->as.int_val == 100);
    assert(oz_deref(u2)->as.int_val == 100);

    /* Conflicting unification should fail */
    OzValue *val200 = oz_val_create_int(200);
    assert(!oz_unify(store, u1, val200));

    /* Record unification */
    uint32_t rec_label = oz_atom_intern("flight");
    uint32_t feat_id = oz_atom_intern("id");
    uint32_t feat_speed = oz_atom_intern("speed");

    OzFeature f1[2] = {
        { feat_id, oz_val_create_atom_name("BAW123") },
        { feat_speed, oz_store_alloc_unbound(store) }
    };
    OzValue *r1 = oz_val_create_record(rec_label, 2, f1);

    OzFeature f2[2] = {
        { feat_id, oz_store_alloc_unbound(store) },
        { feat_speed, oz_val_create_int(250) }
    };
    OzValue *r2 = oz_val_create_record(rec_label, 2, f2);

    assert(oz_unify(store, r1, r2));

    /* Verify bound values inside records */
    OzValue *bound_id = oz_deref(f2[0].value);
    assert(bound_id->type == OZ_VAL_ATOM);
    (void)bound_id;

    OzValue *bound_speed = oz_deref(f1[1].value);
    assert(bound_speed->type == OZ_VAL_INT);
    assert(bound_speed->as.int_val == 250);
    (void)bound_speed;

    oz_val_release(r1);
    oz_val_release(r2);
    oz_val_release(val100);
    oz_val_release(val200);
    oz_store_destroy(store);

    printf("[test_oz_unify] PASS\n");
    return 0;
}
