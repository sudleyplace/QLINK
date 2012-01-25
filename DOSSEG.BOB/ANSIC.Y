
/*
==========================================================================

  ansic.y: PCYACC grammar description for ANSI C
  version 1.0
  by Xing Liu

  PCYACC (R) ABRAXAS SOFTWARE, ALL RIGHT RESERVED.

  Reference: The C Programming Language (Reference Manual)
             Second Edition
             By B.W. Kernighan and D.M. Retchie

===========================================================================
*/

%{

#include "protos.h"

extern void yyerror( char * );

%}

%union {
  int   i;
  float r;
  char *s;
}

/*----------------------- special symbols -------------------------------*/

%token DDD		/* three dots ... */

/*--------------------------- constants ---------------------------------*/

%token	CHARACTER_CONSTANT FLOAT_CONSTANT INTEGER_CONSTANT STRING

/*--------------------------- identifiers -------------------------------*/

%token	IDENTIFIER TYPENAME ENUMERATION_CONSTANT

/*--------------------------- key words ---------------------------------*/

%token	Auto		Break		Case		Char		Const
%token	Continue	Default		Do  	 	Double		Else
%token	Enum		Extern 		Float		For		Goto
%token	If		Int  	  	Long	 	Register	Return
%token	Short		Signed 		Sizeof	 	Static		Struct
%token	Switch		Typedef		Void 	  	Volatile	Union
%token	Unsigned	While

/*--------------------------- combined operators ------------------------*/

/* binary logicals and comparators */

%token	OROR	ANDAND	EQU	NEQ	LEQ	GEQ

/* shift operators */						

%token	SHL	SHR

/* unary increments */

%token	ADDADD	SUBSUB

/* pointer */

%token	PTR

/* assignments */

%token	ADDEQ	SUBEQ	MULEQ	DIVEQ	MODEQ
%token	SHLEQ	SHREQ	ANDEQ	XOREQ	IOREQ

/*--------------------------- operator precedence -----------------------*/

/* comma operator */

%left	','

/* assignment operators */

%right	ADDEQ	SUBEQ	MULEQ	DIVEQ	MODEQ
	SHLEQ	SHREQ	BANDEQ	BXOREQ	BOREQ

/* binary operators */

%right	'?'	':'
%left	OROR
%left	ANDAND
%left	BOR
%left	BEOR
%left	BAND
%left	EQU
%left	NEQ
%left	LEQ	GEQ
%left	SHL	SHR
%left	ADD	SUB
%left	MUL	DIV	MOD

/* unary operators */

%right	ADDADD	SUBSUB	'~'	'!'
	UNIADD	UNISUB	UNIMUL	UNIBAND
	Sizeof	'*'

/* special operators */

%left	'('	'['	'.'	PTR

/*--------------------------- start symbol ------------------------------*/

%start translation_unit

%%

translation_unit
  : external_declaration
  | translation_unit external_declaration
  ;

external_declaration
  : function_definition
  | declaration
  ;

function_definition
  : declaration_specifiers declarator declaration_list compound_statement
  | declaration_specifiers declarator                  compound_statement
  |                        declarator declaration_list compound_statement
  |                        declarator                  compound_statement
  ;

declaration
  : declaration_specifiers init_declarator_list ';'
  | declaration_specifiers                      ';'
  ;

declaration_list
  : declaration
  | declaration_list declaration
  ;

declaration_specifiers
  : declaration_specifier
  | declaration_specifiers declaration_specifier
  ;

declaration_specifier
  : storage_class_specifier
  | type_specifier
  | type_qualifier
  ;

storage_class_specifier
  : Auto
  | Extern
  | Register
  | Static
  | Typedef		/* need to insert type names into symbols table */
  ;

type_specifier
  : Char
  | Double
  | Float
  | Int
  | Long
  | Short
  | Signed
  | Unsigned
  | Void
  | TYPENAME
  | aggregate_specifier
  ;

type_qualifier
  : Const
  | Volatile
  ;

aggregate_specifier
  : aggregate_type IDENTIFIER '{' aggregate_member_list '}'
  | aggregate_type            '{' aggregate_member_list '}'
  | aggregate_type IDENTIFIER
  ;

aggregate_type
  : Enum
  | Struct
  | Union
  ;

aggregate_member_list
  : struct_declaration_list
  | enumerator_list
  ;

struct_declaration_list
  : struct_declaration
  | struct_declaration_list struct_declaration
  ;

init_declarator_list
  : init_declarator
  | init_declarator_list ',' init_declarator
  ;

init_declarator
  : declarator
  | declarator '=' initializer
  ;

struct_declaration
  : declaration_specifiers struct_declarator_list ';'
  ;

struct_declarator_list
  : struct_declarator
  | struct_declarator_list ',' struct_declarator
  ;

struct_declarator
  : declarator
  | declarator ':' constant_expression
  |            ':' constant_expression
  ;

enumerator_list
  : enumerator
  | enumerator_list ',' enumerator
  ;

enumerator		/* need to insert enumeration names into symbol table */
  : IDENTIFIER
  | IDENTIFIER '=' constant_expression
  ;

declarator
  : pointer direct_declarator
  |         direct_declarator
  ;

direct_declarator
  : IDENTIFIER
  | '(' declarator ')' 
  | direct_declarator '[' constant_expression ']'
  | direct_declarator '['                     ']'
  | direct_declarator '(' parameter_type_list ')'
  | direct_declarator '(' identifier_list     ')'
  | direct_declarator '('                     ')'
  ;

pointer
  : '*' type_qualifier_list
  | '*'
  | '*' type_qualifier_list pointer
  | '*'                     pointer
  ;

type_qualifier_list
  : type_qualifier
  | type_qualifier_list type_qualifier
  ;

parameter_type_list
  : parameter_list
  | parameter_list ',' DDD
  ;

parameter_list
  : parameter_declaration
  | parameter_list ',' parameter_declaration
  ;

parameter_declaration
  : declaration_specifiers declarator
  | declaration_specifiers abstract_declarator
  | declaration_specifiers
  ;

identifier_list
  : IDENTIFIER
  | identifier_list ',' IDENTIFIER
  ;

initializer
  : assignment_expression
  | '{' initializer_list '}'
  | '{' initializer_list ',' '}'
  ;

initializer_list
  : initializer
  | initializer_list ',' initializer
  ;

type_name
  : declaration_specifiers abstract_declarator
  | declaration_specifiers
  ;

abstract_declarator
  : pointer
  | pointer direct_abstract_declarator
  |         direct_abstract_declarator
  ;

direct_abstract_declarator
  : '(' abstract_declarator ')'
  | direct_abstract_declarator '[' constant_expression ']'
  | direct_abstract_declarator '['                     ']'
  |                            '[' constant_expression ']'
  |                            '['                     ']'
  | direct_abstract_declarator '(' parameter_type_list ')'
  | direct_abstract_declarator '('                     ')'
  |                            '(' parameter_type_list ')'
  |                            '('                     ')'
  ;

statement
  : labeled_statement
  | expression_statement
  | compound_statement
  | selection_statement
  | iteration_statement
  | jump_statement
  ;

labeled_statement
  : IDENTIFIER ':' statement
  | Case constant_expression ':' statement
  | Default ':' statement
  ;

expression_statement
  : expression ';'
  |            ';'
  ;

compound_statement
  : '{' declaration_list statement_list '}'
  | '{' declaration_list                '}'
  | '{'                  statement_list '}'
  | '{'                                 '}'
  ;

statement_list
  : statement
  | statement_list statement
  ;

selection_statement
  : If '(' expression ')' statement
  | If '(' expression ')' statement Else statement
  | Switch '(' expression ')' statement
  ;

iteration_statement
  : While '(' expression ')' statement
  | Do statement While '(' expression ')' ';'
  | For '(' expression ';' expression ';' expression ')' statement
  | For '(' expression ';' expression ';'            ')' statement
  | For '(' expression ';'            ';' expression ')' statement
  | For '(' expression ';'            ';'            ')' statement
  | For '('            ';' expression ';' expression ')' statement
  | For '('            ';' expression ';'            ')' statement
  | For '('            ';'            ';' expression ')' statement
  | For '('            ';'            ';'            ')' statement
  ;

jump_statement
  : Goto IDENTIFIER   ';'
  | Continue          ';'
  | Break             ';'
  | Return expression ';'
  | Return            ';'
  ;

expression
  : assignment_expression
  | expression ',' assignment_expression
  ;

assignment_expression
  : conditional_expression
  | unary_expression assignment_operator assignment_expression
  ;

assignment_operator
  : '='
  | MULEQ
  | DIVEQ
  | MODEQ
  | ADDEQ
  | SUBEQ
  | SHLEQ
  | SHREQ
  | ANDEQ
  | IOREQ
  | XOREQ
  ;

conditional_expression
  : logical_or_expression
  | logical_or_expression '?' expression ':' conditional_expression
  ;

constant_expression
  : conditional_expression
  ;

logical_or_expression
  : logical_and_expression
  | logical_or_expression OROR logical_and_expression
  ;

logical_and_expression
  : inclusive_or_expression
  | logical_and_expression ANDAND inclusive_or_expression
  ;

inclusive_or_expression
  : exclusive_or_expression
  | inclusive_or_expression '|' exclusive_or_expression
  ;

exclusive_or_expression
  : and_expression
  | exclusive_or_expression '^' and_expression
  ;

and_expression
  : equality_expression
  | and_expression '&' equality_expression
  ;

equality_expression
  : relational_expression
  | equality_expression EQU  relational_expression
  | equality_expression NEQ relational_expression
  ;

relational_expression
  : shift_expression
  | relational_expression '<' shift_expression
  | relational_expression '>' shift_expression
  | relational_expression LEQ shift_expression
  | relational_expression GEQ shift_expression
  ;
			     
shift_expression
  : additive_expression
  | shift_expression SHL additive_expression
  | shift_expression SHR additive_expression
  ;

additive_expression
  : multiplicative_expression
  | additive_expression '+' multiplicative_expression
  | additive_expression '-' multiplicative_expression
  ; 

multiplicative_expression
  : cast_expression
  | multiplicative_expression '*' cast_expression
  | multiplicative_expression '/' cast_expression
  | multiplicative_expression '%' cast_expression
  ; 

cast_expression
  : unary_expression
  | '(' type_name ')' cast_expression
  ;

unary_expression
  : postfix_expression
  | ADDADD unary_expression
  | SUBSUB unary_expression
  | unary_operator cast_expression
  | Sizeof unary_expression
  | Sizeof '(' type_name ')'
  ;

unary_operator
  : '&'
  | '*'
  | '+'
  | '-'
  | '~'
  | '!'
  ;

postfix_expression
  : primary_expression
  | postfix_expression '[' expression ']'
  | postfix_expression '(' argument_expression_list ')'
  | postfix_expression '('                          ')'
  | postfix_expression '.' IDENTIFIER
  | postfix_expression PTR IDENTIFIER
  | postfix_expression ADDADD
  | postfix_expression SUBSUB
  ;

primary_expression
  : IDENTIFIER
  | constant
  | STRING
  | '(' expression ')'
  ;

argument_expression_list
  : assignment_expression
  | argument_expression_list ',' assignment_expression
  ;

constant
  : INTEGER_CONSTANT
  | CHARACTER_CONSTANT
  | FLOAT_CONSTANT
  | ENUMERATION_CONSTANT
  ;


