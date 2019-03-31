#include "oz_ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

void oz_lexer_init(OzLexer *lexer, const char *source, size_t length) {
    lexer->source = source;
    lexer->length = length;
    lexer->cursor = 0;
    lexer->line = 1;
    lexer->column = 1;
}

static char peek_char(const OzLexer *lexer) {
    if (lexer->cursor >= lexer->length) return '\0';
    return lexer->source[lexer->cursor];
}

static char next_char(OzLexer *lexer) {
    if (lexer->cursor >= lexer->length) return '\0';
    char c = lexer->source[lexer->cursor++];
    if (c == '\n') {
        lexer->line++;
        lexer->column = 1;
    } else {
        lexer->column++;
    }
    return c;
}

static void skip_whitespace_and_comments(OzLexer *lexer) {
    while (lexer->cursor < lexer->length) {
        char c = peek_char(lexer);
        if (isspace(c)) {
            next_char(lexer);
        } else if (c == '%') {
            /* Single-line comment: skip to newline */
            while (lexer->cursor < lexer->length && peek_char(lexer) != '\n') {
                next_char(lexer);
            }
        } else if (c == '/' && lexer->cursor + 1 < lexer->length && lexer->source[lexer->cursor + 1] == '*') {
            /* Multi-line comment: skip until closing */
            next_char(lexer); /* '/' */
            next_char(lexer); /* '*' */
            while (lexer->cursor + 1 < lexer->length) {
                if (lexer->source[lexer->cursor] == '*' && lexer->source[lexer->cursor + 1] == '/') {
                    next_char(lexer);
                    next_char(lexer);
                    break;
                }
                next_char(lexer);
            }
        } else {
            break;
        }
    }
}

static OzTokenType check_keyword(const char *text) {
    if (strcmp(text, "functor") == 0) return TOK_KW_FUNCTOR;
    if (strcmp(text, "import") == 0) return TOK_KW_IMPORT;
    if (strcmp(text, "export") == 0) return TOK_KW_EXPORT;
    if (strcmp(text, "define") == 0) return TOK_KW_DEFINE;
    if (strcmp(text, "proc") == 0) return TOK_KW_PROC;
    if (strcmp(text, "fun") == 0) return TOK_KW_FUN;
    if (strcmp(text, "local") == 0) return TOK_KW_LOCAL;
    if (strcmp(text, "in") == 0) return TOK_KW_IN;
    if (strcmp(text, "end") == 0) return TOK_KW_END;
    if (strcmp(text, "thread") == 0) return TOK_KW_THREAD;
    if (strcmp(text, "case") == 0) return TOK_KW_CASE;
    if (strcmp(text, "of") == 0) return TOK_KW_OF;
    if (strcmp(text, "then") == 0) return TOK_KW_THEN;
    if (strcmp(text, "else") == 0) return TOK_KW_ELSE;
    if (strcmp(text, "elseif") == 0) return TOK_KW_ELSEIF;
    if (strcmp(text, "if") == 0) return TOK_KW_IF;
    if (strcmp(text, "nil") == 0) return TOK_KW_NIL;
    if (strcmp(text, "true") == 0) return TOK_KW_TRUE;
    if (strcmp(text, "false") == 0) return TOK_KW_FALSE;
    if (strcmp(text, "skip") == 0) return TOK_KW_SKIP;
    return TOK_ATOM;
}

OzToken oz_lexer_next_token(OzLexer *lexer) {
    skip_whitespace_and_comments(lexer);

    OzToken tok;
    memset(&tok, 0, sizeof(OzToken));
    tok.line = lexer->line;
    tok.column = lexer->column;

    if (lexer->cursor >= lexer->length) {
        tok.type = TOK_EOF;
        return tok;
    }

    char c = peek_char(lexer);

    /* Numbers: integers and floats */
    if (isdigit(c) || (c == '~' && isdigit(lexer->cursor + 1 < lexer->length ? lexer->source[lexer->cursor + 1] : '\0'))) {
        bool neg = false;
        if (c == '~') {
            neg = true;
            next_char(lexer);
        }
        size_t start = lexer->cursor;
        bool is_float = false;
        while (lexer->cursor < lexer->length && (isdigit(peek_char(lexer)) || peek_char(lexer) == '.')) {
            if (peek_char(lexer) == '.') {
                if (is_float) break;
                is_float = true;
            }
            next_char(lexer);
        }
        size_t len = lexer->cursor - start;
        char *buf = (char *)malloc(len + 1);
        memcpy(buf, lexer->source + start, len);
        buf[len] = '\0';
        if (is_float) {
            tok.type = TOK_FLOAT;
            tok.as.float_val = atof(buf);
            if (neg) tok.as.float_val = -tok.as.float_val;
        } else {
            tok.type = TOK_INT;
            tok.as.int_val = atoll(buf);
            if (neg) tok.as.int_val = -tok.as.int_val;
        }
        free(buf);
        return tok;
    }

    /* Strings: "..." */
    if (c == '"') {
        next_char(lexer); /* Skip opening quote */
        size_t start = lexer->cursor;
        while (lexer->cursor < lexer->length && peek_char(lexer) != '"') {
            next_char(lexer);
        }
        size_t len = lexer->cursor - start;
        tok.type = TOK_STRING;
        tok.as.text = (char *)malloc(len + 1);
        memcpy(tok.as.text, lexer->source + start, len);
        tok.as.text[len] = '\0';
        if (peek_char(lexer) == '"') next_char(lexer); /* Skip closing quote */
        return tok;
    }

    /* Quoted Atoms: '...' */
    if (c == '\'') {
        next_char(lexer);
        size_t start = lexer->cursor;
        while (lexer->cursor < lexer->length && peek_char(lexer) != '\'') {
            next_char(lexer);
        }
        size_t len = lexer->cursor - start;
        tok.type = TOK_ATOM;
        tok.as.text = (char *)malloc(len + 1);
        memcpy(tok.as.text, lexer->source + start, len);
        tok.as.text[len] = '\0';
        if (peek_char(lexer) == '\'') next_char(lexer);
        return tok;
    }

    /* Variables: uppercase letter or underscore */
    if (isupper(c) || c == '_') {
        size_t start = lexer->cursor;
        while (lexer->cursor < lexer->length && (isalnum(peek_char(lexer)) || peek_char(lexer) == '_')) {
            next_char(lexer);
        }
        size_t len = lexer->cursor - start;
        tok.type = TOK_VAR;
        tok.as.text = (char *)malloc(len + 1);
        memcpy(tok.as.text, lexer->source + start, len);
        tok.as.text[len] = '\0';
        return tok;
    }

    /* Atoms and Keywords: lowercase letter */
    if (islower(c)) {
        size_t start = lexer->cursor;
        while (lexer->cursor < lexer->length && (isalnum(peek_char(lexer)) || peek_char(lexer) == '_')) {
            next_char(lexer);
        }
        size_t len = lexer->cursor - start;
        char *buf = (char *)malloc(len + 1);
        memcpy(buf, lexer->source + start, len);
        buf[len] = '\0';
        tok.type = check_keyword(buf);
        tok.as.text = buf;
        return tok;
    }

    /* Operators and punctuation */
    next_char(lexer);
    switch (c) {
        case '=':
            if (peek_char(lexer) == '=') { next_char(lexer); tok.type = TOK_EQUAL_EQUAL; }
            else if (peek_char(lexer) == '<') { next_char(lexer); tok.type = TOK_LESS_EQUAL; }
            else tok.type = TOK_EQUAL;
            break;
        case ':':
            if (peek_char(lexer) == '=') { next_char(lexer); tok.type = TOK_COLON_EQUAL; }
            else tok.type = TOK_COLON;
            break;
        case '\\':
            if (peek_char(lexer) == '=') { next_char(lexer); tok.type = TOK_NOT_EQUAL; }
            else tok.type = TOK_ERROR;
            break;
        case '<':
            tok.type = TOK_LESS;
            break;
        case '>':
            if (peek_char(lexer) == '=') { next_char(lexer); tok.type = TOK_GREATER_EQUAL; }
            else tok.type = TOK_GREATER;
            break;
        case '+': tok.type = TOK_PLUS; break;
        case '-': tok.type = TOK_MINUS; break;
        case '*': tok.type = TOK_STAR; break;
        case '/': tok.type = TOK_SLASH; break;
        case '~': tok.type = TOK_TILDE; break;
        case '|': tok.type = TOK_PIPE; break;
        case ',': tok.type = TOK_COMMA; break;
        case ';': tok.type = TOK_SEMICOLON; break;
        case '{': tok.type = TOK_LBRACE; break;
        case '}': tok.type = TOK_RBRACE; break;
        case '[': tok.type = TOK_LBRACKET; break;
        case ']': tok.type = TOK_RBRACKET; break;
        case '(': tok.type = TOK_LPAREN; break;
        case ')': tok.type = TOK_RPAREN; break;
        case '.': tok.type = TOK_DOT; break;
        default:
            tok.type = TOK_ERROR;
            break;
    }
    return tok;
}

void oz_token_free(OzToken *tok) {
    if (!tok) return;
    if (tok->type == TOK_VAR || tok->type == TOK_ATOM || tok->type == TOK_STRING) {
        free(tok->as.text);
        tok->as.text = NULL;
    }
}

const char *oz_token_type_name(OzTokenType type) {
    switch (type) {
        case TOK_EOF: return "EOF";
        case TOK_INT: return "INT";
        case TOK_FLOAT: return "FLOAT";
        case TOK_ATOM: return "ATOM";
        case TOK_VAR: return "VAR";
        case TOK_STRING: return "STRING";
        case TOK_KW_FUNCTOR: return "functor";
        case TOK_KW_IMPORT: return "import";
        case TOK_KW_EXPORT: return "export";
        case TOK_KW_DEFINE: return "define";
        case TOK_KW_PROC: return "proc";
        case TOK_KW_FUN: return "fun";
        case TOK_KW_LOCAL: return "local";
        case TOK_KW_IN: return "in";
        case TOK_KW_END: return "end";
        case TOK_KW_THREAD: return "thread";
        case TOK_KW_CASE: return "case";
        case TOK_KW_OF: return "of";
        case TOK_KW_THEN: return "then";
        case TOK_KW_ELSE: return "else";
        case TOK_KW_IF: return "if";
        case TOK_EQUAL: return "=";
        case TOK_LBRACE: return "{";
        case TOK_RBRACE: return "}";
        default: return "TOKEN";
    }
}

OzAstNode *oz_ast_create_var(const char *name, uint32_t line) {
    OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
    n->type = AST_VAR;
    n->line = line;
    n->as.var_name = strdup(name);
    return n;
}

OzAstNode *oz_ast_create_literal(OzValue *val, uint32_t line) {
    OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
    n->type = AST_LITERAL;
    n->line = line;
    n->as.literal = val;
    return n;
}

OzAstNode *oz_ast_create_unify(OzAstNode *left, OzAstNode *right, uint32_t line) {
    OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
    n->type = AST_UNIFY;
    n->line = line;
    n->as.unify.left = left;
    n->as.unify.right = right;
    return n;
}

OzAstNode *oz_ast_create_seq(OzAstNode *first, OzAstNode *second, uint32_t line) {
    OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
    n->type = AST_SEQ;
    n->line = line;
    n->as.seq.first = first;
    n->as.seq.second = second;
    return n;
}

OzAstNode *oz_ast_create_app(OzAstNode *target, uint32_t num_args, OzAstNode **args, uint32_t line) {
    OzAstNode *n = (OzAstNode *)calloc(1, sizeof(OzAstNode));
    n->type = AST_APP;
    n->line = line;
    n->as.app.target = target;
    n->as.app.num_args = num_args;
    if (num_args > 0 && args) {
        n->as.app.args = (OzAstNode **)malloc(sizeof(OzAstNode *) * num_args);
        memcpy(n->as.app.args, args, sizeof(OzAstNode *) * num_args);
    }
    return n;
}

void oz_ast_free(OzAstNode *node) {
    if (!node) return;
    switch (node->type) {
        case AST_VAR:
            free(node->as.var_name);
            break;
        case AST_LITERAL:
            oz_val_release(node->as.literal);
            break;
        case AST_UNIFY:
            oz_ast_free(node->as.unify.left);
            oz_ast_free(node->as.unify.right);
            break;
        case AST_SEQ:
            oz_ast_free(node->as.seq.first);
            oz_ast_free(node->as.seq.second);
            break;
        case AST_APP:
            oz_ast_free(node->as.app.target);
            for (uint32_t i = 0; i < node->as.app.num_args; ++i) {
                oz_ast_free(node->as.app.args[i]);
            }
            free(node->as.app.args);
            break;
        case AST_LOCAL:
            for (uint32_t i = 0; i < node->as.local_decl.num_vars; ++i) {
                free(node->as.local_decl.vars[i]);
            }
            free(node->as.local_decl.vars);
            oz_ast_free(node->as.local_decl.body);
            break;
        case AST_PROC_DECL:
            free(node->as.proc_decl.name);
            for (uint32_t i = 0; i < node->as.proc_decl.num_params; ++i) {
                free(node->as.proc_decl.params[i]);
            }
            free(node->as.proc_decl.params);
            oz_ast_free(node->as.proc_decl.body);
            break;
        case AST_FUN_DECL:
            free(node->as.fun_decl.name);
            for (uint32_t i = 0; i < node->as.fun_decl.num_params; ++i) {
                free(node->as.fun_decl.params[i]);
            }
            free(node->as.fun_decl.params);
            oz_ast_free(node->as.fun_decl.body);
            break;
        case AST_THREAD:
            oz_ast_free(node->as.thread_decl.body);
            break;
        case AST_IF:
            oz_ast_free(node->as.if_stmt.cond);
            oz_ast_free(node->as.if_stmt.then_branch);
            oz_ast_free(node->as.if_stmt.else_branch);
            break;
        default:
            break;
    }
    free(node);
}
