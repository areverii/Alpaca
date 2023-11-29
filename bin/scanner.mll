(* Ocamllex scanner for Alpaca *)

{ open Parser }

let digit = ['0' - '9']
let digits = digit+
let escape_sequence = ['\\']['n' 'r' 't' '\\' '\"' 'b' 'f']
let stringlit = ([^ '\\' '\"' '\n' '\r'] | escape_sequence)*

rule token = parse
  [' ' '\r' '\t'] { token lexbuf } (* Whitespace *)
| '\n' ['\n' ' ' '\t' '\r']*       { NEWLINE }
| '#'         { comment lexbuf }   (* Comments *)
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
| "not"       { NOT }
| "if"        { IF }
| "else"      { ELSE }
| "for"       { FOR }
| "while"     { WHILE }
| "return"    { RETURN }
| "int"       { INT }
| "bool"      { BOOL }
| "string"    { STRING }
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
| digits as lxm { ILIT(Int64.of_string lxm) }
| digits '.'  digit* as lxm { FLIT(float_of_string lxm) }
| '\"' (stringlit as str) '\"' { SLIT(Scanf.unescaped str) }
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }


and comment = parse
  "\n" { token lexbuf }
| _    { comment lexbuf }
