#include "oz_compiler.h"
#include <stdio.h>
#include <stdlib.h>

const char *oz_opcode_name(OzOpcode op) {
    switch (op) {
        case OP_HALT: return "OP_HALT";
        case OP_MOVE: return "OP_MOVE";
        case OP_LOAD_K: return "OP_LOAD_K";
        case OP_MAKE_UNBOUND: return "OP_MAKE_UNBOUND";
        case OP_UNIFY: return "OP_UNIFY";
        case OP_SUSPEND_IF: return "OP_SUSPEND_IF";
        case OP_CALL: return "OP_CALL";
        case OP_CALL_BUILTIN: return "OP_CALL_BUILTIN";
        case OP_RETURN: return "OP_RETURN";
        case OP_SPAWN: return "OP_SPAWN";
        case OP_NEW_PORT: return "OP_NEW_PORT";
        case OP_SEND: return "OP_SEND";
        case OP_SPACE_NEW: return "OP_SPACE_NEW";
        case OP_SPACE_ASK: return "OP_SPACE_ASK";
        case OP_SPACE_CLONE: return "OP_SPACE_CLONE";
        case OP_SPACE_COMMIT: return "OP_SPACE_COMMIT";
        default: return "OP_UNKNOWN";
    }
}

void oz_disassemble_chunk(const OzBytecodeChunk *chunk, const char *name) {
    if (!chunk) return;
    printf("=== Disassembly of %s (%zu instructions) ===\n", name ? name : "chunk", chunk->code_count);
    for (size_t i = 0; i < chunk->code_count; ++i) {
        uint32_t instr = chunk->code[i];
        OzOpcode op = OZ_INSTR_OP(instr);
        uint8_t a = OZ_INSTR_A(instr);
        uint8_t b = OZ_INSTR_B(instr);
        uint8_t c = OZ_INSTR_C(instr);

        printf("[%04zu] %-16s r%-3u r%-3u r%-3u (line %u)\n",
               i, oz_opcode_name(op), a, b, c, chunk->line_numbers ? chunk->line_numbers[i] : 0);
    }
}
