#ifndef FASTPATH_RTREE_H
#define FASTPATH_RTREE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RTREE_MAX_ENTRIES 16
#define RTREE_MIN_ENTRIES 4

typedef struct RTreeBBox {
    double min_x;
    double min_y;
    double max_x;
    double max_y;
} RTreeBBox;

typedef struct RTreeEntry {
    RTreeBBox bbox;
    uint32_t id;
    void *data;
} RTreeEntry;

typedef struct RTreeNode RTreeNode;

struct RTreeNode {
    bool is_leaf;
    size_t count;
    RTreeBBox bbox;
    union {
        RTreeEntry entries[RTREE_MAX_ENTRIES];
        struct {
            RTreeNode *children[RTREE_MAX_ENTRIES];
            RTreeBBox child_bboxes[RTREE_MAX_ENTRIES];
        } internal;
    } as;
};

typedef struct RTree {
    RTreeNode *root;
    size_t total_items;
} RTree;

/* R-Tree Lifecycle */
RTree *rtree_create(void);
void rtree_destroy(RTree *tree);

/* Insertion and Removal */
void rtree_insert(RTree *tree, RTreeBBox bbox, uint32_t id, void *data);

/* Spatial Intersection Query callback */
typedef bool (*RTreeQueryCallback)(uint32_t id, void *data, void *context);

/* Query all items intersecting search_bbox */
size_t rtree_query(const RTree *tree, RTreeBBox search_bbox, RTreeQueryCallback cb, void *context);

/* Bounding box helpers */
RTreeBBox rtree_bbox_combine(RTreeBBox a, RTreeBBox b);
bool rtree_bbox_intersects(RTreeBBox a, RTreeBBox b);
double rtree_bbox_area(RTreeBBox b);

#ifdef __cplusplus
}
#endif

#endif /* FASTPATH_RTREE_H */
