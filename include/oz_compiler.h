#ifndef OZ_COMPILER_H
#define OZ_COMPILER_H

#include "oz_types.h"
#include "oz_ast.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    OP_HALT = 0,
    OP_MOVE,
    OP_LOAD_K,
    OP_MAKE_UNBOUND,
    OP_UNIFY,
    OP_SUSPEND_IF,
    OP_CALL,
    OP_CALL_BUILTIN,
    OP_RETURN,
    OP_SPAWN,
    OP_NEW_PORT,
    OP_SEND,
    OP_SPACE_NEW,
    OP_SPACE_ASK,
    OP_SPACE_CLONE,
    OP_SPACE_COMMIT
} OzOpcode;

/* 32-bit Encoded Instruction:
   [ Opcode: 8 bits | Reg A: 8 bits | Reg B: 8 bits | Reg C: 8 bits ]
*/
#define OZ_INSTR(op, a, b, c) (((uint32_t)(op) & 0xFF) | (((uint32_t)(a) & 0xFF) << 8) | (((uint32_t)(b) & 0xFF) << 16) | (((uint32_t)(c) & 0xFF) << 24))
#define OZ_INSTR_OP(instr) ((OzOpcode)((instr) & 0xFF))
#define OZ_INSTR_A(instr) (((instr) >> 8) & 0xFF)
#define OZ_INSTR_B(instr) (((instr) >> 16) & 0xFF)
#define OZ_INSTR_C(instr) (((instr) >> 24) & 0xFF)

typedef struct OzBytecodeChunk {
    uint32_t *code;
    size_t code_count;
    size_t code_capacity;

    OzValue **constants;
    size_t const_count;
    size_t const_capacity;

    uint32_t *line_numbers;
} OzBytecodeChunk;

OzBytecodeChunk *oz_chunk_create(void);
void oz_chunk_destroy(OzBytecodeChunk *chunk);
void oz_chunk_emit(OzBytecodeChunk *chunk, uint32_t instr, uint32_t line);
uint32_t oz_chunk_add_constant(OzBytecodeChunk *chunk, OzValue *val);

/* Compilation */
OzBytecodeChunk *oz_compile_ast(const OzAstNode *root);
void oz_disassemble_chunk(const OzBytecodeChunk *chunk, const char *name);

#ifdef __cplusplus
}
#endif

#endif /* OZ_COMPILER_H */
