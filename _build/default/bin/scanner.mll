(* Ocamllex scanner for MicroC *)

{ open Parser }

let digit = ['0' - '9']
let digits = digit+
let stringlit = [^ '\"' '\n' '\r']*

rule token = parse
  [' ' '\r' '\t'] { token lexbuf } (* Whitespace *)
| '\n'        { NEWLINE }
| '#'         { comment lexbuf }        (* Comments *)
| '('         { LPAREN }
| ')'         { RPAREN }
| '['         { LBRACKET }
| ']'         { RBRACKET }
| ','         { COMMA }
| ':'         { COLON }
| "end"       { END }
| '+'         { PLUS }
| '-'         { MINUS }
| '*'         { TIMES }
| '/'         { DIVIDE }
| '%'         { MOD }
| "<<"        { SHIFTL }
| ">>"        { SHIFTR }
| '|'         { BITOR }
| '&'         { BITAND }
| '^'         { BITXOR }
| '='         { ASSIGN }
| "=="        { EQ }
| "!="        { NEQ }
| '<'         { LT }
| "<="        { LEQ }
| ">"         { GT }
| ">="        { GEQ }
| '.'         { DOT }
| "and"       { AND }
| "or"        { OR }
| "!"         { NOT }
| "if"        { IF }
| "else"      { ELSE }
| "for"       { FOR }
| "while"     { WHILE }
| "return"    { RETURN }
| "int"       { INT }
| "bool"      { BOOL }
| "float"     { FLOAT }
| "entity"    { ENTITY }
| "component" { COMPONENT }
| "system"    { SYSTEM }
| "function"  { FUNCTION }
| "query"     { QUERY }
| "spawn"     { SPAWN }
| "in"        { IN }
| "as"        { AS }
| "void"      { VOID }
| "true"      { BLIT(true)  }
| "false"     { BLIT(false) }
| digits as lxm { ILIT(int_of_string lxm) }
| digits '.'  digit* as lxm { FLIT(float_of_string lxm) }
| '\"' stringlit '\"' as str { SLIT(str) }
(*| '['         { list lexbuf }*)
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "\n" { token lexbuf }
| _    { comment lexbuf }

(*
and list = parse
  "]" {token lexbuf}
|  digits [',' ' '* digits]* "]" as elmts { LLit(elmts) }
| "[" {list lexbuf} *)