#include "fastpath_rtree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

RTreeBBox rtree_bbox_combine(RTreeBBox a, RTreeBBox b) {
    RTreeBBox res;
    res.min_x = a.min_x < b.min_x ? a.min_x : b.min_x;
    res.min_y = a.min_y < b.min_y ? a.min_y : b.min_y;
    res.max_x = a.max_x > b.max_x ? a.max_x : b.max_x;
    res.max_y = a.max_y > b.max_y ? a.max_y : b.max_y;
    return res;
}

bool rtree_bbox_intersects(RTreeBBox a, RTreeBBox b) {
    if (a.max_x < b.min_x || a.min_x > b.max_x) return false;
    if (a.max_y < b.min_y || a.min_y > b.max_y) return false;
    return true;
}

double rtree_bbox_area(RTreeBBox b) {
    double w = b.max_x - b.min_x;
    double h = b.max_y - b.min_y;
    return (w > 0 && h > 0) ? (w * h) : 0.0;
}

static RTreeNode *create_node(bool is_leaf) {
    RTreeNode *n = (RTreeNode *)calloc(1, sizeof(RTreeNode));
    n->is_leaf = is_leaf;
    n->count = 0;
    return n;
}

static void destroy_node(RTreeNode *node) {
    if (!node) return;
    if (!node->is_leaf) {
        for (size_t i = 0; i < node->count; ++i) {
            destroy_node(node->as.internal.children[i]);
        }
    }
    free(node);
}

RTree *rtree_create(void) {
    RTree *tree = (RTree *)calloc(1, sizeof(RTree));
    tree->root = create_node(true);
    tree->total_items = 0;
    return tree;
}

void rtree_destroy(RTree *tree) {
    if (!tree) return;
    destroy_node(tree->root);
    free(tree);
}

static void update_bbox(RTreeNode *node) {
    if (node->count == 0) {
        memset(&node->bbox, 0, sizeof(RTreeBBox));
        return;
    }
    if (node->is_leaf) {
        node->bbox = node->as.entries[0].bbox;
        for (size_t i = 1; i < node->count; ++i) {
            node->bbox = rtree_bbox_combine(node->bbox, node->as.entries[i].bbox);
        }
    } else {
        node->bbox = node->as.internal.child_bboxes[0];
        for (size_t i = 1; i < node->count; ++i) {
            node->bbox = rtree_bbox_combine(node->bbox, node->as.internal.child_bboxes[i]);
        }
    }
}

static void split_leaf_node(RTreeNode *node, RTreeNode **out_new_node) {
    RTreeNode *new_node = create_node(true);
    size_t split_point = node->count / 2;

    for (size_t i = split_point; i < node->count; ++i) {
        new_node->as.entries[new_node->count++] = node->as.entries[i];
    }
    node->count = split_point;

    update_bbox(node);
    update_bbox(new_node);
    *out_new_node = new_node;
}

static void insert_internal(RTreeNode *node, RTreeBBox bbox, uint32_t id, void *data, RTreeNode **out_split) {
    if (node->is_leaf) {
        node->as.entries[node->count].bbox = bbox;
        node->as.entries[node->count].id = id;
        node->as.entries[node->count].data = data;
        node->count++;

        if (node->count >= RTREE_MAX_ENTRIES) {
            split_leaf_node(node, out_split);
        } else {
            *out_split = NULL;
            update_bbox(node);
        }
        return;
    }

    /* Choose child with minimum area enlargement */
    size_t best_child = 0;
    double best_enlargement = 1e30;

    for (size_t i = 0; i < node->count; ++i) {
        RTreeBBox combined = rtree_bbox_combine(node->as.internal.child_bboxes[i], bbox);
        double enlargement = rtree_bbox_area(combined) - rtree_bbox_area(node->as.internal.child_bboxes[i]);
        if (enlargement < best_child) {
            best_enlargement = enlargement;
            best_child = i;
        }
    }

    RTreeNode *child_split = NULL;
    insert_internal(node->as.internal.children[best_child], bbox, id, data, &child_split);
    node->as.internal.child_bboxes[best_child] = node->as.internal.children[best_child]->bbox;

    if (child_split) {
        if (node->count < RTREE_MAX_ENTRIES) {
            node->as.internal.children[node->count] = child_split;
            node->as.internal.child_bboxes[node->count] = child_split->bbox;
            node->count++;
            *out_split = NULL;
        } else {
            /* Internal split */
            RTreeNode *new_internal = create_node(false);
            size_t split_pt = node->count / 2;
            for (size_t i = split_pt; i < node->count; ++i) {
                new_internal->as.internal.children[new_internal->count] = node->as.internal.children[i];
                new_internal->as.internal.child_bboxes[new_internal->count] = node->as.internal.child_bboxes[i];
                new_internal->count++;
            }
            node->count = split_pt;
            update_bbox(node);
            update_bbox(new_internal);
            *out_split = new_internal;
            return;
        }
    }
    *out_split = NULL;
    update_bbox(node);
}

void rtree_insert(RTree *tree, RTreeBBox bbox, uint32_t id, void *data) {
    if (!tree) return;
    RTreeNode *split = NULL;
    insert_internal(tree->root, bbox, id, data, &split);

    if (split) {
        /* Create new root */
        RTreeNode *new_root = create_node(false);
        new_root->as.internal.children[0] = tree->root;
        new_root->as.internal.child_bboxes[0] = tree->root->bbox;
        new_root->as.internal.children[1] = split;
        new_root->as.internal.child_bboxes[1] = split->bbox;
        new_root->count = 2;
        update_bbox(new_root);
        tree->root = new_root;
    }
    tree->total_items++;
}

static size_t query_node(const RTreeNode *node, RTreeBBox search_bbox, RTreeQueryCallback cb, void *context) {
    if (!node || !rtree_bbox_intersects(node->bbox, search_bbox)) {
        return 0;
    }

    size_t hits = 0;
    if (node->is_leaf) {
        for (size_t i = 0; i < node->count; ++i) {
            if (rtree_bbox_intersects(node->as.entries[i].bbox, search_bbox)) {
                hits++;
                if (cb && !cb(node->as.entries[i].id, node->as.entries[i].data, context)) {
                    return hits;
                }
            }
        }
    } else {
        for (size_t i = 0; i < node->count; ++i) {
            if (rtree_bbox_intersects(node->as.internal.child_bboxes[i], search_bbox)) {
                hits += query_node(node->as.internal.children[i], search_bbox, cb, context);
            }
        }
    }
    return hits;
}

size_t rtree_query(const RTree *tree, RTreeBBox search_bbox, RTreeQueryCallback cb, void *context) {
    if (!tree || !tree->root) return 0;
    return query_node(tree->root, search_bbox, cb, context);
}
