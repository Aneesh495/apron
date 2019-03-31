#ifndef OZ_AST_H
#define OZ_AST_H

#include "oz_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    /* Special Tokens */
    TOK_EOF = 0,
    TOK_ERROR,

    /* Literals */
    TOK_INT,
    TOK_FLOAT,
    TOK_ATOM,
    TOK_VAR,
    TOK_STRING,

    /* Keywords */
    TOK_KW_FUNCTOR,
    TOK_KW_IMPORT,
    TOK_KW_EXPORT,
    TOK_KW_DEFINE,
    TOK_KW_PROC,
    TOK_KW_FUN,
    TOK_KW_LOCAL,
    TOK_KW_IN,
    TOK_KW_END,
    TOK_KW_THREAD,
    TOK_KW_CASE,
    TOK_KW_OF,
    TOK_KW_THEN,
    TOK_KW_ELSE,
    TOK_KW_ELSEIF,
    TOK_KW_IF,
    TOK_KW_NIL,
    TOK_KW_TRUE,
    TOK_KW_FALSE,
    TOK_KW_SKIP,

    /* Operators and Punctuation */
    TOK_EQUAL,              /* = */
    TOK_COLON_EQUAL,        /* := */
    TOK_EQUAL_EQUAL,        /* == */
    TOK_NOT_EQUAL,          /* \= */
    TOK_LESS,               /* < */
    TOK_LESS_EQUAL,         /* =< */
    TOK_GREATER,            /* > */
    TOK_GREATER_EQUAL,      /* >= */
    TOK_PLUS,               /* + */
    TOK_MINUS,              /* - */
    TOK_STAR,               /* * */
    TOK_SLASH,              /* / */
    TOK_TILDE,              /* ~ */
    TOK_PIPE,               /* | */
    TOK_COLON,              /* : */
    TOK_COMMA,              /* , */
    TOK_SEMICOLON,          /* ; */
    TOK_LBRACE,             /* { */
    TOK_RBRACE,             /* } */
    TOK_LBRACKET,           /* [ */
    TOK_RBRACKET,           /* ] */
    TOK_LPAREN,             /* ( */
    TOK_RPAREN,             /* ) */
    TOK_DOT                 /* . */
} OzTokenType;

typedef struct OzToken {
    OzTokenType type;
    uint32_t line;
    uint32_t column;
    union {
        int64_t int_val;
        double float_val;
        char *text;
    } as;
} OzToken;

/* Lexer State */
typedef struct OzLexer {
    const char *source;
    size_t length;
    size_t cursor;
    uint32_t line;
    uint32_t column;
} OzLexer;

void oz_lexer_init(OzLexer *lexer, const char *source, size_t length);
OzToken oz_lexer_next_token(OzLexer *lexer);
void oz_token_free(OzToken *tok);
const char *oz_token_type_name(OzTokenType type);

/* AST Node Structures */
typedef enum {
    AST_LITERAL = 0,
    AST_VAR,
    AST_LOCAL,
    AST_PROC_DECL,
    AST_FUN_DECL,
    AST_APP,            /* {P Arg1 Arg2 ...} */
    AST_UNIFY,          /* X = Y */
    AST_SEQ,            /* Stmt1 Stmt2 */
    AST_THREAD,         /* thread Stmt end */
    AST_IF,             /* if Cond then Stmt1 else Stmt2 end */
    AST_CASE,           /* case Expr of Pat1 then Stmt1 ... end */
    AST_FUNCTOR         /* functor ... define ... end */
} OzAstType;

typedef struct OzAstNode OzAstNode;

struct OzAstNode {
    OzAstType type;
    uint32_t line;
    union {
        /* Literal value */
        OzValue *literal;

        /* Variable name */
        char *var_name;

        /* Local declaration: local V1 V2 ... in Body end */
        struct {
            char **vars;
            uint32_t num_vars;
            OzAstNode *body;
        } local_decl;

        /* Procedure declaration: proc {Name Arg1 ...} Body end */
        struct {
            char *name;
            char **params;
            uint32_t num_params;
            OzAstNode *body;
        } proc_decl;

        /* Function declaration: fun {Name Arg1 ...} Body end */
        struct {
            char *name;
            char **params;
            uint32_t num_params;
            OzAstNode *body;
        } fun_decl;

        /* Application: {Target Arg1 Arg2 ...} */
        struct {
            OzAstNode *target;
            OzAstNode **args;
            uint32_t num_args;
        } app;

        /* Unification: Left = Right */
        struct {
            OzAstNode *left;
            OzAstNode *right;
        } unify;

        /* Statement sequence */
        struct {
            OzAstNode *first;
            OzAstNode *second;
        } seq;

        /* Concurrent thread: thread Body end */
        struct {
            OzAstNode *body;
        } thread_decl;

        /* Conditional: if Cond then ThenPart else ElsePart end */
        struct {
            OzAstNode *cond;
            OzAstNode *then_branch;
            OzAstNode *else_branch;
        } if_stmt;
    } as;
};

OzAstNode *oz_ast_create_var(const char *name, uint32_t line);
OzAstNode *oz_ast_create_literal(OzValue *val, uint32_t line);
OzAstNode *oz_ast_create_unify(OzAstNode *left, OzAstNode *right, uint32_t line);
OzAstNode *oz_ast_create_seq(OzAstNode *first, OzAstNode *second, uint32_t line);
OzAstNode *oz_ast_create_app(OzAstNode *target, uint32_t num_args, OzAstNode **args, uint32_t line);
void oz_ast_free(OzAstNode *node);

#ifdef __cplusplus
}
#endif

#endif /* OZ_AST_H */
