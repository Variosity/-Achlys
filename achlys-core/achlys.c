/*
 * ACHLYS - "The Mist of Death"
 * Version: Hybrid Core (Shadow/Neon) v1.5
 * Capabilities: Network (Hands), Graphics (Eyes - Optional), System (Voice)
 *
 * --- COMPILE INSTRUCTIONS ---
 *
 * 1. THE SHADOW (Red Team / Server / Headless):
 * Use this for stealth implants, servers, or systems without GPUs.
 * Command: gcc achlys.c -o achlys -lm
 *
 * 2. THE NEON (Cyberpunk OS / GUI / Games):
 * Use this for your graphical terminal and visual tools. Requires Raylib.
 * Command: gcc achlys.c -o achlys_gui -DENABLE_GRAPHICS -lraylib -lm
 */

 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <ctype.h>
 #include <math.h>
 #include <stdarg.h>
 
 // ============================================================================
 // [SECTION 1] IMPLANTS & HEADERS
 // ============================================================================
 
 // --- THE NEON LAYER (Graphics - Optional) ---
 // Only active if compiled with -DENABLE_GRAPHICS
 #ifdef ENABLE_GRAPHICS
     #include <raylib.h>
 #endif
 
 // --- THE NERVE LAYER (Networking) ---
 #ifdef _WIN32
     #include <winsock2.h>
     #include <ws2tcpip.h>
     #pragma comment(lib, "ws2_32.lib")
     #ifdef ENABLE_GRAPHICS
         #pragma comment(lib, "raylib.lib")
     #endif
     typedef int socklen_t;
 #else
     #include <sys/socket.h>
     #include <arpa/inet.h>
     #include <unistd.h>
     #include <netdb.h>
     #define INVALID_SOCKET -1
     #define SOCKET_ERROR -1
     typedef int SOCKET;
 #endif
 
 // ============================================================================
 // [SECTION 2] CORE TYPE DEFINITIONS
 // ============================================================================
 
 typedef enum {
     TOK_EOF, 
     TOK_INT, 
     TOK_FLOAT, 
     TOK_STRING, 
     TOK_IDENT,
     TOK_LET,        // vas, idea, umbra
     TOK_PRINT,      // scribo, monstro, insusurro
     TOK_IF,         // si
     TOK_ELSE,       // aliter
     TOK_WHILE,      // dum
     TOK_OPUS,       // opus
     TOK_REDDO,      // reddo
     TOK_BREAK,      // abrumpere
     TOK_CONTINUE,   // pergere
     TOK_BIT_AND,    // &
     TOK_BIT_OR,     // |
     TOK_BIT_XOR,    // xor
     TOK_BIT_NOT,    // ~
     TOK_RSHIFT,     // >>
     TOK_IMPORT,     // importare
     TOK_LPAREN, 
     TOK_RPAREN,     // ( )
     TOK_LBRACE, 
     TOK_RBRACE,     // { }
     TOK_LBRACKET, 
     TOK_RBRACKET,   // [ ]
     TOK_COLON,      // :
     TOK_ARROW,      // ->
     TOK_CARET,      // ^
     TOK_DOT,        // .
     TOK_APPEND,     // <<
     TOK_AND,        // et
     TOK_OR,         // vel
     TOK_CONST,
     TOK_SHARED,
     TOK_OP          // +, -, *, /, ==, !=, <, >, <=, >=
 } TokenType;
 
 typedef struct {
     TokenType type;
     char *text;
     long int_val;
     double float_val;
     int line; // Added for better error reporting
 } Token;
 
 typedef enum {
     VAL_INT, 
     VAL_FLOAT, 
     VAL_STRING, 
     VAL_LIST, 
     VAL_MAP, 
     VAL_FUNC,
     VAL_VOID
 } ValueType;
 
 typedef struct Value Value;
 typedef struct MapEntry MapEntry;
 typedef struct Function Function;
 
 struct MapEntry {
     char *key;
     Value *value;
     MapEntry *next;
 };
 
 struct Function {
     char *name;
     char **params;
     int param_count;
     void *body; // Stored as Stmt** cast to void* to break circular dep
     int body_count;
 };
 
 struct Value {
     ValueType type;
     union {
         long i;
         double f;
         char *s;
         struct {
             Value **items;
             int count;
             int capacity;
         } list;
         MapEntry *map;
         Function func;
     } data;
 };
 
 // ============================================================================
 // [SECTION 3] ENVIRONMENT (MEMORY)
 // ============================================================================
 
 int break_flag = 0; // Add this Global
 int continue_flag = 0; // Add this Global
 
 typedef struct EnvEntry {
     char *name;
     Value *value;
     struct EnvEntry *next;
 } EnvEntry;
 
 typedef struct {
     EnvEntry *head;
 } Environment;
 
 // Global Function Registry
 Environment *global_funcs;
 Environment *globals;
 // Return Value Register (For recursion handling)
 Value *return_value = NULL;
 
 Environment *env_new() {
     Environment *env = malloc(sizeof(Environment));
     env->head = NULL;
     return env;
 }
 // [NEW] Define a new variable (Strict: Creates new entry in current scope)
 void env_def(Environment *env, const char *name, Value *val) {
    EnvEntry *entry = malloc(sizeof(EnvEntry));
    entry->name = strdup(name);
    entry->value = val;
    entry->next = env->head;
    env->head = entry;
}

// [UPDATED] Update an existing variable (Strict: Crashes if variable not found)
// REPLACE YOUR EXISTING env_set WITH THIS:
void env_set(Environment *env, const char *name, Value *val) {
    // 1. Try updating local
    for (EnvEntry *e = env->head; e; e = e->next) {
        if (strcmp(e->name, name) == 0) {
            e->value = val;
            return;
        }
    }
    // 2. Try updating global (if allowed)
    if (globals) {
        for (EnvEntry *e = globals->head; e; e = e->next) {
            if (strcmp(e->name, name) == 0) {
                e->value = val;
                return;
            }
        }
    }
    // 3. Error
    fprintf(stderr, "💀 ERROR: Variable '%s' not declared. Use 'vas' or 'communis' first.\n", name);
    exit(1);
}
 
// REPLACE YOUR EXISTING env_get WITH THIS:
Value *env_get(Environment *env, const char *name) {
    // 1. Check Local Scope
    for (EnvEntry *e = env->head; e; e = e->next) {
        if (strcmp(e->name, name) == 0) return e->value;
    }
    // 2. Check Global Scope (The new feature)
    if (globals) {
        for (EnvEntry *e = globals->head; e; e = e->next) {
            if (strcmp(e->name, name) == 0) return e->value;
        }
    }
    // 3. Panic
    fprintf(stderr, "💀 [MEMORY ERROR] Variable '%s' not found in this reality.\n", name);
    exit(1);
}
 
 // ============================================================================
 // [SECTION 4] VALUE FACTORY
 // ============================================================================
 
 Value *val_int(long i) {
     Value *v = malloc(sizeof(Value));
     v->type = VAL_INT;
     v->data.i = i;
     return v;
 }
 
 Value *val_float(double f) {
     Value *v = malloc(sizeof(Value));
     v->type = VAL_FLOAT;
     v->data.f = f;
     return v;
 }
 
 Value *val_string(const char *s) {
     Value *v = malloc(sizeof(Value));
     v->type = VAL_STRING;
     v->data.s = strdup(s);
     return v;
 }
 
 Value *val_list() {
     Value *v = malloc(sizeof(Value));
     v->type = VAL_LIST;
     v->data.list.items = NULL;
     v->data.list.count = 0;
     v->data.list.capacity = 0;
     return v;
 }
 
 void list_append(Value *list, Value *item) {
     if (list->data.list.count >= list->data.list.capacity) {
         int new_cap = list->data.list.capacity == 0 ? 8 : list->data.list.capacity * 2;
         list->data.list.items = realloc(list->data.list.items, new_cap * sizeof(Value*));
         list->data.list.capacity = new_cap;
     }
     list->data.list.items[list->data.list.count++] = item;
 }
 
 Value *val_map() {
     Value *v = malloc(sizeof(Value));
     v->type = VAL_MAP;
     v->data.map = NULL;
     return v;
 }
 
 void map_set(Value *map, const char *key, Value *val) {
     for (MapEntry *e = map->data.map; e; e = e->next) {
         if (strcmp(e->key, key) == 0) {
             e->value = val;
             return;
         }
     }
     MapEntry *entry = malloc(sizeof(MapEntry));
     entry->key = strdup(key);
     entry->value = val;
     entry->next = map->data.map;
     map->data.map = entry;
 }
 
 Value *map_get(Value *map, const char *key) {
     for (MapEntry *e = map->data.map; e; e = e->next) {
         if (strcmp(e->key, key) == 0) return e->value;
     }
     fprintf(stderr, "💀 [OBJECT ERROR] Property '%s' not found on object.\n", key);
     exit(1);
 }
 
 // HELPER: COLOR MAPPING (Only compiled in Neon mode)
 #ifdef ENABLE_GRAPHICS
 Color get_color(long hex) {
     // 0=Black, 1=White, 2=Red, 3=Green, 4=Blue, 5=RayWhite, 6=DarkGray, 7=Gold
     if (hex == 0) return BLACK;
     if (hex == 1) return WHITE;
     if (hex == 2) return RED;
     if (hex == 3) return GREEN;
     if (hex == 4) return BLUE;
     if (hex == 5) return RAYWHITE;
     if (hex == 6) return DARKGRAY;
     if (hex == 7) return GOLD;
     // Default fallback: Parse standard Hex integers (0xRRGGBBAA)
     return (Color){ (hex >> 24) & 0xFF, (hex >> 16) & 0xFF, (hex >> 8) & 0xFF, hex & 0xFF };
 }
 #endif
 
 // ============================================================================
 // [SECTION 5] AST NODES
 // ============================================================================
 
 typedef enum {
     EXPR_INT, EXPR_FLOAT, EXPR_STRING, EXPR_VAR, EXPR_LIST, EXPR_MAP,
     EXPR_BINARY, EXPR_INDEX, EXPR_GET, EXPR_CALL, EXPR_INPUT, EXPR_READ, EXPR_MEASURE
 } ExprType;
 
 typedef struct Expr Expr;
 
 struct Expr {
     ExprType type;
     union {
         long i;
         double f;
         char *s;
         struct { Expr *left; char *op; Expr *right; } binary;
         struct { Expr *list; Expr *index; } index;
         struct { Expr *object; char *name; } get;
         struct { char *name; Expr **args; int arg_count; } call;
         struct { Expr **items; int count; } list;
         struct { char **keys; Expr **values; int count; } map;
         Expr *child;
     } data;
 };
 
 typedef enum {
     STMT_LET, STMT_ASSIGN, STMT_SET, STMT_APPEND, STMT_PRINT,
     STMT_IF, STMT_WHILE, STMT_FUNC, STMT_RETURN, STMT_IMPORT, STMT_BREAK, STMT_CONTINUE, STMT_EXPR, STMT_CONST, STMT_SHARED
 } StmtType;
 
 typedef struct Stmt Stmt;
 
 struct Stmt {
     StmtType type;
     union {
         struct { char *name; char *type_hint; Expr *value; } let;
         struct { char *name; Expr *value; } assign;
         struct { Expr *object; char *name; Expr *value; } set;
         struct { char *name; Expr *value; } append;
         Expr *expr;
         struct { Expr *cond; Stmt **then_stmts; int then_count; Stmt **else_stmts; int else_count; } if_stmt;
         struct { Expr *cond; Stmt **body; int body_count; } while_stmt;
         struct { char *name; char **params; int param_count; Stmt **body; int body_count; } func;
     } data;
 };
 
 // ============================================================================
 // [SECTION 6] LEXER
 // ============================================================================
 
 typedef struct {
     const char *src;
     int pos;
     Token *tokens;
     int token_count;
     int token_cap;
 } Lexer;
 
 void lexer_init(Lexer *lex, const char *src) {
     lex->src = src;
     lex->pos = 0;
     lex->token_cap = 256;
     lex->tokens = malloc(lex->token_cap * sizeof(Token));
     lex->token_count = 0;
 }
 
 void lexer_add_token(Lexer *lex, TokenType type, const char *text, long ival, double fval) {
    if (lex->token_count >= lex->token_cap) {
        lex->token_cap *= 2;
        lex->tokens = realloc(lex->tokens, lex->token_cap * sizeof(Token));
    }
    lex->tokens[lex->token_count].type = type;
    lex->tokens[lex->token_count].text = text ? strdup(text) : NULL;
    lex->tokens[lex->token_count].int_val = ival;   // <--- Added
    lex->tokens[lex->token_count].float_val = fval; // <--- Added
    lex->tokens[lex->token_count].line = 0;         // (Optional: Init line to 0)
    lex->token_count++;
}
 
 void lexer_run(Lexer *lexer) {
     const char *src = lexer->src;
     int i = 0;
     
     while (src[i]) {
         char c = src[i];
         
         if (isspace(c)) { i++; continue; }
         
         // Comments (// and /* */)
         if (c == '/') {
             if (src[i+1] == '/') {
                 while (src[i] && src[i] != '\n') i++;
                 continue;
             }
             if (src[i+1] == '*') {
                 i += 2;
                 while (src[i] && !(src[i] == '*' && src[i+1] == '/')) i++;
                 i += 2;
                 continue;
             }
             lexer_add_token(lexer, TOK_OP, "/", 0, 0);
             i++;
             continue;
         }
         
         // Single-char tokens
        if (c == '(') { lexer_add_token(lexer, TOK_LPAREN, "(", 0, 0); i++; continue; }
        if (c == ')') { lexer_add_token(lexer, TOK_RPAREN, ")", 0, 0); i++; continue; }
        if (c == '{') { lexer_add_token(lexer, TOK_LBRACE, "{", 0, 0); i++; continue; }
        if (c == '}') { lexer_add_token(lexer, TOK_RBRACE, "}", 0, 0); i++; continue; }
        if (c == '[') { lexer_add_token(lexer, TOK_LBRACKET, "[", 0, 0); i++; continue; }
        if (c == ']') { lexer_add_token(lexer, TOK_RBRACKET, "]", 0, 0); i++; continue; }
        if (c == ':') { lexer_add_token(lexer, TOK_COLON, ":", 0, 0); i++; continue; }
        if (c == '^') { lexer_add_token(lexer, TOK_CARET, "^", 0, 0); i++; continue; }
        if (c == ',') { lexer_add_token(lexer, TOK_OP, ",", 0, 0); i++; continue; }
        if (c == '.') { lexer_add_token(lexer, TOK_DOT, ".", 0, 0); i++; continue; }
        if (c == '&') { lexer_add_token(lexer, TOK_BIT_AND, "&", 0, 0); i++; continue; }
        if (c == '|') { lexer_add_token(lexer, TOK_BIT_OR, "|", 0, 0); i++; continue; }
        if (c == '~') { lexer_add_token(lexer, TOK_BIT_NOT, "~", 0, 0); i++; continue; }
         
         // Multi-char operators
         if (c == '<' && src[i+1] == '<') {
             lexer_add_token(lexer, TOK_APPEND, NULL, 0, 0);
             i += 2;
             continue;
         }

         if (c == '>' && src[i+1] == '>') { // Right Shift >>
            lexer_add_token(lexer, TOK_RSHIFT, NULL, 0, 0);
            i += 2;
            continue;
        }
         
         // Arrow ->
         if (c == '-' && src[i+1] == '>') {
             lexer_add_token(lexer, TOK_ARROW, NULL, 0, 0);
             i += 2;
             continue;
         }
         
         // Standard Operators (+, -, *, /, <, >, ==, !=)
         if (c == '<' || c == '>' || c == '=' || c == '!') {
             char op[3] = {c, 0, 0};
             i++;
             if (src[i] == '=') { op[1] = '='; i++; }
             lexer_add_token(lexer, TOK_OP, op, 0 ,0);
             continue;
         }
         
         if (c == '+' || c == '-' || c == '*' || c == '/' || c == '%') {
             char op[2] = {c, 0};
             lexer_add_token(lexer, TOK_OP, op, 0, 0);
             i++;
             continue;
         }
         
         // String Literals
         if (c == '"') {
             i++;
             char str[4096]; // Increased buffer size for large strings/payloads
             int str_idx = 0;
             
             while (src[i] && src[i] != '"') {
                 if (src[i] == '\\' && src[i+1]) {
                     i++;
                     switch (src[i]) {
                         case 'n': str[str_idx++] = '\n'; break;
                         case 't': str[str_idx++] = '\t'; break;
                         case 'r': str[str_idx++] = '\r'; break;
                         case '"': str[str_idx++] = '"'; break;
                         case '\\': str[str_idx++] = '\\'; break;
                         default: str[str_idx++] = src[i]; break;
                     }
                 } else {
                     str[str_idx++] = src[i];
                 }
                 i++;
             }
             str[str_idx] = 0;
             lexer_add_token(lexer, TOK_STRING, str, 0, 0);
             i++;
             continue;
         }
         
         // Numbers (Integers and Floats)
         if (isdigit(c)) {
            // Check for Hex (0x...)
            if (c == '0' && (src[i+1] == 'x' || src[i+1] == 'X')) {
                i += 2; // Skip '0x'
                int start = i;
                while (isxdigit(src[i])) i++;
                
                char *n = malloc(i - start + 1);
                memcpy(n, src + start, i - start);
                n[i - start] = 0;
                
                // Parse as base 16
                long val = strtol(n, NULL, 16);
                lexer_add_token(lexer, TOK_INT, n, val, 0);
                free(n);
                continue;
            }
         
            else {
            int start = i, fl = 0;
            // 1. Exact same parsing logic as before
            while (isdigit(src[i]) || (src[i] == '.' && !fl)) { 
                if (src[i] == '.') fl = 1; 
                i++; 
            }
            
            // 2. Extract string
            char *n = malloc(i - start + 1);
            memcpy(n, src + start, i - start);
            n[i - start] = 0;
            
            // 3. Safe insertion (Uses strdup internally to prevent memory errors)
            if (fl) lexer_add_token(lexer, TOK_FLOAT, n, 0, atof(n));
            else lexer_add_token(lexer, TOK_INT, n, atol(n), 0);
            
            free(n); // Safe to free because lexer_add_token made a copy
            continue;
        }
    }
         
         // Identifiers and Keywords
         if (isalpha(c) || c == '_') {
             int start = i;
             while (isalnum(src[i]) || src[i] == '_') i++;
             char *word = malloc(i - start + 1);
             memcpy(word, src + start, i - start);
             word[i - start] = 0;
             
             TokenType type = TOK_IDENT;
             if (strcmp(word, "vas") == 0 || strcmp(word, "idea") == 0 || strcmp(word, "umbra") == 0) type = TOK_LET;
             else if (strcmp(word, "scribo") == 0 || strcmp(word, "monstro") == 0 || strcmp(word, "insusurro") == 0) type = TOK_PRINT;
             else if (strcmp(word, "si") == 0) type = TOK_IF;
             else if (strcmp(word, "aliter") == 0) type = TOK_ELSE;
             else if (strcmp(word, "dum") == 0) type = TOK_WHILE;
             else if (strcmp(word, "opus") == 0) type = TOK_OPUS;
             else if (strcmp(word, "reddo") == 0) type = TOK_REDDO;
             else if (strcmp(word, "importare") == 0) type = TOK_IMPORT;
             else if (strcmp(word, "abrumpere") == 0) type = TOK_BREAK;
             else if (strcmp(word, "pergere") == 0) type = TOK_CONTINUE;
             else if (strcmp(word, "constans") == 0) type = TOK_CONST;
             else if (strcmp(word, "communis") == 0) type = TOK_SHARED;
             else if (strcmp(word, "et") == 0) type = TOK_AND;  // <--- NEW
             else if (strcmp(word, "vel") == 0) type = TOK_OR;  // <--- NEW
             else if (strcmp(word, "xor") == 0) type = TOK_BIT_XOR;
             else if (strcmp(word, "verum") == 0) { 
                lexer_add_token(lexer, TOK_INT, "1", 1, 0); 
                free(word); 
                continue; 
            }
            else if (strcmp(word, "falsum") == 0) { 
                lexer_add_token(lexer, TOK_INT, "0", 0, 0); 
                free(word); 
                continue; 
            }
             
             lexer_add_token(lexer, type, word, 0, 0);
             free(word);
             continue;
         }
         
         i++;
     }
     
     lexer_add_token(lexer, TOK_EOF, NULL, 0, 0);
 }
 
 // ============================================================================
 // [SECTION 7] PARSER
 // ============================================================================
 
 typedef struct {
     Token *tokens;
     int pos;
     int count;
 } Parser;
 
 void parser_init(Parser *p, Token *tokens, int count);
 Token *parser_peek(Parser *p);
 Token *parser_advance(Parser *p);
 void parser_expect(Parser *p, TokenType type);
 Expr *parse_expr(Parser *p);
 Stmt **parse_program(Parser *p, int *stmt_count);
 
 // PARSER implementation
 void parser_init(Parser *p, Token *tokens, int count) {
     p->tokens = tokens;
     p->pos = 0;
     p->count = count;
 }
 
 Token *parser_peek(Parser *p) {
     return &p->tokens[p->pos];
 }
 
 Token *parser_advance(Parser *p) {
     return &p->tokens[p->pos++];
 }
 
 void parser_expect(Parser *p, TokenType type) {
     if (parser_peek(p)->type != type) {
         fprintf(stderr, "💀 Parse error: expected token type %d at pos %d\n", type, p->pos);
         exit(1);
     }
     parser_advance(p);
 }
 
 // Forward declarations
 Expr *parse_primary(Parser *p);
 Expr *parse_postfix(Parser *p);
 Expr *parse_unary(Parser *p); 
 Expr *parse_factor(Parser *p);
 Expr *parse_comparison(Parser *p);
 Expr *parse_term(Parser *p);
 
 Expr *parse_primary(Parser *p) {
     Token *t = parser_peek(p);
     
     if (t->type == TOK_INT) {
         Expr *e = malloc(sizeof(Expr));
         e->type = EXPR_INT;
         e->data.i = t->int_val;
         parser_advance(p);
         return e;
     }
     
     if (t->type == TOK_FLOAT) {
         Expr *e = malloc(sizeof(Expr));
         e->type = EXPR_FLOAT;
         e->data.f = t->float_val;
         parser_advance(p);
         return e;
     }
     
     if (t->type == TOK_STRING) {
         Expr *e = malloc(sizeof(Expr));
         e->type = EXPR_STRING;
         e->data.s = strdup(t->text);
         parser_advance(p);
         return e;
     }
     
     if (t->type == TOK_LBRACKET) {
         parser_advance(p);
         Expr *e = malloc(sizeof(Expr));
         e->type = EXPR_LIST;
         e->data.list.count = 0;
         e->data.list.items = malloc(16 * sizeof(Expr*));
         
         if (parser_peek(p)->type != TOK_RBRACKET) {
             e->data.list.items[e->data.list.count++] = parse_expr(p);
             while (parser_peek(p)->type == TOK_OP && strcmp(parser_peek(p)->text, ",") == 0) {
                 parser_advance(p);
                 e->data.list.items[e->data.list.count++] = parse_expr(p);
             }
         }
         parser_expect(p, TOK_RBRACKET);
         return e;
     }
     
     if (t->type == TOK_LBRACE) {
         parser_advance(p);
         Expr *e = malloc(sizeof(Expr));
         e->type = EXPR_MAP;
         e->data.map.count = 0;
         e->data.map.keys = malloc(16 * sizeof(char*));
         e->data.map.values = malloc(16 * sizeof(Expr*));
         
         while (parser_peek(p)->type != TOK_RBRACE) {
             Token *key = parser_advance(p);
             e->data.map.keys[e->data.map.count] = strdup(key->text);
             parser_expect(p, TOK_COLON);
             e->data.map.values[e->data.map.count] = parse_expr(p);
             e->data.map.count++;
             
             if (parser_peek(p)->type != TOK_RBRACE) {
                 parser_expect(p, TOK_OP);
             }
         }
         parser_expect(p, TOK_RBRACE);
         return e;
     }
     
     if (t->type == TOK_IDENT) {
         char *name = strdup(t->text);
         parser_advance(p);
         
         if (strcmp(name, "capio") == 0) {
             parser_expect(p, TOK_LPAREN);
             parser_expect(p, TOK_RPAREN);
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_INPUT;
             return e;
         }
         
         if (strcmp(name, "revelare") == 0) {
             parser_expect(p, TOK_LPAREN);
             Expr *arg = parse_expr(p);
             parser_expect(p, TOK_RPAREN);
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_READ;
             e->data.child = arg;
             return e;
         }
         
         if (strcmp(name, "mensura") == 0) {
             parser_expect(p, TOK_LPAREN);
             Expr *arg = parse_expr(p);
             parser_expect(p, TOK_RPAREN);
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_MEASURE;
             e->data.child = arg;
             return e;
         }
         
         if (parser_peek(p)->type == TOK_LPAREN) {
             parser_advance(p);
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_CALL;
             e->data.call.name = name;
             e->data.call.args = malloc(16 * sizeof(Expr*));
             e->data.call.arg_count = 0;
             
             if (parser_peek(p)->type != TOK_RPAREN) {
                 e->data.call.args[e->data.call.arg_count++] = parse_expr(p);
                 while (parser_peek(p)->type == TOK_OP && strcmp(parser_peek(p)->text, ",") == 0) {
                     parser_advance(p);
                     e->data.call.args[e->data.call.arg_count++] = parse_expr(p);
                 }
             }
             parser_expect(p, TOK_RPAREN);
             return e;
         }
         
         Expr *e = malloc(sizeof(Expr));
         e->type = EXPR_VAR;
         e->data.s = name;
         return e;
     }
     
     if (t->type == TOK_LPAREN) {
         parser_advance(p);
         Expr *e = parse_expr(p);
         parser_expect(p, TOK_RPAREN);
         return e;
     }
     
     fprintf(stderr, "💀 Unexpected token in expression at pos %d\n", p->pos);
     exit(1);
 }
 
 Expr *parse_postfix(Parser *p) {
     Expr *expr = parse_primary(p);
     
     while (1) {
         if (parser_peek(p)->type == TOK_LBRACKET) {
             parser_advance(p);
             Expr *index = parse_expr(p);
             parser_expect(p, TOK_RBRACKET);
             
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_INDEX;
             e->data.index.list = expr;
             e->data.index.index = index;
             expr = e;
         } else if (parser_peek(p)->type == TOK_DOT) {
             parser_advance(p);
             Token *prop = parser_advance(p);
             
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_GET;
             e->data.get.object = expr;
             e->data.get.name = strdup(prop->text);
             expr = e;
         } else {
             break;
         }
     }
     
     return expr;
 }
 
 Expr *parse_unary(Parser *p) {
    // Handle Unary Operators (-, !, ~)
    if (parser_peek(p)->type == TOK_OP || parser_peek(p)->type == TOK_BIT_NOT) {
        char *op = parser_peek(p)->text;
        TokenType type = parser_peek(p)->type;

        // Handle Negative Numbers (-x)
        if (type == TOK_OP && strcmp(op, "-") == 0) {
            parser_advance(p);
            Expr *right = parse_unary(p);
            
            // Convert "-x" to "0 - x"
            Expr *zero = malloc(sizeof(Expr));
            zero->type = EXPR_INT;
            zero->data.i = 0;
            
            Expr *e = malloc(sizeof(Expr));
            e->type = EXPR_BINARY;
            e->data.binary.left = zero;
            e->data.binary.op = strdup("-");
            e->data.binary.right = right;
            return e;
        }
        
        // Handle Logical NOT (!x)
        if (type == TOK_OP && strcmp(op, "!") == 0) {
            parser_advance(p);
            Expr *right = parse_unary(p);
            
            // Convert "!x" to "x == 0"
            Expr *zero = malloc(sizeof(Expr));
            zero->type = EXPR_INT;
            zero->data.i = 0;
            
            Expr *e = malloc(sizeof(Expr));
            e->type = EXPR_BINARY;
            e->data.binary.left = right;
            e->data.binary.op = strdup("==");
            e->data.binary.right = zero;
            return e;
        }
        
        // Handle Bitwise NOT (~x)
        if (type == TOK_BIT_NOT || (type == TOK_OP && strcmp(op, "~") == 0)) {
           parser_advance(p);
           Expr *right = parse_unary(p);
           
           Expr *e = malloc(sizeof(Expr));
           e->type = EXPR_BINARY;
           e->data.binary.left = right;
           e->data.binary.op = strdup("~");
           
           // [FIX] Create a Syntax Tree Node (Expr), NOT a Runtime Value
           Expr *dummy = malloc(sizeof(Expr));
           dummy->type = EXPR_INT;
           dummy->data.i = 0;
           
           e->data.binary.right = dummy;
           return e;
       }
    }
    
    return parse_postfix(p);
}
 
 Expr *parse_factor(Parser *p) {
     Expr *left = parse_unary(p); 
     
     while (parser_peek(p)->type == TOK_OP) {
         char *op = parser_peek(p)->text;
         if (strcmp(op, "*") == 0 || strcmp(op, "/") == 0 || strcmp(op, "%") == 0) {
             parser_advance(p);
             Expr *right = parse_unary(p);
             
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_BINARY;
             e->data.binary.left = left;
             e->data.binary.op = strdup(op);
             e->data.binary.right = right;
             left = e;
         } else {
             break;
         }
     }
     
     return left;
 }
 
 Expr *parse_term(Parser *p) {
     Expr *left = parse_factor(p);
     
     while (parser_peek(p)->type == TOK_OP) {
         char *op = parser_peek(p)->text;
         if (strcmp(op, "+") == 0 || strcmp(op, "-") == 0) {
             parser_advance(p);
             Expr *right = parse_factor(p);
             
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_BINARY;
             e->data.binary.left = left;
             e->data.binary.op = strdup(op);
             e->data.binary.right = right;
             left = e;
         } else {
             break;
         }
     }
     
     return left;
 }

 // 1. BITWISE (Calls parse_term for the next level down)
 Expr *parse_bitwise(Parser *p) {
    Expr *left = parse_term(p); // Lower precedence (+ -)
    
    while (parser_peek(p)->type == TOK_BIT_AND || 
           parser_peek(p)->type == TOK_BIT_OR || 
           parser_peek(p)->type == TOK_BIT_XOR ||
           parser_peek(p)->type == TOK_RSHIFT ||
           parser_peek(p)->type == TOK_APPEND) { 
        
        TokenType type = parser_peek(p)->type;
        char *op = "";
        
        if (type == TOK_BIT_AND) op = "&";
        else if (type == TOK_BIT_OR) op = "|";
        else if (type == TOK_BIT_XOR) op = "^";
        else if (type == TOK_RSHIFT) op = ">>";
        else if (type == TOK_APPEND) op = "<<"; 
        
        parser_advance(p);
        Expr *right = parse_term(p); // Right side is also a term
        
        Expr *e = malloc(sizeof(Expr));
        e->type = EXPR_BINARY;
        e->data.binary.left = left;
        e->data.binary.op = strdup(op);
        e->data.binary.right = right;
        left = e;
    }
    return left;
}
 
 // 2. COMPARISON (Calls parse_bitwise for the next level down)
 Expr *parse_comparison(Parser *p) {
     Expr *left = parse_bitwise(p); // [FIX] Now calls bitwise
     
     while (parser_peek(p)->type == TOK_OP) {
         char *op = parser_peek(p)->text;
         if (strcmp(op, "<") == 0 || strcmp(op, ">") == 0 || 
             strcmp(op, "==") == 0 || strcmp(op, "!=") == 0 ||
             strcmp(op, "<=") == 0 || strcmp(op, ">=") == 0) {
             parser_advance(p);
             Expr *right = parse_bitwise(p); // [FIX] Right side is also bitwise
             
             Expr *e = malloc(sizeof(Expr));
             e->type = EXPR_BINARY;
             e->data.binary.left = left;
             e->data.binary.op = strdup(op);
             e->data.binary.right = right;
             left = e;
         } else {
             break;
         }
     }
     return left;
 }
 
 // 3. EXPRESSION (Calls parse_comparison for the next level down)
 Expr *parse_expr(Parser *p) {
    Expr *left = parse_comparison(p); // [FIX] Calls comparison (Top of chain)
    
    while (parser_peek(p)->type == TOK_AND || parser_peek(p)->type == TOK_OR) {
        TokenType type = parser_peek(p)->type;
        char *op = type == TOK_AND ? "et" : "vel";
        parser_advance(p);
        
        Expr *right = parse_comparison(p);
        
        Expr *e = malloc(sizeof(Expr));
        e->type = EXPR_BINARY;
        e->data.binary.left = left;
        e->data.binary.op = strdup(op);
        e->data.binary.right = right;
        left = e;
    }
    return left;
}

Stmt *parse_continue(Parser *p) {
    parser_advance(p); // Skip 'pergere'
    parser_expect(p, TOK_CARET); // Expect ^
    
    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_CONTINUE;
    return s;
}
 
 Stmt *parse_break(Parser *p) {
    parser_advance(p); // Skip 'abrumpere'
    parser_expect(p, TOK_CARET); // Expect ^
    
    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_BREAK;
    return s;
}

// Essentially the same as parse_let, but with different Statement Types
Stmt *parse_const(Parser *p) {
    parser_advance(p); // Skip 'constans'
    Token *name = parser_advance(p);

    parser_expect(p, TOK_COLON); 
    Token *type_token = parser_advance(p); // Ignore type for now or check it
    char *hint = strdup(type_token->text);

    parser_expect(p, TOK_ARROW);
    Expr *value = parse_expr(p);
    parser_expect(p, TOK_CARET);

    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_CONST;
    s->data.let.name = strdup(name->text);
    s->data.let.type_hint = hint;
    s->data.let.value = value;
    return s;
}

Stmt *parse_shared(Parser *p) {
    parser_advance(p); // Skip 'communis'
    Token *name = parser_advance(p);

    parser_expect(p, TOK_COLON); 
    Token *type_token = parser_advance(p);
    char *hint = strdup(type_token->text);

    parser_expect(p, TOK_ARROW);
    Expr *value = parse_expr(p);
    parser_expect(p, TOK_CARET);

    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_SHARED;
    s->data.let.name = strdup(name->text);
    s->data.let.type_hint = hint;
    s->data.let.value = value;
    return s;
}
 
 Stmt *parse_stmt(Parser *p);
 
 Stmt *parse_let(Parser *p) {
    parser_advance(p); // Skip 'vas'
    Token *name = parser_advance(p); // Get name
    
    // [FIX] MANDATORY TYPE DECLARATION
    // Code like 'vas x -> 10' will now FAIL. Must be 'vas x : int -> 10'
    parser_expect(p, TOK_COLON); 
    Token *type_token = parser_advance(p); 
    char *hint = strdup(type_token->text);
    
    parser_expect(p, TOK_ARROW);
    Expr *value = parse_expr(p);
    parser_expect(p, TOK_CARET);
    
    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_LET;
    s->data.let.name = strdup(name->text);
    s->data.let.type_hint = hint; // We store it for the evaluator
    s->data.let.value = value;
    return s;
}
 
 Stmt *parse_print(Parser *p) {
     parser_advance(p);
     parser_expect(p, TOK_LPAREN);
     Expr *e = parse_expr(p);
     parser_expect(p, TOK_RPAREN);
     parser_expect(p, TOK_CARET);
     
     Stmt *s = malloc(sizeof(Stmt));
     s->type = STMT_PRINT;
     s->data.expr = e;
     return s;
 }
 
 Stmt *parse_if(Parser *p) {
    parser_advance(p);
    parser_expect(p, TOK_LPAREN);
    Expr *cond = parse_expr(p);
    parser_expect(p, TOK_RPAREN);
    parser_expect(p, TOK_LBRACE);
    
    Stmt **then_stmts = malloc(64 * sizeof(Stmt*));
    int then_count = 0;
    while (parser_peek(p)->type != TOK_RBRACE) {
        // FIX: Ignore stray carets inside blocks
        if (parser_peek(p)->type == TOK_CARET) { parser_advance(p); continue; }
        then_stmts[then_count++] = parse_stmt(p);
    }
    parser_advance(p);
    
    Stmt **else_stmts = NULL;
    int else_count = 0;
    if (parser_peek(p)->type == TOK_ELSE) {
        parser_advance(p);
        parser_expect(p, TOK_LBRACE);
        else_stmts = malloc(64 * sizeof(Stmt*));
        while (parser_peek(p)->type != TOK_RBRACE) {
            // FIX: Ignore stray carets inside else blocks
            if (parser_peek(p)->type == TOK_CARET) { parser_advance(p); continue; }
            else_stmts[else_count++] = parse_stmt(p);
        }
        parser_advance(p);
    }
    
    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_IF;
    s->data.if_stmt.cond = cond;
    s->data.if_stmt.then_stmts = then_stmts;
    s->data.if_stmt.then_count = then_count;
    s->data.if_stmt.else_stmts = else_stmts;
    s->data.if_stmt.else_count = else_count;
    return s;
}
 
Stmt *parse_while(Parser *p) {
    parser_advance(p);
    parser_expect(p, TOK_LPAREN);
    Expr *cond = parse_expr(p);
    parser_expect(p, TOK_RPAREN);
    parser_expect(p, TOK_LBRACE);
    
    Stmt **body = malloc(64 * sizeof(Stmt*));
    int body_count = 0;
    while (parser_peek(p)->type != TOK_RBRACE) {
        // FIX: Ignore stray carets inside loops
        if (parser_peek(p)->type == TOK_CARET) { parser_advance(p); continue; }
        body[body_count++] = parse_stmt(p);
    }
    parser_advance(p);
    
    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_WHILE;
    s->data.while_stmt.cond = cond;
    s->data.while_stmt.body = body;
    s->data.while_stmt.body_count = body_count;
    return s;
}
 
Stmt *parse_function(Parser *p) {
    parser_advance(p);
    Token *name = parser_advance(p);
    parser_expect(p, TOK_LPAREN);
    
    char **params = malloc(16 * sizeof(char*));
    int param_count = 0;
    if (parser_peek(p)->type != TOK_RPAREN) {
        params[param_count++] = strdup(parser_advance(p)->text);
        while (parser_peek(p)->type == TOK_OP && strcmp(parser_peek(p)->text, ",") == 0) {
            parser_advance(p);
            params[param_count++] = strdup(parser_advance(p)->text);
        }
    }
    parser_expect(p, TOK_RPAREN);
    parser_expect(p, TOK_LBRACE);
    
    Stmt **body = malloc(64 * sizeof(Stmt*));
    int body_count = 0;
    while (parser_peek(p)->type != TOK_RBRACE) {
        // FIX: Ignore stray carets inside functions
        if (parser_peek(p)->type == TOK_CARET) { parser_advance(p); continue; }
        body[body_count++] = parse_stmt(p);
    }
    parser_advance(p);
    
    Stmt *s = malloc(sizeof(Stmt));
    s->type = STMT_FUNC;
    s->data.func.name = strdup(name->text);
    s->data.func.params = params;
    s->data.func.param_count = param_count;
    s->data.func.body = body;
    s->data.func.body_count = body_count;
    return s;
}
 
 Stmt *parse_return(Parser *p) {
     parser_advance(p);
     Expr *e = parse_expr(p);
     parser_expect(p, TOK_CARET);
     
     Stmt *s = malloc(sizeof(Stmt));
     s->type = STMT_RETURN;
     s->data.expr = e;
     return s;
 }
 
 Stmt *parse_import(Parser *p) {
     parser_advance(p);
     parser_expect(p, TOK_LPAREN);
     Expr *path = parse_expr(p);
     parser_expect(p, TOK_RPAREN);
     parser_expect(p, TOK_CARET);
     
     Stmt *s = malloc(sizeof(Stmt));
     s->type = STMT_IMPORT;
     s->data.expr = path;
     return s;
 }
 
 Stmt *parse_stmt(Parser *p) {
     Token *t = parser_peek(p);
     
     if (t->type == TOK_LET) return parse_let(p);
     if (t->type == TOK_CONST) return parse_const(p);   // <--- ADD
    if (t->type == TOK_SHARED) return parse_shared(p);   // <--- ADD
     if (t->type == TOK_PRINT) return parse_print(p);
     if (t->type == TOK_IF) return parse_if(p);
     if (t->type == TOK_WHILE) return parse_while(p);
     if (t->type == TOK_OPUS) return parse_function(p);
     if (t->type == TOK_REDDO) return parse_return(p);
     if (t->type == TOK_IMPORT) return parse_import(p);
     if (t->type == TOK_BREAK) return parse_break(p);
     if (t->type == TOK_CONTINUE) return parse_continue(p);
     
     if (t->type == TOK_IDENT) {
         Expr *expr = parse_expr(p);
         
         if (parser_peek(p)->type == TOK_ARROW) {
             parser_advance(p);
             Expr *value = parse_expr(p);
             parser_expect(p, TOK_CARET);
             
             Stmt *s = malloc(sizeof(Stmt));
             if (expr->type == EXPR_VAR) {
                 s->type = STMT_ASSIGN;
                 s->data.assign.name = expr->data.s;
                 s->data.assign.value = value;
             } else if (expr->type == EXPR_GET) {
                 s->type = STMT_SET;
                 s->data.set.object = expr->data.get.object;
                 s->data.set.name = expr->data.get.name;
                 s->data.set.value = value;
             }
             return s;
         } else if (parser_peek(p)->type == TOK_APPEND) {
             parser_advance(p);
             Expr *value = parse_expr(p);
             parser_expect(p, TOK_CARET);
             
             Stmt *s = malloc(sizeof(Stmt));
             s->type = STMT_APPEND;
             s->data.append.name = expr->data.s;
             s->data.append.value = value;
             return s;
         } else {
             parser_expect(p, TOK_CARET);
             Stmt *s = malloc(sizeof(Stmt));
             s->type = STMT_EXPR;
             s->data.expr = expr;
             return s;
         }
     }
     
     fprintf(stderr, "💀 Unexpected statement: %s at pos %d\n", t->text, p->pos);
     exit(1);
 }
 
 Stmt **parse_program(Parser *p, int *stmt_count) {
    Stmt **stmts = malloc(256 * sizeof(Stmt*));
    *stmt_count = 0;
    
    while (parser_peek(p)->type != TOK_EOF) {
        // FIX: Ignore stray carets at the root level
        if (parser_peek(p)->type == TOK_CARET) { parser_advance(p); continue; }
        stmts[(*stmt_count)++] = parse_stmt(p);
    }
    
    return stmts;
}
 
 // ============================================================================
 // [SECTION 8] EVALUATOR / VM
 // ============================================================================
 
 Value *eval_expr(Expr *e, Environment *env);
 void run_stmts(Stmt **stmts, int count, Environment *env);
 
 void print_value(Value *v) {
     switch (v->type) {
         case VAL_INT:
             printf("%ld", v->data.i);
             break;
         case VAL_FLOAT:
             printf("%f", v->data.f);
             break;
         case VAL_STRING:
             printf("%s", v->data.s);
             break;
         case VAL_LIST:
             printf("[");
             for (int i = 0; i < v->data.list.count; i++) {
                 print_value(v->data.list.items[i]);
                 if (i < v->data.list.count - 1) printf(", ");
             }
             printf("]");
             break;
         case VAL_MAP:
             printf("{ ");
             for (MapEntry *e = v->data.map; e; e = e->next) {
                 printf("%s: ", e->key);
                 print_value(e->value);
                 if (e->next) printf(", ");
             }
             printf(" }");
             break;
         default:
             printf("unknown");
     }
 }
 
 int truthy(Value *v) {
     return v->type == VAL_INT && v->data.i != 0;
 }
 
 Value *eval_expr(Expr *e, Environment *env) {
     switch (e->type) {
         case EXPR_INT:
             return val_int(e->data.i);
         
         case EXPR_FLOAT:
             return val_float(e->data.f);
         
         case EXPR_STRING:
             return val_string(e->data.s);
         
         case EXPR_VAR:
             return env_get(env, e->data.s);
         
         case EXPR_LIST: {
             Value *list = val_list();
             for (int i = 0; i < e->data.list.count; i++) {
                 list_append(list, eval_expr(e->data.list.items[i], env));
             }
             return list;
         }
         
         case EXPR_MAP: {
             Value *map = val_map();
             for (int i = 0; i < e->data.map.count; i++) {
                 map_set(map, e->data.map.keys[i], eval_expr(e->data.map.values[i], env));
             }
             return map;
         }
         
         case EXPR_INDEX: {
             Value *list = eval_expr(e->data.index.list, env);
             Value *index = eval_expr(e->data.index.index, env);
             if (list->type == VAL_LIST && index->type == VAL_INT) {
                 return list->data.list.items[index->data.i];
             }
             if (list->type == VAL_STRING && index->type == VAL_INT) {
                 char buf[2] = {list->data.s[index->data.i], 0};
                 return val_string(buf);
             }
             fprintf(stderr, "💀 Index error\n");
             exit(1);
         }
         
         case EXPR_GET: {
             Value *obj = eval_expr(e->data.get.object, env);
             return map_get(obj, e->data.get.name);
         }
         
         case EXPR_INPUT: {
             char buf[1024];
             if (fgets(buf, sizeof(buf), stdin)) {
                 buf[strcspn(buf, "\n")] = 0;
                 return val_string(buf);
             }
             return val_string("");
         }
         
         case EXPR_READ: {
             Value *path = eval_expr(e->data.child, env);
             FILE *f = fopen(path->data.s, "r");
             if (!f) {
                 fprintf(stderr, "💀 Could not read file: %s\n", path->data.s);
                 exit(1);
             }
             fseek(f, 0, SEEK_END);
             long size = ftell(f);
             fseek(f, 0, SEEK_SET);
             char *content = malloc(size + 1);
             fread(content, 1, size, f);
             content[size] = 0;
             fclose(f);
             return val_string(content);
         }
         
         case EXPR_MEASURE: {
             Value *target = eval_expr(e->data.child, env);
             if (target->type == VAL_STRING) {
                 return val_int(strlen(target->data.s));
             }
             if (target->type == VAL_LIST) {
                 return val_int(target->data.list.count);
             }
             return val_int(0);
         }
         
         case EXPR_CALL: {
             // --- CORE SYSTEM CALLS ---
             if (strcmp(e->data.call.name, "inscribo") == 0) {
                 Value *path = eval_expr(e->data.call.args[0], env);
                 Value *content = eval_expr(e->data.call.args[1], env);
                 FILE *f = fopen(path->data.s, "w");
                 fprintf(f, "%s", content->data.s);
                 fclose(f);
                 return val_int(0);
             }
             
             if (strcmp(e->data.call.name, "sys") == 0) {
                 Value *cmd = eval_expr(e->data.call.args[0], env);
                 int ret = system(cmd->data.s);
                 return val_int(ret);
             }
 
             // --- NETWORKING PRIMITIVES (Latin names) ---
             // conexus = connect, mitto = send, recipio = receive, claudere = close
             
             if (strcmp(e->data.call.name, "conexus") == 0 || strcmp(e->data.call.name, "necto") == 0) {
                Value *host = eval_expr(e->data.call.args[0], env);
                Value *port = eval_expr(e->data.call.args[1], env);
                
                #ifdef _WIN32
                SOCKET sock = socket(AF_INET, SOCK_STREAM, 0);
                #else
                int sock = socket(AF_INET, SOCK_STREAM, 0);
                #endif
                
                struct sockaddr_in serv_addr;
                serv_addr.sin_family = AF_INET;
                serv_addr.sin_port = htons(port->data.i);
                
                // DNS Resolution Logic
                struct hostent *he;
                
                // Try to convert as IP address first
                #ifdef _WIN32
                    if ((serv_addr.sin_addr.s_addr = inet_addr(host->data.s)) == INADDR_NONE) {
                        // If not IP, resolve hostname
                        he = gethostbyname(host->data.s);
                        if (he == NULL) return val_int(-1);
                        memcpy(&serv_addr.sin_addr, he->h_addr_list[0], he->h_length);
                    }
                #else
                    if (inet_pton(AF_INET, host->data.s, &serv_addr.sin_addr) <= 0) {
                        // If not IP, resolve hostname
                        he = gethostbyname(host->data.s);
                        if (he == NULL) return val_int(-1);
                        memcpy(&serv_addr.sin_addr, he->h_addr_list[0], he->h_length);
                    }
                #endif

                if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
                    return val_int(-1); // Connection failed
                }
                return val_int((long)sock);
            }

            if (strcmp(e->data.call.name, "mitto") == 0) { // send(socket, data)
                Value *sock = eval_expr(e->data.call.args[0], env);
                Value *data = eval_expr(e->data.call.args[1], env);
                send((SOCKET)sock->data.i, data->data.s, strlen(data->data.s), 0);
                return val_int(0);
            }

            if (strcmp(e->data.call.name, "recipio") == 0) { // recv(socket, buf_size)
                Value *sock = eval_expr(e->data.call.args[0], env);
                Value *size = eval_expr(e->data.call.args[1], env);
                
                char *buf = malloc(size->data.i + 1);
                int len = recv((SOCKET)sock->data.i, buf, size->data.i, 0);
                if (len < 0) len = 0;
                buf[len] = 0;
                return val_string(buf);
            }

            if (strcmp(e->data.call.name, "claudere") == 0) { // close(socket)
                Value *sock = eval_expr(e->data.call.args[0], env);
                #ifdef _WIN32
                    closesocket((SOCKET)sock->data.i);
                #else
                    close((int)sock->data.i);
                #endif
                return val_int(0);
            }
 
             // --- GRAPHICS PRIMITIVES (THE NEON) [LATINIZED] ---
             // Only available if compiled with -DENABLE_GRAPHICS
             
             // fenestra(width, height, title) -> InitWindow
             if (strcmp(e->data.call.name, "fenestra") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     Value *w = eval_expr(e->data.call.args[0], env);
                     Value *h = eval_expr(e->data.call.args[1], env);
                     Value *title = eval_expr(e->data.call.args[2], env);
                     InitWindow(w->data.i, h->data.i, title->data.s);
                     SetTargetFPS(60);
                     return val_int(0);
                 #else
                     fprintf(stderr, "⚠️  Graphics disabled - rebuild with -DENABLE_GRAPHICS\n");
                     return val_int(-1);
                 #endif
             }
             
             // fenestra_claudenda() -> WindowShouldClose
             if (strcmp(e->data.call.name, "fenestra_claudenda") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     return val_int(WindowShouldClose());
                 #else
                     return val_int(1); // Always "should close" if no graphics
                 #endif
             }
             
             // incipere_picturam() -> BeginDrawing
             if (strcmp(e->data.call.name, "incipere_picturam") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     BeginDrawing();
                     return val_int(0);
                 #else
                     return val_int(0);
                 #endif
             }
             
             // finire_picturam() -> EndDrawing
             if (strcmp(e->data.call.name, "finire_picturam") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     EndDrawing();
                     return val_int(0);
                 #else
                     return val_int(0);
                 #endif
             }
             
             // purgare_fundum(color) -> ClearBackground
             if (strcmp(e->data.call.name, "purgare_fundum") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     Value *c = eval_expr(e->data.call.args[0], env);
                     ClearBackground(get_color(c->data.i));
                     return val_int(0);
                 #else
                     return val_int(0);
                 #endif
             }
             
             // delinere_textum(text, x, y, size, color) -> DrawText
             if (strcmp(e->data.call.name, "delinere_textum") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     Value *text = eval_expr(e->data.call.args[0], env);
                     Value *x = eval_expr(e->data.call.args[1], env);
                     Value *y = eval_expr(e->data.call.args[2], env);
                     Value *size = eval_expr(e->data.call.args[3], env);
                     Value *col = eval_expr(e->data.call.args[4], env);
                     DrawText(text->data.s, x->data.i, y->data.i, size->data.i, get_color(col->data.i));
                     return val_int(0);
                 #else
                     // Fallback: print to terminal if graphics unavailable
                     Value *text = eval_expr(e->data.call.args[0], env);
                     printf("%s\n", text->data.s);
                     return val_int(0);
                 #endif
             }
             
             // delinere_quadratum(x, y, w, h, color) -> DrawRectangle
             if (strcmp(e->data.call.name, "delinere_quadratum") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     Value *x = eval_expr(e->data.call.args[0], env);
                     Value *y = eval_expr(e->data.call.args[1], env);
                     Value *w = eval_expr(e->data.call.args[2], env);
                     Value *h = eval_expr(e->data.call.args[3], env);
                     Value *col = eval_expr(e->data.call.args[4], env);
                     DrawRectangle(x->data.i, y->data.i, w->data.i, h->data.i, get_color(col->data.i));
                     return val_int(0);
                 #else
                     return val_int(0);
                 #endif
             }
             
             // delinere_circulum(centerX, centerY, radius, color) -> DrawCircle
             if (strcmp(e->data.call.name, "delinere_circulum") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     Value *cx = eval_expr(e->data.call.args[0], env);
                     Value *cy = eval_expr(e->data.call.args[1], env);
                     Value *r = eval_expr(e->data.call.args[2], env);
                     Value *col = eval_expr(e->data.call.args[3], env);
                     DrawCircle(cx->data.i, cy->data.i, (float)r->data.i, get_color(col->data.i));
                     return val_int(0);
                 #else
                     return val_int(0);
                 #endif
             }
             
             // delinere_lineam(startX, startY, endX, endY, color) -> DrawLine
             if (strcmp(e->data.call.name, "delinere_lineam") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     Value *sx = eval_expr(e->data.call.args[0], env);
                     Value *sy = eval_expr(e->data.call.args[1], env);
                     Value *ex = eval_expr(e->data.call.args[2], env);
                     Value *ey = eval_expr(e->data.call.args[3], env);
                     Value *col = eval_expr(e->data.call.args[4], env);
                     DrawLine(sx->data.i, sy->data.i, ex->data.i, ey->data.i, get_color(col->data.i));
                     return val_int(0);
                 #else
                     return val_int(0);
                 #endif
             }
             
             // --- INPUT PRIMITIVES (Latin names with conditionals) ---
             
             // capere_signum() -> GetCharPressed
             if (strcmp(e->data.call.name, "capere_signum") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     return val_int(GetCharPressed());
                 #else
                     return val_int(0);
                 #endif
             }
             
             // clavis_pressa(key) -> IsKeyDown
             if (strcmp(e->data.call.name, "clavis_pressa") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     Value *k = eval_expr(e->data.call.args[0], env);
                     return val_int(IsKeyDown(k->data.i));
                 #else
                     return val_int(0);
                 #endif
             }
             
             // capere_clavem() -> GetKeyPressed
             if (strcmp(e->data.call.name, "capere_clavem") == 0) {
                 #ifdef ENABLE_GRAPHICS
                     return val_int(GetKeyPressed());
                 #else
                     return val_int(0);
                 #endif
             }
             
             // --- UTILITY (UNIVERSAL) ---
             
             // signum_ex(int) -> string (ASCII conversion)
             if (strcmp(e->data.call.name, "signum_ex") == 0) {
                 Value *code = eval_expr(e->data.call.args[0], env);
                 char b[2] = { (char)code->data.i, 0 };
                 return val_string(b);
             }
             // [NEW] codex(string) -> int (New: ord)
             // Converts first character of string to its ASCII integer
             if (strcmp(e->data.call.name, "codex") == 0) {
                Value *s = eval_expr(e->data.call.args[0], env);
                if (s->type != VAL_STRING) return val_int(0);
                return val_int((unsigned char)s->data.s[0]);
            }
             
             // char_at is an alias for signum_ex for backward compatibility if needed
             if (strcmp(e->data.call.name, "char_at") == 0) {
                 Value *code = eval_expr(e->data.call.args[0], env);
                 char b[2] = { (char)code->data.i, 0 };
                 return val_string(b);
             }
             // [NEW] Cast String to Number (int or float)
            // Usage: vas x : int -> numerus("123")
            if (strcmp(e->data.call.name, "numerus") == 0) {
                Value *v = eval_expr(e->data.call.args[0], env);
                if (v->type != VAL_STRING) return v; // Already a number?
                
                // Check if it contains a dot for float/dec
                if (strchr(v->data.s, '.')) return val_float(atof(v->data.s));
                return val_int(atol(v->data.s));
            }

 
             // --- USER FUNCTIONS ---
             // [FIX] Update Function Parameters to use env_def (Creation) not env_set (Update)
            Value *func_val = env_get(global_funcs, e->data.call.name);
            if (func_val->type != VAL_FUNC) { fprintf(stderr, "💀 Not a function: %s\n", e->data.call.name); exit(1); }
            Function *func = &func_val->data.func; Environment *local = env_new();
            for (int i = 0; i < func->param_count; i++) {
                // MUST BE env_def because we are creating local variables
                env_def(local, func->params[i], eval_expr(e->data.call.args[i], env));
            }
             
             for (int i = 0; i < func->param_count; i++) {
                 env_def(local, func->params[i], eval_expr(e->data.call.args[i], env));
             }
             
             // Recursion Safeguard
             Value *old_ret = return_value;
             return_value = NULL;
             run_stmts((Stmt**)func->body, func->body_count, local);
             Value *ret = return_value;
             return_value = old_ret;
 
             return ret ? ret : val_int(0);
         }
         
         case EXPR_BINARY: {
             Value *left = eval_expr(e->data.binary.left, env);
             Value *right = eval_expr(e->data.binary.right, env);
             char *op = e->data.binary.op;
             
             if (strcmp(op, "et") == 0) {
                // Short-circuit behavior for AND
                int l_truth = truthy(left);
                if (!l_truth) return val_int(0); // If left is false, result is false
                return val_int(truthy(right));
            }
            if (strcmp(op, "vel") == 0) {
                // Short-circuit behavior for OR
                int l_truth = truthy(left);
                if (l_truth) return val_int(1); // If left is true, result is true
                return val_int(truthy(right));
            }

             // [NEW] AUTOMATIC STRING CONCATENATION (The Fix)
            // Allows: "Age: " + 24   OR   24 + " years"
            if (!strcmp(op, "+") && (left->type == VAL_STRING || right->type == VAL_STRING)) {
                char *ls, *rs;
                char buf_l[64], buf_r[64];
                
                // Convert LEFT operand to string if needed
                if (left->type == VAL_STRING) ls = left->data.s;
                else if (left->type == VAL_INT) { sprintf(buf_l, "%ld", left->data.i); ls = buf_l; }
                else if (left->type == VAL_FLOAT) { sprintf(buf_l, "%g", left->data.f); ls = buf_l; }
                else { ls = "[obj]"; } // Fallback for lists/maps

                // Convert RIGHT operand to string if needed
                if (right->type == VAL_STRING) rs = right->data.s;
                else if (right->type == VAL_INT) { sprintf(buf_r, "%ld", right->data.i); rs = buf_r; }
                else if (right->type == VAL_FLOAT) { sprintf(buf_r, "%g", right->data.f); rs = buf_r; }
                else { rs = "[obj]"; }

                // Allocate and Join
                char *res = malloc(strlen(ls) + strlen(rs) + 1);
                sprintf(res, "%s%s", ls, rs);
                
                Value *ret = val_string(res);
                free(res); // val_string creates its own copy, so we free the temp
                return ret;
            }
             
             // LIST MERGE
             if (left->type == VAL_LIST && right->type == VAL_LIST && strcmp(op, "+") == 0) {
                 Value *new_list = val_list();
                 for (int i = 0; i < left->data.list.count; i++) list_append(new_list, left->data.list.items[i]);
                 for (int i = 0; i < right->data.list.count; i++) list_append(new_list, right->data.list.items[i]);
                 return new_list;
             }
 
             // INT MATH
             if (left->type == VAL_INT && right->type == VAL_INT) {
                 if (strcmp(op, "+") == 0) return val_int(left->data.i + right->data.i);
                 if (strcmp(op, "-") == 0) return val_int(left->data.i - right->data.i);
                 if (strcmp(op, "*") == 0) return val_int(left->data.i * right->data.i);
                 if (strcmp(op, "/") == 0) return val_int(left->data.i / right->data.i);
                 if (strcmp(op, "%") == 0) return val_int(left->data.i % right->data.i);
                 if (strcmp(op, "<") == 0) return val_int(left->data.i < right->data.i);
                 if (strcmp(op, ">") == 0) return val_int(left->data.i > right->data.i);
                 if (strcmp(op, "<=") == 0) return val_int(left->data.i <= right->data.i);
                 if (strcmp(op, ">=") == 0) return val_int(left->data.i >= right->data.i);
                 if (strcmp(op, "==") == 0) return val_int(left->data.i == right->data.i);
                 if (strcmp(op, "!=") == 0) return val_int(left->data.i != right->data.i);
                 if (strcmp(op, "&") == 0) return val_int(left->data.i & right->data.i);
                 if (strcmp(op, "|") == 0) return val_int(left->data.i | right->data.i);
                 if (strcmp(op, "^") == 0) return val_int(left->data.i ^ right->data.i);
                 if (strcmp(op, ">>") == 0) return val_int(left->data.i >> right->data.i);
                 // Smart Shift: '<<'
                 // If it's a number, it's Left Shift. If it's a list (handled above), it's Append.
                 if (strcmp(op, "<<") == 0) return val_int(left->data.i << right->data.i);
                 if (strcmp(op, "~") == 0) return val_int(~left->data.i);

             }
             
             // FLOAT MATH
             if (left->type == VAL_FLOAT && right->type == VAL_FLOAT) {
                 if (strcmp(op, "+") == 0) return val_float(left->data.f + right->data.f);
                 if (strcmp(op, "-") == 0) return val_float(left->data.f - right->data.f);
                 if (strcmp(op, "*") == 0) return val_float(left->data.f * right->data.f);
                 if (strcmp(op, "/") == 0) return val_float(left->data.f / right->data.f);
                 if (strcmp(op, "<") == 0) return val_int(left->data.f < right->data.f);
                 if (strcmp(op, ">") == 0) return val_int(left->data.f > right->data.f);
                 if (strcmp(op, "<=") == 0) return val_int(left->data.f <= right->data.f);
                 if (strcmp(op, ">=") == 0) return val_int(left->data.f >= right->data.f);
             }
             
             // STRING OPS
             if (left->type == VAL_STRING && right->type == VAL_STRING) {
                 if (strcmp(op, "+") == 0) {
                     char *result = malloc(strlen(left->data.s) + strlen(right->data.s) + 1);
                     strcpy(result, left->data.s);
                     strcat(result, right->data.s);
                     return val_string(result);
                 }
                 if (strcmp(op, "==") == 0) return val_int(strcmp(left->data.s, right->data.s) == 0);
                 if (strcmp(op, "!=") == 0) return val_int(strcmp(left->data.s, right->data.s) != 0);
                 if (strcmp(op, ">") == 0) return val_int(strcmp(left->data.s, right->data.s) > 0);
                 if (strcmp(op, "<") == 0) return val_int(strcmp(left->data.s, right->data.s) < 0);
                 if (strcmp(op, ">=") == 0) return val_int(strcmp(left->data.s, right->data.s) >= 0);
                 if (strcmp(op, "<=") == 0) return val_int(strcmp(left->data.s, right->data.s) <= 0);
             }
             
             fprintf(stderr, "💀 Type error in operation %s\n", op);
             exit(1);
         }
     }
     
     return val_int(0);
 }
 
 void run_stmts(Stmt **stmts, int count, Environment *env) {
     for (int i = 0; i < count; i++) {
         if (return_value) return;
         if (break_flag || continue_flag) return;
         
         Stmt *s = stmts[i];
         
         switch (s->type) {
            case STMT_LET: {
                Value *val = eval_expr(s->data.let.value, env);
                
                // --- STRICT TYPE ENFORCEMENT ---
                char *h = s->data.let.type_hint;
                int valid = 0;
                
                if (strcmp(h, "int") == 0 && val->type == VAL_INT) valid = 1;
                else if (strcmp(h, "dec") == 0 && val->type == VAL_FLOAT) valid = 1;
                else if (strcmp(h, "str") == 0 && val->type == VAL_STRING) valid = 1;
                else if (strcmp(h, "arr") == 0 && val->type == VAL_LIST) valid = 1;
                else if (strcmp(h, "obj") == 0 && val->type == VAL_MAP) valid = 1;
                else if (strcmp(h, "any") == 0) valid = 1; // 'any' type for flexibility if needed

                if (!valid) {
                    fprintf(stderr, "💀 TYPE ERROR: Variable '%s' declared as '%s' but assigned type %d\n", 
                            s->data.let.name, h, val->type);
                    exit(1);
                }
                // ------------------------
                
                // Use env_def because this is a NEW declaration
                env_def(env, s->data.let.name, val);
                break;
            }
             
             case STMT_ASSIGN: {
                 Value *val = eval_expr(s->data.assign.value, env);
                 env_def(env, s->data.assign.name, val);
                 break;
             }
             
             case STMT_SET: {
                 Value *val = eval_expr(s->data.set.value, env);
                 if (s->data.set.object->type == EXPR_VAR) {
                     Value *obj = env_get(env, s->data.set.object->data.s);
                     map_set(obj, s->data.set.name, val);
                 }
                 break;
             }
             
             case STMT_APPEND: {
                 Value *val = eval_expr(s->data.append.value, env);
                 Value *list = env_get(env, s->data.append.name);
                 
                 if (list->type == VAL_LIST && val->type == VAL_LIST) {
                      for(int k=0; k < val->data.list.count; k++) {
                          list_append(list, val->data.list.items[k]);
                      }
                 } else {
                      list_append(list, val);
                 }
                 break;
             }
             
             case STMT_PRINT: {
                 Value *val = eval_expr(s->data.expr, env);
                 print_value(val);
                 printf("\n");
                 break;
             }
             
             case STMT_IF: {
                 Value *cond = eval_expr(s->data.if_stmt.cond, env);
                 if (truthy(cond)) {
                     run_stmts(s->data.if_stmt.then_stmts, s->data.if_stmt.then_count, env);
                 } else if (s->data.if_stmt.else_stmts) {
                     run_stmts(s->data.if_stmt.else_stmts, s->data.if_stmt.else_count, env);
                 }
                 break;
             }
             
             case STMT_WHILE: {
                 while (truthy(eval_expr(s->data.while_stmt.cond, env))) {
                     run_stmts(s->data.while_stmt.body, s->data.while_stmt.body_count, env);
                     if (break_flag) {
                       break_flag = 0; // Reset flag and exit loop
                       break;
                      }
                     if (continue_flag) {
                       continue_flag = 0; // Reset flag and continue loop
                       continue;
                     }
                     if (return_value) return;
                 }
                 break;
             }
             
             case STMT_FUNC: {
                 Value *func = malloc(sizeof(Value));
                 func->type = VAL_FUNC;
                 func->data.func.name = s->data.func.name;
                 func->data.func.params = s->data.func.params;
                 func->data.func.param_count = s->data.func.param_count;
                 func->data.func.body = (void*)s->data.func.body;
                 func->data.func.body_count = s->data.func.body_count;
                 env_def(global_funcs, s->data.func.name, func);
                 break;
             }
            case STMT_CONST:
            case STMT_SHARED: {
                Value *val = eval_expr(s->data.let.value, env);
                // We define these DIRECTLY in the 'globals' environment
                env_def(globals, s->data.let.name, val);
                break;
            }
             
             case STMT_RETURN: {
                 return_value = eval_expr(s->data.expr, env);
                 return;
             }
             
             case STMT_BREAK: {
               break_flag = 1;
               return;
             }

             case STMT_CONTINUE: {
               continue_flag = 1;
               return;
             }

             case STMT_IMPORT: {
                 Value *path = eval_expr(s->data.expr, env);
                 FILE *f = fopen(path->data.s, "r");
                 if (!f) {
                     fprintf(stderr, "💀 Could not import: %s\n", path->data.s);
                     exit(1);
                 }
                 fseek(f, 0, SEEK_END);
                 long size = ftell(f);
                 fseek(f, 0, SEEK_SET);
                 char *src = malloc(size + 1);
                 fread(src, 1, size, f);
                 src[size] = 0;
                 fclose(f);
                 
                 Lexer lex;
                 lexer_init(&lex, src);
                 lexer_run(&lex);
                 
                 Parser p;
                 parser_init(&p, lex.tokens, lex.token_count);
                 int import_count;
                 Stmt **import_stmts = parse_program(&p, &import_count);
                 
                 run_stmts(import_stmts, import_count, env);
                 break;
             }
             
             case STMT_EXPR: {
                 eval_expr(s->data.expr, env);
                 break;
             }
         }
     }
 }
 
 // ============================================================================
 // [SECTION 9] ENTRY POINT (THE OUROBOROS)
 // ============================================================================
 
 #ifndef FROZEN
 const char *EMBEDDED_SCRIPT = NULL;
 #endif
 
 int main(int argc, char **argv) {
     #ifdef _WIN32
         WSADATA wsaData;
         if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
             fprintf(stderr, "WSAStartup failed.\n");
             return 1;
         }
     #endif
 
     // 1. Ouroboros Mode: If script is embedded inside the binary, run it.
     if (EMBEDDED_SCRIPT != NULL) {
         // printf("⚔️  Achlys [Standalone Mode] Active\n"); // Silent running
         global_funcs = env_new();
         
         Lexer lexer; 
         lexer_init(&lexer, EMBEDDED_SCRIPT); 
         lexer_run(&lexer);
         
         Parser parser; 
         parser_init(&parser, lexer.tokens, lexer.token_count);
         
         int stmt_count; 
         Stmt **stmts = parse_program(&parser, &stmt_count);
         
         Environment *env = env_new();
         run_stmts(stmts, stmt_count, env);
         
         #ifdef _WIN32
             WSACleanup();
         #endif
         return 0;
     }
 
     // 2. Interpreter Mode: Run file provided in args
     if (argc < 2) {
         fprintf(stderr, "Usage: achlys <file.nox>\n");
         return 1;
     }
     
     // Safety check for extension
     if (!strstr(argv[1], ".nox")) {
         fprintf(stderr, "💀 [ACHLYS ERROR]: Only the Void (.nox) is welcome here.\n");
         return 1;
     }
     
     FILE *f = fopen(argv[1], "r");
     if (!f) {
         fprintf(stderr, "💀 Error: Could not open %s\n", argv[1]);
         return 1;
     }
     
     fseek(f, 0, SEEK_END);
     long size = ftell(f);
     fseek(f, 0, SEEK_SET);
     char *source = malloc(size + 1);
     fread(source, 1, size, f);
     source[size] = 0;
     fclose(f);
     
     printf("⚔️  Achlys booting [%s]\n", argv[1]);
     
     global_funcs = env_new();
     globals = env_new();
     
     Lexer lexer;
     lexer_init(&lexer, source);
     lexer_run(&lexer);
     
     Parser parser;
     parser_init(&parser, lexer.tokens, lexer.token_count);
     
     int stmt_count;
     Stmt **stmts = parse_program(&parser, &stmt_count);
     
     Environment *env = env_new();
     run_stmts(stmts, stmt_count, env);
     
     #ifdef _WIN32
         WSACleanup();
     #endif
 
     return 0;
 }
