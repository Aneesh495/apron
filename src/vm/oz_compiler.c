#include "oz_compiler.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_CHUNK_CAPACITY 256

OzBytecodeChunk *oz_chunk_create(void) {
    OzBytecodeChunk *c = (OzBytecodeChunk *)calloc(1, sizeof(OzBytecodeChunk));
    c->code_capacity = INITIAL_CHUNK_CAPACITY;
    c->code = (uint32_t *)malloc(sizeof(uint32_t) * c->code_capacity);
    c->line_numbers = (uint32_t *)malloc(sizeof(uint32_t) * c->code_capacity);
    c->const_capacity = 64;
    c->constants = (OzValue **)malloc(sizeof(OzValue *) * c->const_capacity);
    return c;
}

void oz_chunk_destroy(OzBytecodeChunk *chunk) {
    if (!chunk) return;
    free(chunk->code);
    free(chunk->line_numbers);
    for (size_t i = 0; i < chunk->const_count; ++i) {
        oz_val_release(chunk->constants[i]);
    }
    free(chunk->constants);
    free(chunk);
}

void oz_chunk_emit(OzBytecodeChunk *chunk, uint32_t instr, uint32_t line) {
    if (chunk->code_count >= chunk->code_capacity) {
        chunk->code_capacity *= 2;
        chunk->code = (uint32_t *)realloc(chunk->code, sizeof(uint32_t) * chunk->code_capacity);
        chunk->line_numbers = (uint32_t *)realloc(chunk->line_numbers, sizeof(uint32_t) * chunk->code_capacity);
    }
    chunk->code[chunk->code_count] = instr;
    chunk->line_numbers[chunk->code_count] = line;
    chunk->code_count++;
}

uint32_t oz_chunk_add_constant(OzBytecodeChunk *chunk, OzValue *val) {
    if (chunk->const_count >= chunk->const_capacity) {
        chunk->const_capacity *= 2;
        chunk->constants = (OzValue **)realloc(chunk->constants, sizeof(OzValue *) * chunk->const_capacity);
    }
    uint32_t idx = (uint32_t)chunk->const_count++;
    chunk->constants[idx] = val;
    oz_val_retain(val);
    return idx;
}

typedef struct Symbol {
    char *name;
    uint8_t reg;
} Symbol;

typedef struct CompilerContext {
    OzBytecodeChunk *chunk;
    Symbol symbols[128];
    size_t symbol_count;
    uint8_t next_reg;
} CompilerContext;

static uint8_t lookup_or_alloc_symbol(CompilerContext *ctx, const char *name) {
    for (size_t i = 0; i < ctx->symbol_count; ++i) {
        if (strcmp(ctx->symbols[i].name, name) == 0) {
            return ctx->symbols[i].reg;
        }
    }
    uint8_t reg = ctx->next_reg++;
    ctx->symbols[ctx->symbol_count].name = strdup(name);
    ctx->symbols[ctx->symbol_count].reg = reg;
    ctx->symbol_count++;
    return reg;
}

static uint8_t compile_node(CompilerContext *ctx, const OzAstNode *node) {
    if (!node) return 0;

    switch (node->type) {
        case AST_VAR: {
            return lookup_or_alloc_symbol(ctx, node->as.var_name);
        }

        case AST_LITERAL: {
            uint32_t const_idx = oz_chunk_add_constant(ctx->chunk, node->as.literal);
            uint8_t reg = ctx->next_reg++;
            oz_chunk_emit(ctx->chunk, OZ_INSTR(OP_LOAD_K, reg, (uint8_t)const_idx, 0), node->line);
            return reg;
        }

        case AST_UNIFY: {
            uint8_t r_left = compile_node(ctx, node->as.unify.left);
            uint8_t r_right = compile_node(ctx, node->as.unify.right);
            oz_chunk_emit(ctx->chunk, OZ_INSTR(OP_UNIFY, r_left, r_right, 0), node->line);
            return r_left;
        }

        case AST_LOCAL: {
            for (uint32_t i = 0; i < node->as.local_decl.num_vars; ++i) {
                uint8_t r = lookup_or_alloc_symbol(ctx, node->as.local_decl.vars[i]);
                oz_chunk_emit(ctx->chunk, OZ_INSTR(OP_MAKE_UNBOUND, r, 0, 0), node->line);
            }
            return compile_node(ctx, node->as.local_decl.body);
        }

        case AST_APP: {
            uint8_t r_target = compile_node(ctx, node->as.app.target);
            uint8_t arg_regs[16];
            uint8_t argc = (uint8_t)(node->as.app.num_args > 16 ? 16 : node->as.app.num_args);
            for (uint8_t i = 0; i < argc; ++i) {
                arg_regs[i] = compile_node(ctx, node->as.app.args[i]);
            }
            oz_chunk_emit(ctx->chunk, OZ_INSTR(OP_CALL, r_target, argc, 0), node->line);
            return r_target;
        }

        case AST_THREAD: {
            uint8_t r_body = compile_node(ctx, node->as.thread_decl.body);
            oz_chunk_emit(ctx->chunk, OZ_INSTR(OP_SPAWN, r_body, 0, 0), node->line);
            return r_body;
        }

        case AST_SEQ: {
            compile_node(ctx, node->as.seq.first);
            return compile_node(ctx, node->as.seq.second);
        }

        default:
            return 0;
    }
}

OzBytecodeChunk *oz_compile_ast(const OzAstNode *root) {
    if (!root) return NULL;
    CompilerContext ctx;
    memset(&ctx, 0, sizeof(ctx));
    ctx.chunk = oz_chunk_create();
    ctx.next_reg = 0;

    compile_node(&ctx, root);
    oz_chunk_emit(ctx.chunk, OZ_INSTR(OP_HALT, 0, 0, 0), root->line);

    for (size_t i = 0; i < ctx.symbol_count; ++i) {
        free(ctx.symbols[i].name);
    }
    return ctx.chunk;
}
