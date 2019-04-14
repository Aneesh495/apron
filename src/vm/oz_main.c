#include "oz_vm.h"
#include "oz_ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declaration from oz_parser.c */
OzAstNode *oz_parse_source(const char *source, size_t length);

static char *read_file_to_string(const char *path, size_t *out_len) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "[ozvm] Error: Could not open file '%s'\n", path);
        return NULL;
    }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz < 0) {
        fclose(f);
        return NULL;
    }
    char *buf = (char *)malloc(sz + 1);
    size_t read_bytes = fread(buf, 1, sz, f);
    buf[read_bytes] = '\0';
    fclose(f);
    if (out_len) *out_len = read_bytes;
    return buf;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        printf("Oz Virtual Machine (ozvm) v1.0.0\n");
        printf("Usage:\n");
        printf("  ozvm run <file.oz>      : Execute Oz source file\n");
        printf("  ozvm disasm <file.oz>   : Disassemble Oz source file to bytecode\n");
        printf("  ozvm --version          : Display version information\n");
        return 0;
    }

    if (strcmp(argv[1], "--version") == 0) {
        printf("ozvm 1.0.0 (Apron Oz Execution Engine, C11)\n");
        return 0;
    }

    if (strcmp(argv[1], "disasm") == 0) {
        if (argc < 3) {
            fprintf(stderr, "[ozvm] Error: No input file specified for disassembly\n");
            return 1;
        }
        size_t len = 0;
        char *src = read_file_to_string(argv[2], &len);
        if (!src) return 1;

        OzAstNode *ast = oz_parse_source(src, len);
        free(src);
        if (!ast) {
            fprintf(stderr, "[ozvm] Parse failure in %s\n", argv[2]);
            return 1;
        }

        OzBytecodeChunk *chunk = oz_compile_ast(ast);
        oz_ast_free(ast);
        oz_disassemble_chunk(chunk, argv[2]);
        oz_chunk_destroy(chunk);
        return 0;
    }

    if (strcmp(argv[1], "run") == 0) {
        if (argc < 3) {
            fprintf(stderr, "[ozvm] Error: No input file specified for run\n");
            return 1;
        }
        size_t len = 0;
        char *src = read_file_to_string(argv[2], &len);
        if (!src) return 1;

        OzAstNode *ast = oz_parse_source(src, len);
        free(src);
        if (!ast) {
            fprintf(stderr, "[ozvm] Parse failure in %s\n", argv[2]);
            return 1;
        }

        OzBytecodeChunk *chunk = oz_compile_ast(ast);
        oz_ast_free(ast);

        OzVM *vm = oz_vm_create();
        oz_vm_load_chunk(vm, chunk);
        int ret = oz_vm_run(vm);
        oz_vm_destroy(vm);
        return ret;
    }

    fprintf(stderr, "[ozvm] Unknown command '%s'. Run 'ozvm' for help.\n", argv[1]);
    return 1;
}
