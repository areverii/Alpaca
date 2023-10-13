(* Abstract Syntax Tree and functions for printing it *)

type triop = Dot

type binop = Add | Sub | Mult | Div | Mod | ShiftR | ShiftL |
              BitOr | BitAnd | Xor | Eq | Neq | Less | Greater | Leq | Geq |
              And | Or

type uop = Neg | Not

type typ = Int | Bool | Float | String | Entity | Void 

type bind = typ * string

type lit = 
    ILit of int
  | SLit of string
  | FLit of float
  | BLit of bool
  | LLit of lit list

type expr =
    Binop of expr * binop * expr
  | Literal of lit 
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
  | If of expr * stmt
  | IfElse of expr * stmt * stmt
  | For of string * expr * stmt
  | While of expr * stmt 
  | Spawn of string * (string * ((string * expr) list)) list

type func_decl = {
    typ : typ;
    fname : string;
    formals : bind list;
    locals : bind list;
    body : stmt list;
  }

type comp_decl = {
  cname : string;
  members : bind list;
}

type entity_decl = {
  ename: string;
  components : string list;
}

type system_decl = {
  sname : string;
  formals : bind list;
  qlist : string list;
  qlistname : string;
  body : stmt list;
}


type program = comp_decl list * entity_decl list * system_decl list * func_decl list 

(* Pretty-printing functions 

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
  | Xor -> "^"
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
  | Not -> "!"

let rec string_of_expr = function
    Literal(l) -> string_of_int l
  | Fliteral(l) -> l
  | BoolLit(true) -> "true"
  | BoolLit(false) -> "false"
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | For(e1, e2, e3, s) ->
      "for (" ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^
      string_of_expr e3  ^ ") " ^ string_of_stmt s
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s

let string_of_typ = function
    Int -> "int"
  | Bool -> "bool"
  | Float -> "float"
  | Void -> "void"

let string_of_vdecl (t, id) = string_of_typ t ^ " " ^ id ^ ";\n"

let string_of_fdecl fdecl =
  string_of_typ fdecl.typ ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.formals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.locals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_program (vars, funcs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs) *)
