
(* The type of tokens. *)

type token = 
  | WHILE
  | VOID
  | TIMES
  | SEMI
  | RPAREN
  | RETURN
  | RBRACE
  | PLUS
  | OR
  | NOT
  | NEQ
  | MINUS
  | LT
  | LPAREN
  | LITERAL of (int)
  | LEQ
  | LBRACE
  | INT
  | IF
  | ID of (string)
  | GT
  | GEQ
  | FOR
  | FLOAT
  | FLIT of (string)
  | EQ
  | EOF
  | ELSE
  | DIVIDE
  | COMMA
  | BOOL
  | BLIT of (bool)
  | ASSIGN
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.program)
