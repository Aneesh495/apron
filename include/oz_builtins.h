#ifndef OZ_BUILTINS_H
#define OZ_BUILTINS_H

#include "oz_types.h"
#include "oz_store.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef OzValue *(*OzBuiltinFn)(OzStore *store, uint32_t argc, OzValue **argv);

typedef struct OzBuiltinEntry {
    const char *module_name;
    const char *func_name;
    uint32_t arity;
    OzBuiltinFn fn;
} OzBuiltinEntry;

/* Lookup built-in function by module and function name */
OzBuiltinFn oz_builtin_lookup(const char *module_name, const char *func_name, uint32_t arity);

/* Initialize built-in module records */
void oz_builtins_init(void);

/* Builtin function prototypes */
OzValue *oz_builtin_system_show(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_system_print_info(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_app_exit(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_time_time(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_list_length(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_list_reverse(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_list_append(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_record_label(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_record_arity(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_port_new(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_port_send(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_math_sqrt(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_math_abs(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_math_min(OzStore *store, uint32_t argc, OzValue **argv);
OzValue *oz_builtin_math_max(OzStore *store, uint32_t argc, OzValue **argv);

#ifdef __cplusplus
}
#endif

#endif /* OZ_BUILTINS_H */
