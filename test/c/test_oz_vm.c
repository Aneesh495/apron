#include "oz_vm.h"
#include <stdio.h>
#include <assert.h>

int main(void) {
    printf("[test_oz_vm] Initializing virtual machine execution test...\n");

    OzVM *vm = oz_vm_create();
    assert(vm != NULL);

    OzBytecodeChunk *chunk = oz_chunk_create();

    /* Program:
       r0 = 10
       r1 = 20
       r2 = unbound
       r2 = r1 (unify)
       halt
    */
    uint32_t c0 = oz_chunk_add_constant(chunk, oz_val_create_int(10));
    uint32_t c1 = oz_chunk_add_constant(chunk, oz_val_create_int(20));

    oz_chunk_emit(chunk, OZ_INSTR(OP_LOAD_K, 0, (uint8_t)c0, 0), 1);
    oz_chunk_emit(chunk, OZ_INSTR(OP_LOAD_K, 1, (uint8_t)c1, 0), 2);
    oz_chunk_emit(chunk, OZ_INSTR(OP_MAKE_UNBOUND, 2, 0, 0), 3);
    oz_chunk_emit(chunk, OZ_INSTR(OP_UNIFY, 2, 1, 0), 4);
    oz_chunk_emit(chunk, OZ_INSTR(OP_HALT, 0, 0, 0), 5);

    oz_vm_load_chunk(vm, chunk);
    int res = oz_vm_run(vm);
    assert(res == 0);

    oz_vm_destroy(vm);
    printf("[test_oz_vm] PASS\n");
    return 0;
}
