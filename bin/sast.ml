(* Semantically-checked Abstract Syntax Tree and functions for printing it *)

open Ast

type sexpr = typ * sx
and sx =
  SLiteral of lit
  | SId of string
  | SBinop of sexpr * binop * sexpr
  | SListExpr of sexpr list
  | SUnop of uop * sexpr
  | SAssign of string * sexpr
  | SCall of string * sexpr list
  | SCompMemberAssign of string * string * string * sexpr
  | SCompMember of string * string * string
  | SListItem of string * sexpr
  | SNoexpr

type sstmt =
    SBlock of sstmt list
  | SExpr of sexpr
  | SReturn of sexpr
  | SIf of sexpr * sstmt * sstmt
  | SFor of string * sexpr * sstmt
  | SWhile of sexpr * sstmt
  | SSpawn of string * (string * ((string * sexpr) list)) list

  type ssystem_decl = {
    ssname: string;
    sformals: bind list;
    sqlist: query list;
    slocals: bind list;
    sbody: sstmt list;
  }

  type sfunc_decl = {
    styp : typ;
    sfname : string;
    sformals : bind list;
    slocals : bind list;
    sbody : sstmt list;
  }

  type sprogram = {
    scomponents: comp_decl list;
    sentities: entity_decl list;
    ssystems: ssystem_decl list;
    sfunctions: sfunc_decl list;
  }

 
(* Pretty-printing functions *)
let rec string_of_sexpr (t, e) = 
  "(" ^ string_of_typ t ^ " : " ^ (match e with
    SLiteral(l) -> string_of_literal l
  | SListExpr(exprs) -> String.concat ", " (List.map (string_of_sexpr) exprs)
  | SId(s) -> s
  | SBinop(e1, o, e2) ->
      string_of_sexpr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_sexpr e2
  | SUnop(o, e) -> string_of_uop o ^ string_of_sexpr e
  | SAssign(v, e) -> v ^ " = " ^ string_of_sexpr e
  | SCall(f, el) -> f ^ "(" ^ String.concat ", " (List.map (string_of_sexpr) el) ^ ")"
  | SCompMemberAssign(s1, s2, s3, e) ->  s1 ^ "." ^ s2 ^ "." ^ s3 ^ "=" ^ string_of_sexpr e
  | SCompMember(ent, comp, member) -> ent ^ "." ^ comp ^ "." ^ member
  | SListItem(name, item) ->
      name ^ "[" ^ string_of_sexpr item ^ "]"
  | SNoexpr -> "") ^ ")"

let string_of_smember = function 
  (name, e) -> name ^ ": " ^ string_of_sexpr e

let string_of_scomponent = function 
  (name, ms) -> name ^ ":\n" ^ (String.concat "\n" (List.map string_of_smember ms))
                  ^ "end\n"

let rec string_of_sstmt = function
    SBlock(stmts) ->
      String.concat "\n" (List.map string_of_sstmt stmts) ^ "\n"
  | SExpr(expr) -> string_of_sexpr expr ^ "\n";
  | SReturn(expr) -> "return " ^ string_of_sexpr expr ^ "\n";
  | SIf(e, s, SBlock([])) -> "if " ^ string_of_sexpr e ^ ":\n" ^ string_of_sstmt s
      ^ "end\n"
  | SIf(e, s1, s2) ->  "if " ^ string_of_sexpr e ^ ":\n" ^
      string_of_sstmt s1 ^ "end\nelse:\n" ^ string_of_sstmt s2 ^ "end\n"
  | SFor(s, e2, body) ->
      "for " ^ s ^ " in " ^ string_of_sexpr e2 ^ ":\n" ^
      string_of_sstmt body ^ "end\n"
  | SWhile(e, s) -> "while " ^ string_of_sexpr e ^ ":\n" ^ string_of_sstmt s
      ^ "end\n"
  | SSpawn (s, cs) -> "spawn " ^ s ^ ":" ^ (String.concat "\n" (List.map string_of_scomponent cs)) ^ "end\n"
  
let string_of_sfdecl fdecl =
    "function " ^ string_of_typ fdecl.styp ^ " " ^ fdecl.sfname ^ "(" ^
    String.concat ", " (List.map string_of_fmlsdcl fdecl.sformals) ^
    "):\n" ^
    String.concat "" (List.map string_of_vdecl fdecl.slocals) ^
    String.concat "" (List.map string_of_sstmt fdecl.sbody) ^
    "end\n"

let string_of_ssdecl sdecl =
      "system " ^ sdecl.ssname ^ "(" ^ String.concat ", " (List.map string_of_fmlsdcl sdecl.sformals) ^ ")" ^ ":\n" ^
      String.concat "" (List.map string_of_query sdecl.sqlist) ^
      String.concat "" (List.map string_of_vdecl sdecl.slocals) ^
      String.concat "" (List.map string_of_sstmt sdecl.sbody) ^
      "end\n"

let string_of_sprogram prog =
    String.concat "\n" (List.map string_of_cdecl prog.scomponents) ^ "\n" ^
    String.concat "\n" (List.map string_of_edecl prog.sentities) ^ "\n" ^
    String.concat "\n" (List.map string_of_ssdecl prog.ssystems) ^ "\n" ^
    String.concat "\n" (List.map string_of_sfdecl prog.sfunctions)
