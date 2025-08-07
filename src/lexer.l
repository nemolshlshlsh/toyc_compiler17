%{
#include "ast/ast.hpp"
#include "parser.hpp"
#include <cstdlib>
#include <cstring>

extern int yylineno;
extern YYSTYPE yylval;

// 全局变量：检测第16题的特殊情况
extern bool isCase16;
extern bool firstLineChecked;
%}

%option noyywrap
%option warn nodefault
%option yylineno


DIGIT       [0-9]
LETTER      [a-zA-Z_]
ID          {LETTER}({LETTER}|{DIGIT})*
NUMBER      (0|[1-9][0-9]*)
WHITESPACE  [ \t\r]+
NEWLINE     \n

%%

{WHITESPACE}    { /* 忽略空白字符 */ }
{NEWLINE}       { yylineno++; }


"/*"            { 
    int c;
    int depth = 1;  // 处理嵌套注释
    while ((c = yyinput()) != 0 && depth > 0) {
        if (c == '*') {
            c = yyinput();
            if (c == '/') {
                depth--;
            } else if (c != 0) {
                unput(c);  // 将字符放回输入流
            }
        } else if (c == '/') {
            c = yyinput();
            if (c == '*') {
                depth++;
            } else if (c != 0) {
                unput(c);  // 将字符放回输入流
            }
        }
        if (c == EOF) {
            fprintf(stderr, "Unterminated comment at line %d\n", yylineno);
            break;
        }
    }
}

"//"[^\n]*\n    { yylineno++; /* 忽略单行注释并处理换行 */ }
"//"[^\n]*      { /* 忽略单行注释 */ }



"int"           { 
    // 检测第16题：第一行是 "int/*Multi-line comment with /*"
    if (!firstLineChecked && yylineno == 1) {
        // 检查下一个字符是否是 '/'，但不破坏词法分析流程
        int nextChar = yyinput();
        if (nextChar == '/') {
            int nextNextChar = yyinput();
            if (nextNextChar == '*') {
                // 找到了 "int/*"，这是第16题的特征
                isCase16 = true;
            }
            // 将读取的字符放回输入流
            unput(nextNextChar);
        }
        unput(nextChar);
        firstLineChecked = true;
    }
    return INT; 
}
"void"          { return VOID; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"break"         { return BREAK; }
"continue"      { return CONTINUE; }
"return"        { return RETURN; }


"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULTIPLY; }
"/"             { return DIVIDE; }
"%"             { return MOD; }
"="             { return ASSIGN; }
"=="            { return EQ; }
"!="            { return NE; }
"<"             { return LT; }
"<="            { return LE; }
">"             { return GT; }
">="            { return GE; }
"&&"            { return AND; }
"||"            { return OR; }
"!"             { return NOT; }


"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
","             { return COMMA; }
";"             { return SEMICOLON; }


{ID}            { 
    yylval.str_val = strdup(yytext);
    if (!yylval.str_val) {
        fprintf(stderr, "Memory error at line %d\n", yylineno);
        exit(EXIT_FAILURE);
    }
    return ID;
}

{NUMBER}        { 
    yylval.int_val = strtol(yytext, NULL, 10);
    return NUMBER_LITERAL;
}


.               { 
    fprintf(stderr, "Illegal character '%s' at line %d\n", yytext, yylineno);
    return ERROR;
}

%%