%{
#include <iostream>
#include <vector>
#include <list>

#include "Statement.h"
#include "Assignment.h"
#include "PrintStatement.h"
#include "ReturnStatement.h"
#include "SymbolTable.h"
#include "Value.h"
#include "AST.h"

extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();
void yyerror(const char * s);

using namespace std;

%}

%union {
     char*       string;
     int         integer;
     float       real;
     bool        boolean;
     Value*      value;
     AST*        node;
     list<AST*>* astList;
     list<Statement*>* stmtList;
     Statement*        stmt;
     list<Parameter*>* paramList;
     Parameter*        param;
}

%start progr
%token VARIABLE_DEF CONST OBJECT_DEF FUNCTION_DEF FOR IF ELSE THEN WHILE PRINT RETURN TYPE_OF EVAL BGIN
%token ASSIGN PLUS MINUS MULT DIV EQUAL LESS GREATER LESSEQUAL GREATEREQUAL NOTEQUAL
%token ':' ';' ',' DOT DOT2 CALL
%token '(' ')' '{' '}' '[' ']'
%token<string>    ID TYPE
%token<real>      FLOAT_LITERAL
%token<integer>   INT_LITERAL 
%token<string>    STRING_LITERAL CHAR_LITERAL
%token<boolean>   TRUE FALSE 

%nonassoc THEN
%nonassoc ELSE
%left DOT PLUS MINUS MULT DIV '(' ')'

// non-terminal symbols 
%type <node>      literal factor term expr extended_expr function_call
%type <astList>   argument_list
%type <stmtList>  code_block statements
%type <stmt>      statement print assignment if_statement for_statement while_statement 
%type <stmt>      return_statement function_stmt eval type_of
%type <param>     parameter
%type <paramList> parameters

%%

progr: decl main {printf("The program is correct!\n");}
     ;

decl : user_data_types global_variables function_definitions 
     ;

parameter :  TYPE ID { $$ = new Parameter(yylineno, $2, $1); }
          ;

parameters : parameter                  { $$ = new list<Parameter*>(); $$->push_back($1); }
           | parameters ',' parameter { $1-> push_back($3); $$ = $1; }
           |                            { $$ = new list<Parameter*>(); }
           ;

main : BGIN code_block {SymbolTable::getInstance()->addFunction("void", "ctrl(main)", new list<Parameter*>(), $2, yylineno);}
     ;

members : class_variables function_definitions
        ;

class_variable : TYPE ID ';'
                         { 
                              cout << $1 << " " << $2 << endl;
                         
                         SymbolTable::getInstance()->addVariable($1, $2, "class", yylineno);
                         }    
                | TYPE ID '[' INT_LITERAL ']' ';'
                         { cout << "Define array variable " << $2 << " of type " << $4 << endl;}
                | CONST ID ASSIGN TYPE '(' literal ')' ';'
                         {
                              Variable* v = SymbolTable::getInstance()->addVariable($4, $2, "class", yylineno);
                              v->setValue($6->getValue());
                              v->setConstant(); 
                         } 
                ;

class_variables : class_variables class_variable
               |
                ;

user_data_types : user_data_type user_data_types 
                |
                ;

user_data_type : OBJECT_DEF ID '{' members '}' {
     SymbolTable::getInstance()->addObject($2, yylineno);
}
               ;

literal   : FLOAT_LITERAL  { $$ = new AST(yylineno, new FloatValue($1)); }
          | INT_LITERAL    { $$ = new AST(yylineno, new IntValue($1)); }
          | STRING_LITERAL { $$ = new AST(yylineno, new StringValue($1)); }
          | CHAR_LITERAL   { $$ = new AST(yylineno, new CharValue($1[0])); }
          | TRUE           { $$ = new AST(yylineno, new BoolValue($1)); }
          | FALSE          { $$ = new AST(yylineno, new BoolValue($1)); }
          ;

global_variable : TYPE ID ';'
                         { 
                              cout << $1 << " " << $2 << endl;
                         
                         SymbolTable::getInstance()->addVariable($1, $2, "global", yylineno);
                         }
                | TYPE ID '[' INT_LITERAL ']' ';'
                         { cout << "Define array variable " << $2 << " of type " << $4 << endl;}
                | CONST ID ASSIGN TYPE '(' literal ')' ';'
                         {
                              Variable* v = SymbolTable::getInstance()->addVariable($4, $2, "global", yylineno);
                              v->setValue($6->getValue());
                              v->setConstant(); 
                         }
                ;

global_variables : global_variables global_variable
                 |
                 ;

factor: literal
     | ID '[' extended_expr ']'    // access array element
               {  $$ = new AST(yylineno, $1, $3); }
     | ID DOT ID '(' argument_list ')' // accessing object method
               {
                    //printf("%d: Accessing object method {%s.%s(AST, AST ...)}.\n", yylineno, $1, $3);
                    $$ = new AST(yylineno, $1, $3, $5);
               }
     | ID DOT ID '[' extended_expr ']'     // access array element member of an objet
               { printf("%d: Accessing object array field {%s.%s[AST]}.\n", yylineno, $1, $3); }
     | ID DOT ID                                       
               { 
                    //printf("%d Accessing object filed {%s.%s}.\n", yylineno, $1, $3);
                    $$ = new AST(yylineno, $1, $3);
               }
     | ID      {  $$ = new AST(yylineno, $1); } // accesing simple variable/parameter
     | function_call
     | '(' extended_expr ')'
               { $$ = $2; }
     ;

term : factor 
     | factor MULT factor { $$ = new AST(yylineno, $1, $3, '*');}
     | factor DIV factor  { $$ = new AST(yylineno, $1, $3, '/');}
     ;

expr : term 
     | term PLUS term     { $$ = new AST(yylineno, $1, $3, '+');}
     | term MINUS term    { $$ = new AST(yylineno, $1, $3, '-');}
     ; 

extended_expr : expr 
              | expr EQUAL expr          { $$ = new AST(yylineno, $1, $3, '='); }
              | expr LESS expr           { $$ = new AST(yylineno, $1, $3, '<'); }
              | expr GREATER expr        { $$ = new AST(yylineno, $1, $3, '>'); }
              | expr LESSEQUAL expr      { $$ = new AST(yylineno, $1, $3, AST_LEQ); }
              | expr GREATEREQUAL expr   { $$ = new AST(yylineno, $1, $3, AST_GEQ); }
              | expr NOTEQUAL expr       { $$ = new AST(yylineno, $1, $3, AST_NOT_EQ); }
              ;

assignment : ID ASSIGN extended_expr
               { 
                    // cout << yylineno << " ASSIGN " << $1 << " <- " << "$3" << endl;
                    $$ = new Assignment(yylineno, $1, $3);
               }
           ;

if_statement : IF '(' extended_expr ')' THEN statement
                    {
                         //cout << yylineno << ": IF <expr> THEN <stmt>"  << endl; 
                         $$ = new IfStatement(yylineno, $3, $6, nullptr);
                    }
             | IF '(' extended_expr ')' THEN statement ELSE statement
                    {    
                         //cout << yylineno << ": IF <expr> THEN <stmt> ELSE <stmt>"  << endl; 
                         $$ = new IfStatement(yylineno, $3, $6, $8);
                    }
             ;

for_statement : FOR '(' global_variable ';' extended_expr ';' extended_expr ')' statement
                    { $$ = new EmptyStatement(yylineno); }
              ;

while_statement : WHILE '(' extended_expr ')' statement
                    { $$ = new WhileStatement(yylineno, $3, $5); }
                ;

argument_list : extended_expr                      { $$ = new list<AST*>; $$->push_front($1); }
              | extended_expr ',' argument_list  { $3->push_front($1); $$ = $3; }
              |                                    { $$ = new list<AST*>;}
              ;

function_stmt : CALL ID '(' argument_list ')'
               {
                    // printf("%d: Invoking function {%s(AST, AST ...)} as statement.\n", yylineno, $2);
                    //$$ = new AST(yylineno, $1, $3);
                    { $$ = new EmptyStatement(yylineno); }
               }
              ;
function_call : ID '(' argument_list ')'
               {
                    // printf("%d: Invoking function {%s(AST, AST ...)} as expression.\n", yylineno, $1);
                    $$ = new AST(yylineno, $1, $3);
               }
              ;

print : PRINT '(' argument_list ')'
          { $$ = new PrintStatement(yylineno, $3); }
      ;

eval : EVAL '(' extended_expr ')' { $$ = new Eval(yylineno, $3); }
     ;    
type_of : TYPE_OF '(' extended_expr ')'
     { $$ = new TypeOf(yylineno, $3); }


return_statement: RETURN extended_expr { $$ = new ReturnStatement(yylineno, $2); }
                | RETURN               { $$ = new ReturnStatement(yylineno, nullptr); }
                ;

statement : assignment ';'
          | if_statement
          | for_statement
          | while_statement
          | print ';'
          | return_statement ';'
          | function_stmt ';'
          | eval ';'
          | type_of ';'
          | '{' statements '}' { $$ = new ComposedStatement(yylineno, $2); }
          | ';'                           { $$ = new EmptyStatement(yylineno); }
          ;

statements : statements statement  { $1->push_back($2); $$ = $1; }
           | { $$ = new list<Statement*>(); }
           ;

code_block : '{' function_variables statements '}' { $$ = $3; }
           ;

function_variable : TYPE ID ';'
                         { 
                              cout << $1 << " " << $2 << endl;
                         
                         SymbolTable::getInstance()->addVariable($1, $2, "function", yylineno);
                         }    
                | TYPE ID '[' INT_LITERAL ']' ';'
                         { cout << "Define array variable " << $2 << " of type " << $4 << endl;}
                | CONST ID ASSIGN TYPE '(' literal ')' ';'
                         {
                              Variable* v = SymbolTable::getInstance()->addVariable($4, $2, "function", yylineno);
                              v->setValue($6->getValue());
                              v->setConstant(); 
                         } 
                ;

function_variables : function_variables function_variable
               |
                ;

function_definition : FUNCTION_DEF TYPE ID '(' parameters ')' code_block
     {
          //cout << "Added function " << $2 <<" "<< $3 << " " << $5 << " " << $7 <<endl; 
          SymbolTable::getInstance()->addFunction($2, $3, $5, $7, yylineno); 
     }
                    ; 

function_definitions : function_definitions function_definition
                     |
                     ;
%%

void yyerror(const char * s)
{
     cout << "error: " <<  s << " at line:" << yylineno << endl;
}

int main(int argc, char** argv)
{
     yyin=fopen(argv[1],"r");
     yyparse();
     SymbolTable::getInstance()->printVars();  

     Function* mainF = SymbolTable::getInstance()->getFunction("ctrl(main)");
     if (mainF == nullptr)
     {
          cout << "main() function not found!" << endl;
          return -1;
     }

     mainF->execute(new list<AST*>());  
} 
