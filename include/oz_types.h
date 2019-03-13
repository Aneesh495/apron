#ifndef OZ_TYPES_H
#define OZ_TYPES_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Oz Value Type Tag */
typedef enum {
    OZ_VAL_UNBOUND = 0,
    OZ_VAL_INT,
    OZ_VAL_FLOAT,
    OZ_VAL_ATOM,
    OZ_VAL_STRING,
    OZ_VAL_NIL,
    OZ_VAL_PAIR,        /* [Head | Tail] list constructor */
    OZ_VAL_TUPLE,       /* label(v1, v2, ..., vn) */
    OZ_VAL_RECORD,      /* label(f1:v1, f2:v2, ...) */
    OZ_VAL_PROC,        /* Procedure closure */
    OZ_VAL_PORT,        /* Asynchronous communication port */
    OZ_VAL_SPACE,       /* First-class computation space */
    OZ_VAL_FD_VAR       /* Finite domain constraint variable */
} OzValueType;

typedef struct OzValue OzValue;
typedef struct OzThread OzThread;
typedef struct OzSpace OzSpace;

/* Linked list of threads suspended on an unbound variable */
typedef struct OzSuspension {
    OzThread *thread;
    struct OzSuspension *next;
} OzSuspension;

/* Feature key-value pair for Oz records */
typedef struct OzFeature {
    uint32_t key_atom;  /* Atom ID of the feature name */
    OzValue *value;
} OzFeature;

/* Finite domain range: [min, max] */
typedef struct OzFDRange {
    int32_t min;
    int32_t max;
} OzFDRange;

/* Oz Value Structure */
struct OzValue {
    OzValueType type;
    uint32_t ref_count;
    union {
        /* Unbound Variable / Equivalence Class */
        struct {
            OzValue *forward;        /* Union-find parent pointer; NULL if representative */
            OzSuspension *susp_list; /* Threads suspended on this unbound variable */
            uint32_t var_id;         /* Diagnostic variable identifier */
        } unbound;

        /* Integer */
        int64_t int_val;

        /* Float */
        double float_val;

        /* Atom Symbol (Interned index) */
        uint32_t atom_id;

        /* String */
        struct {
            char *chars;
            size_t length;
        } str_val;

        /* List Pair: [Head | Tail] */
        struct {
            OzValue *head;
            OzValue *tail;
        } pair;

        /* Tuple: label(val1, val2, ..., valN) */
        struct {
            uint32_t label_atom;
            uint32_t arity;
            OzValue **elements;
        } tuple;

        /* Record: label(f1:v1, f2:v2, ..., fn:vn) */
        struct {
            uint32_t label_atom;
            uint32_t num_features;
            OzFeature *features; /* Sorted by key_atom for O(log N) lookup */
        } record;

        /* Procedure Closure */
        struct {
            uint32_t code_entry;    /* Bytecode entry point offset */
            uint32_t arity;         /* Number of arguments */
            uint32_t num_captured;  /* Number of captured free variables */
            OzValue **captured;     /* Environment vector */
            char *name;             /* Debug name */
        } proc;

        /* Port Object */
        struct {
            OzValue *tail_var;      /* Pointer to the current unbound tail variable */
            uint32_t port_id;       /* Unique port serial number */
        } port;

        /* Computation Space Reference */
        struct {
            OzSpace *space_ptr;
        } space;

        /* Finite Domain Variable */
        struct {
            int32_t min;
            int32_t max;
            uint32_t var_id;
        } fd_var;
    } as;
};

/* Atom Interning Table */
uint32_t oz_atom_intern(const char *name);
const char *oz_atom_name(uint32_t atom_id);

/* Value Constructors */
OzValue *oz_val_create_unbound(uint32_t var_id);
OzValue *oz_val_create_int(int64_t val);
OzValue *oz_val_create_float(double val);
OzValue *oz_val_create_atom(uint32_t atom_id);
OzValue *oz_val_create_atom_name(const char *name);
OzValue *oz_val_create_string(const char *chars, size_t len);
OzValue *oz_val_create_nil(void);
OzValue *oz_val_create_pair(OzValue *head, OzValue *tail);
OzValue *oz_val_create_tuple(uint32_t label_atom, uint32_t arity);
OzValue *oz_val_create_record(uint32_t label_atom, uint32_t num_features, const OzFeature *features);
OzValue *oz_val_create_proc(uint32_t entry, uint32_t arity, uint32_t num_captured, const char *name);
OzValue *oz_val_create_port(OzValue *stream_var, uint32_t port_id);
OzValue *oz_val_create_fd(int32_t min, int32_t max, uint32_t var_id);

/* Value Utilities */
OzValue *oz_deref(OzValue *val);
bool oz_is_determined(OzValue *val);
void oz_val_retain(OzValue *val);
void oz_val_release(OzValue *val);
void oz_val_print(const OzValue *val);

#ifdef __cplusplus
}
#endif

#endif /* OZ_TYPES_H */
