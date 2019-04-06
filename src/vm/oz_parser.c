#include "oz_ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct OzParser {
    OzLexer lexer;
    OzToken current;
    OzToken peek;
} OzParser;

static void parser_advance(OzParser *parser) {
    oz_token_free(&parser->current);
    parser->current = parser->peek;
    parser->peek = oz_lexer_next_token(&parser->lexer);
}

static bool parser_match(OzParser *parser, OzTokenType type) {
    if (parser->current.type == type) {
        parser_advance(parser);
        return true;
    }
    return false;
}

static OzAstNode *parse_statement(OzParser *parser);
static OzAstNode *parse_expression(OzParser *parser);

static OzAstNode *parse_application_or_call(OzParser *parser) {
    uint32_t line = parser->current.line;
    parser_advance(parser); /* Consume '{' */

    OzAstNode *target = parse_expression(parser);

    OzAstNode *args[32];
    uint32_t num_args = 0;

    while (parser->current.type != TOK_RBRACE && parser->current.type != TOK_EOF && num_args < 32) {
        args[num_args++] = parse_expression(parser);
    }
    if (parser->current.type == TOK_RBRACE) {
        parser_advance(parser); /* Consume '}' */
    }

    return oz_ast_create_app(target, num_args, args, line);
}

static OzAstNode *parse_local(OzParser *parser) {
    uint32_t line = parser->current.line;
    parser_advance(parser); /* Consume 'local' */

    char *vars[64];
    uint32_t num_vars = 0;

    while (parser->current.type == TOK_VAR && num_vars < 64) {
        vars[num_vars++] = strdup(parser->current.as.text);
        parser_advance(parser);
    }

    if (parser_match(parser, TOK_KW_IN)) {
        OzAstNode *body = parse_statement(parser);
        if (parser_match(parser, TOK_KW_END)) {
            OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
            n->type = AST_LOCAL;
            n->line = line;
            n->as.local_decl.num_vars = num_vars;
            n->as.local_decl.vars = (char **)malloc(sizeof(char *) * num_vars);
            memcpy(n->as.local_decl.vars, vars, sizeof(char *) * num_vars);
            n->as.local_decl.body = body;
            return n;
        }
    }
    for (uint32_t i = 0; i < num_vars; ++i) free(vars[i]);
    return NULL;
}

static OzAstNode *parse_proc(OzParser *parser) {
    uint32_t line = parser->current.line;
    parser_advance(parser); /* Consume 'proc' */

    if (parser_match(parser, TOK_LBRACE)) {
        char *name = NULL;
        if (parser->current.type == TOK_VAR || parser->current.type == TOK_ATOM) {
            name = strdup(parser->current.as.text);
            parser_advance(parser);
        }
        char *params[32];
        uint32_t num_params = 0;
        while (parser->current.type == TOK_VAR && num_params < 32) {
            params[num_params++] = strdup(parser->current.as.text);
            parser_advance(parser);
        }
        if (parser_match(parser, TOK_RBRACE)) {
            OzAstNode *body = parse_statement(parser);
            if (parser_match(parser, TOK_KW_END)) {
                OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
                n->type = AST_PROC_DECL;
                n->line = line;
                n->as.proc_decl.name = name;
                n->as.proc_decl.num_params = num_params;
                n->as.proc_decl.params = (char **)malloc(sizeof(char *) * num_params);
                memcpy(n->as.proc_decl.params, params, sizeof(char *) * num_params);
                n->as.proc_decl.body = body;
                return n;
            }
        }
        free(name);
        for (uint32_t i = 0; i < num_params; ++i) free(params[i]);
    }
    return NULL;
}

static OzAstNode *parse_thread(OzParser *parser) {
    uint32_t line = parser->current.line;
    parser_advance(parser); /* Consume 'thread' */
    OzAstNode *body = parse_statement(parser);
    parser_match(parser, TOK_KW_END);

    OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
    n->type = AST_THREAD;
    n->line = line;
    n->as.thread_decl.body = body;
    return n;
}

static OzAstNode *parse_primary(OzParser *parser) {
    uint32_t line = parser->current.line;
    if (parser->current.type == TOK_INT) {
        int64_t v = parser->current.as.int_val;
        parser_advance(parser);
        return oz_ast_create_literal(oz_val_create_int(v), line);
    }
    if (parser->current.type == TOK_FLOAT) {
        double v = parser->current.as.float_val;
        parser_advance(parser);
        return oz_ast_create_literal(oz_val_create_float(v), line);
    }
    if (parser->current.type == TOK_ATOM) {
        char *name = strdup(parser->current.as.text);
        parser_advance(parser);
        OzAstNode *node = oz_ast_create_literal(oz_val_create_atom_name(name), line);
        free(name);
        return node;
    }
    if (parser->current.type == TOK_STRING) {
        char *str = strdup(parser->current.as.text);
        parser_advance(parser);
        OzAstNode *node = oz_ast_create_literal(oz_val_create_string(str, strlen(str)), line);
        free(str);
        return node;
    }
    if (parser->current.type == TOK_KW_NIL) {
        parser_advance(parser);
        return oz_ast_create_literal(oz_val_create_nil(), line);
    }
    if (parser->current.type == TOK_VAR) {
        char *name = strdup(parser->current.as.text);
        parser_advance(parser);
        OzAstNode *node = oz_ast_create_var(name, line);
        free(name);
        return node;
    }
    if (parser->current.type == TOK_LBRACE) {
        return parse_application_or_call(parser);
    }
    return NULL;
}

static OzAstNode *parse_expression(OzParser *parser) {
    OzAstNode *left = parse_primary(parser);
    if (!left) return NULL;

    /* Handle binary infix operators: =, +, -, *, /, == */
    if (parser->current.type == TOK_EQUAL) {
        uint32_t line = parser->current.line;
        parser_advance(parser);
        OzAstNode *right = parse_expression(parser);
        return oz_ast_create_unify(left, right, line);
    }
    return left;
}

static OzAstNode *parse_statement(OzParser *parser) {
    if (parser->current.type == TOK_KW_LOCAL) {
        return parse_local(parser);
    }
    if (parser->current.type == TOK_KW_PROC) {
        return parse_proc(parser);
    }
    if (parser->current.type == TOK_KW_THREAD) {
        return parse_thread(parser);
    }
    if (parser->current.type == TOK_KW_SKIP) {
        uint32_t line = parser->current.line;
        parser_advance(parser);
        return oz_ast_create_literal(oz_val_create_nil(), line);
    }

    OzAstNode *first = parse_expression(parser);
    if (!first) return NULL;

    /* If followed by another statement, sequence them */
    if (parser->current.type != TOK_KW_END &&
        parser->current.type != TOK_KW_IN &&
        parser->current.type != TOK_KW_ELSE &&
        parser->current.type != TOK_EOF &&
        parser->current.type != TOK_RBRACE) {
        OzAstNode *second = parse_statement(parser);
        if (second) {
            return oz_ast_create_seq(first, second, first->line);
        }
    }
    return first;
}

OzAstNode *oz_parse_source(const char *source, size_t length) {
    OzParser parser;
    oz_lexer_init(&parser.lexer, source, length);
    parser.current = oz_lexer_next_token(&parser.lexer);
    parser.peek = oz_lexer_next_token(&parser.lexer);

    /* Handle optional 'functor ... define ... end' wrapper */
    if (parser.current.type == TOK_KW_FUNCTOR) {
        while (parser.current.type != TOK_KW_DEFINE && parser.current.type != TOK_EOF) {
            parser_advance(&parser);
        }
        if (parser.current.type == TOK_KW_DEFINE) {
            parser_advance(&parser); /* Consume 'define' */
            OzAstNode *body = parse_statement(&parser);
            oz_token_free(&parser.current);
            oz_token_free(&parser.peek);
            return body;
        }
    }

    OzAstNode *root = parse_statement(&parser);
    oz_token_free(&parser.current);
    oz_token_free(&parser.peek);
    return root;
}
