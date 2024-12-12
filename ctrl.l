%{
#include <stdio.h>
#include "ctrl.tab.h"
%}
%option noyywrap
%%
"int"|"float"|"char"|"string"|"bool" {yylval.string = strdup(yytext);return TYPE;}
"ctrl()" {return BGIN;}
"while" { return WHILE; }
"endfor" { return ENDFOR; }
"endif" { return ENDIF; }
"true" { return TRUE; }
"false" { return FALSE; }
"endwhile" { return ENDWHILE; }
"if" { return IF; }
"else" { return ELSE; }
"then" { return THEN; }
"for" { return FOR; }
"class" { return CLASS; }
"new" { return NEW; }
"function"   { return FUNCTION; }
"return" { return RETURN; }
"print" { return PRINT; }
"typeof" { return TYPEOF; }
"public"|"private" {yylval.string = strdup(yytext);return PRIVACY;}
[a-zA-Z][a-zA-Z0-9_]* {yylval.string = strdup(yytext); return VAR;}  
":=" {return ASSIGN;}
"==" {return EQ;}
"!=" {return NE;}
"<=" {return LEQ;}
">=" {return GEQ;}
[1-9][0-9]*|[0-9] {return NR;}
[0-9]+\.[0-9]+ { return FLOAT;}
[ \t] ;
\n {yylineno++;}
. {return yytext[0];}

 
