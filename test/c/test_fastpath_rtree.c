#include "fastpath_rtree.h"
#include <stdio.h>
#include <assert.h>

static bool count_cb(uint32_t id, void *data, void *context) {
    (void)id; (void)data;
    size_t *c = (size_t *)context;
    (*c)++;
    return true;
}

int main(void) {
    printf("[test_fastpath_rtree] Initializing 2D R-tree tests...\n");

    RTree *tree = rtree_create();
    assert(tree != NULL);

    /* Insert 10 bounding boxes */
    for (uint32_t i = 0; i < 10; ++i) {
        RTreeBBox b = { (double)i * 10.0, (double)i * 10.0, (double)i * 10.0 + 5.0, (double)i * 10.0 + 5.0 };
        rtree_insert(tree, b, i + 1, NULL);
    }
    assert(tree->total_items == 10);

    /* Query box covering items 2, 3, 4 */
    RTreeBBox query_box = { 15.0, 15.0, 48.0, 48.0 };
    size_t hit_count = 0;
    size_t returned = rtree_query(tree, query_box, count_cb, &hit_count);
    assert(returned == hit_count);
    (void)returned;
    assert(hit_count >= 3);

    rtree_destroy(tree);
    printf("[test_fastpath_rtree] PASS\n");
    return 0;
}
