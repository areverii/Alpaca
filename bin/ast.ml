(* Abstract Syntax Tree and functions for printing it *)

type binop = Add | Sub | Mult | Div | Mod | ShiftR | ShiftL |
              BitOr | BitAnd | BitXor | Eq | Neq | Less | Greater | Leq | Geq |
              And | Or

type uop = Neg | Not

type typ = Int | Bool | Float | String | Entity of string | Void | List of typ

type bind = typ * string

type lit = 
    ILit of int64
  | SLit of string
  | FLit of float
  | BLit of bool
  
type expr =
    Binop of expr * binop * expr
  | Literal of lit 
  | ListExpr of expr list
  | Unop of uop * expr
  | Assign of string * expr
  | CompMemberAssign of string * string * string * expr
  | CompMember of string * string * string
  | ListItem of string * expr
  | Call of string * expr list
  | Id of string
  | Noexpr

type stmt =
    Block of stmt list
  | Expr of expr
  | Return of expr
  | If of expr * stmt * stmt 
  | For of string * expr * stmt
  | While of expr * stmt 
  | Spawn of string * (string * ((string * expr) list)) list

  type comp_decl = {
    cname: string;
    members: bind list;
    }
    
  type entity_decl = {
    ename: string;
    components: string list;
  }
      
  type query = {
    tname: string;
    components: string list;
    lname: string;
  }
        
  type func_decl = { 
    typ: typ;
    name: string;
    formals: bind list;
    qlist: query list;
    locals: bind list;
    body: stmt list;
  }
(* type system_decl = { 
  sname: string;
  formals: bind list;
  qlist: query list;
  locals: bind list;
  body: stmt list;
} *)

type program = {
  components: comp_decl list;
  entities: entity_decl list;
  functions: func_decl list;
}


let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Mod -> "%"
  | ShiftR -> ">>"
  | ShiftL -> "<<"
  | BitOr -> "|"
  | BitAnd -> "&"
  | BitXor -> "^"
  | Eq -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "and"
  | Or -> "or"

let string_of_uop = function
    Neg -> "-"
  | Not -> "not "

let string_of_literal = function
    ILit(l) -> Int64.to_string l
  | FLit(l) -> string_of_float l
  | BLit(l) -> string_of_bool l
  | SLit(l) -> "\"" ^ l ^ "\""

let rec string_of_expr = function
    Literal(l) -> string_of_literal l
  | ListExpr(exprs) -> "[" ^ String.concat ", " (List.map (string_of_expr) exprs) ^ "]"
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Call(f, el) -> f ^ "(" ^ String.concat ", " (List.map (string_of_expr) el) ^ ")"
  | CompMemberAssign(s1, s2, s3, e) ->  s1 ^ "." ^ s2 ^ "." ^ s3 ^ "=" ^ string_of_expr e
  | CompMember(ent, comp, member) -> ent ^ "." ^ comp ^ "." ^ member
  | ListItem(name, item) ->
      name ^ "[" ^ string_of_expr item ^ "]"
  | Noexpr -> ""


let string_of_member = function 
  (name, e) -> name ^ ": " ^ string_of_expr e

let string_of_component = function 
  (name, ms) -> name ^ ":\n" ^ (String.concat "\n" (List.map string_of_member ms))
                  ^ "end\n"

let rec string_of_stmt = function
    Block(stmts) ->
      String.concat "\n" (List.map string_of_stmt stmts) ^ "\n"
  | Expr(expr) -> string_of_expr expr ^ "\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ "\n";
  | If(e, s, Block([])) -> "if " ^ string_of_expr e ^ ":\n" ^ string_of_stmt s
      ^ "end\n"
  | If(e, s1, s2) ->  "if " ^ string_of_expr e ^ ":\n" ^
      string_of_stmt s1 ^ "end\nelse:\n" ^ string_of_stmt s2 ^ "end\n"
  | For(s, e2, body) ->
      "for " ^ s ^ " in " ^ string_of_expr e2 ^ ":\n" ^
      string_of_stmt body ^ "end\n"
  | While(e, s) -> "while " ^ string_of_expr e ^ ":\n" ^ string_of_stmt s
      ^ "end\n"
  | Spawn (s, cs) -> "spawn " ^ s ^ ":" ^ (String.concat "\n" (List.map string_of_component cs)) ^ "end\n"
  
let rec string_of_typ = function
    Int -> "int"
  | Bool -> "bool"
  | Float -> "float"
  | Void -> "void"
  | String -> "string"
  | Entity tname -> "entity<" ^ tname ^ ">"
  | List(t) -> "< " ^ string_of_typ t ^ " >"
  

let string_of_vdecl (t, id) = string_of_typ t ^ " " ^ id ^ "\n"

let string_of_fmlsdcl (t, id) = string_of_typ t ^ " " ^ id

let string_of_fdecl fdecl = 
  "function " ^ string_of_typ fdecl.typ ^ " " ^ fdecl.name ^ "(" ^
  String.concat ", " (List.map string_of_fmlsdcl fdecl.formals) ^
  "):\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.locals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "end\n"

let string_of_query qdecl =
  "query<" ^ qdecl.tname ^ "> [" ^ String.concat ", " qdecl.components ^ "] as " ^ qdecl.lname ^ "\n"

let string_of_sdecl sdecl =
  "system " ^ sdecl.name ^ "(" ^ String.concat ", " (List.map string_of_fmlsdcl sdecl.formals) ^ ")" ^ ":\n" ^
  String.concat "" (List.map string_of_query sdecl.qlist) ^
  String.concat "" (List.map string_of_vdecl sdecl.locals) ^
  String.concat "" (List.map string_of_stmt sdecl.body) ^
  "end\n"

let string_of_sfdecl sfdecl =
  match sfdecl.qlist with
    [] -> string_of_fdecl sfdecl
  | _ -> string_of_sdecl sfdecl
  
let string_of_cdecl cdecl = "component " ^ cdecl.cname ^ ":\n" ^ (String.concat "" (List.map string_of_vdecl cdecl.members)) ^ "end\n"

let string_of_edecl edecl =
  "entity " ^ edecl.ename ^ ":\n" ^ (String.concat "\n" edecl.components) ^ "\nend\n"

let string_of_program prog =
  String.concat "\n" (List.map string_of_cdecl prog.components) ^ "\n" ^
  String.concat "\n" (List.map string_of_edecl prog.entities) ^ "\n" ^
  String.concat "\n" (List.map string_of_sfdecl prog.functions)
