#ifndef OZ_VM_H
#define OZ_VM_H

#include "oz_types.h"
#include "oz_store.h"
#include "oz_compiler.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct OzVM {
    OzStore *store;
    OzBytecodeChunk *chunk;
    bool is_running;
    int exit_code;
} OzVM;

OzVM *oz_vm_create(void);
void oz_vm_destroy(OzVM *vm);
bool oz_vm_load_chunk(OzVM *vm, OzBytecodeChunk *chunk);
int oz_vm_run(OzVM *vm);

/* Thread execution step */
bool oz_vm_step_thread(OzVM *vm, OzThread *thread);

#ifdef __cplusplus
}
#endif

#endif /* OZ_VM_H */
