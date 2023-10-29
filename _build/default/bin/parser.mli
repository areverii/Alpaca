
(* The type of tokens. *)

type token = 
  | WHILE
  | VOID
  | TIMES
  | SYSTEM
  | STRING
  | SPAWN
  | SLIT of (string)
  | SHIFTR
  | SHIFTL
  | RPAREN
  | RETURN
  | RBRACKET
  | QUERY
  | PLUS
  | OR
  | NOT
  | NEWLINE
  | NEQ
  | MOD
  | MINUS
  | LT
  | LPAREN
  | LEQ
  | LBRACKET
  | INT
  | IN
  | ILIT of (int)
  | IF
  | ID of (string)
  | GT
  | GEQ
  | FUNCTION
  | FOR
  | FLOAT
  | FLIT of (float)
  | EQ
  | EOF
  | ENTITY
  | END
  | ELSE
  | DOT
  | DIVIDE
  | COMPONENT
  | COMMA
  | COLON
  | BOOL
  | BLIT of (bool)
  | BITXOR
  | BITOR
  | BITAND
  | ASSIGN
  | AS
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.program)
