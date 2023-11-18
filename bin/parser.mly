/* Ocamlyacc parser for Alpaca */

%{
open Ast
%}

%token LPAREN RPAREN LBRACKET RBRACKET COMMA COLON ASSIGN NEWLINE END
%token PLUS MINUS TIMES DIVIDE MOD NOT EQ NEQ LT LEQ GT GEQ DOT AND OR SHIFTL SHIFTR BITOR BITAND BITXOR
%token INT BOOL FLOAT VOID STRING RETURN IF ELSE FOR WHILE SYSTEM FUNCTION ENTITY COMPONENT QUERY IN AS SPAWN
%token <int64> ILIT
%token <bool> BLIT
%token <string> ID SLIT 
%token <float> FLIT
%token EOF

%start program
%type <Ast.program> program 

%right ASSIGN
%left OR 
%left AND
%left BITOR
%left BITXOR
%left BITAND
%left EQ NEQ
%left LT GT LEQ GEQ
%left SHIFTL SHIFTR
%left PLUS MINUS
%left TIMES DIVIDE MOD
%right NOT

%%
program:
  cdecl_list edecl_list sfdecl_list EOF {{
    components = List.rev $1;
    entities = List.rev $2;
    functions =  List.rev $3;
    }}
 
fdecl:
   FUNCTION typ ID LPAREN formals_opt RPAREN COLON NEWLINE vdecl_list stmt_list END NEWLINE
     { {
   typ = $2;
	 name = $3;
	 formals = List.rev $5;
	 locals = List.rev $9;
	 body = List.rev $10;
   qlist = [] } }


sfdecl:
     fdecl {$1}
  |  sdecl {$1}

sfdecl_list:
   /* Nothing */ {[]}
  | sfdecl_list sfdecl {$2 :: $1}

cdecl:
   COMPONENT ID COLON NEWLINE vdecl_list END NEWLINE
   { {
   cname = $2;
	 members = List.rev $5;
   } }

cdecl_list:
  /*Nothing */ {[]}
  | cdecl_list cdecl {$2 :: $1}

edecl:
   ENTITY ID COLON NEWLINE comp_list END NEWLINE
   { {
   ename = $2;
	 components = List.rev $5;
   } }

edecl_list:
  /*Nothing */ {[]}
  | edecl_list edecl {$2 :: $1}

sdecl:
   SYSTEM ID LPAREN formals_opt RPAREN COLON NEWLINE query_list vdecl_list stmt_list END NEWLINE
   { {
   name = $2;
	 formals = List.rev $4;
	 qlist = List.rev $8;
   locals = List.rev $9;
   body = List.rev $10;
   typ = Void;
   } }

query: 
  QUERY LT ID GT LBRACKET query_comp_list RBRACKET AS ID NEWLINE
  { {
  tname = $3;
  lname = $9;
  components = List.rev $6;
  } }

query_list: 
    query            { [$1]     }
  | query_list query { $2 :: $1 } 

comp_list:
    ID NEWLINE           { [$1]     }
  | comp_list ID NEWLINE { $2 :: $1 }

query_comp_list:
    ID                        { [$1]     }
  | query_comp_list COMMA ID  { $3 :: $1 }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

formal_list:
    typ ID                   { [($1, $2)]     }
  | formal_list COMMA typ ID { ($3, $4) :: $1 }

typ:
    INT    { Int   }
  | BOOL   { Bool  }
  | FLOAT  { Float }
  | VOID   { Void }
  | STRING { String }
  | ENTITY LT ID GT { Entity($3) }
  | LT typ GT { List($2) }

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
   typ ID NEWLINE { ($1, $2) }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

stmt_block:
    stmt_list { Block(List.rev $1) }

stmt:
  | expr NEWLINE                            { Expr $1                }
  | RETURN expr_opt NEWLINE                 { Return $2              }
  | IF expr COLON NEWLINE stmt_block END NEWLINE 
                                            { If($2, $5, Block([]))  }
  | IF expr COLON NEWLINE stmt_block END NEWLINE ELSE COLON NEWLINE stmt_block END NEWLINE
                                            { If($2, $5, $11)        }
  | FOR ID IN expr COLON NEWLINE stmt_block END NEWLINE
                                            { For($2, $4, $7)        }
  | WHILE expr COLON NEWLINE stmt_block END NEWLINE          
                                            { While($2, $5)          }
  | SPAWN ID COLON NEWLINE comp_inst_list END NEWLINE { Spawn($2, List.rev $5)}       

comp_inst_list:
    ID COLON NEWLINE mem_inst_list END NEWLINE { [($1, List.rev $4)] } (*tuple of comp name, member dict *)
  | comp_inst_list ID COLON NEWLINE mem_inst_list END NEWLINE { ($2, List.rev $5) :: $1  }   

mem_inst_list: 
  ID COLON expr NEWLINE {[($1, $3)]} 
  | mem_inst_list ID COLON expr NEWLINE {($2, $4) :: $1}                      
                             
expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
    ILIT             { Literal(ILit($1))   }
  | FLIT	           { Literal(FLit($1))   }
  | BLIT             { Literal(BLit($1))   }
  | SLIT             { Literal(SLit($1))   }
  | LBRACKET expr_list RBRACKET { ListExpr(List.rev $2) }
  | ID               { Id($1)                 }
  | expr PLUS   expr { Binop($1, Add,   $3)   }
  | expr MINUS  expr { Binop($1, Sub,   $3)   }
  | expr TIMES  expr { Binop($1, Mult,  $3)   }
  | expr DIVIDE expr { Binop($1, Div,   $3)   }
  | expr MOD expr    { Binop($1, Mod,   $3)   }
  | expr BITXOR expr { Binop($1, BitXor,   $3)   }
  | expr EQ     expr { Binop($1, Eq, $3)      }
  | expr NEQ    expr { Binop($1, Neq,   $3)   }
  | expr LT     expr { Binop($1, Less,  $3)   }
  | expr LEQ    expr { Binop($1, Leq,   $3)   }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3)   }
  | expr AND    expr { Binop($1, And,   $3)   }
  | expr OR     expr { Binop($1, Or,    $3)   }
  | expr SHIFTL expr { Binop($1, ShiftL,   $3)   }
  | expr SHIFTR expr { Binop($1, ShiftR,   $3)   }
  | expr BITOR   expr { Binop($1, BitOr,   $3)   }
  | expr BITAND    expr { Binop($1, BitAnd,   $3)   }
  | MINUS expr %prec NOT { Unop(Neg, $2)      }
  | NOT expr         { Unop(Not, $2)          }
  | ID ASSIGN expr   { Assign($1, $3)         }
  | ID DOT ID DOT ID ASSIGN expr {CompMemberAssign($1, $3, $5, $7)}
  | ID DOT ID DOT ID { CompMember($1, $3, $5) }
  | ID LBRACKET expr RBRACKET { ListItem($1, $3) }
  | ID LPAREN args_opt RPAREN { Call($1, $3)  }
  | LPAREN expr RPAREN { $2                   }

args_opt:
    /* nothing */ { [] }
  | expr_list  { List.rev $1 }

expr_list:
    expr                    { [$1] }
  | expr_list COMMA expr { $3 :: $1 }

(* Decisions made:
Tabs are a stylic choice -- no meaning *)
(* Newlines matter!! *)
