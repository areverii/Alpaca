(* Semantic checking for the MicroC compiler *)

open Ast
open Sast
module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each function,  *)
let check program  =

  (*Check if a certain kind of binding has void type or is a duplicate
     of another, previously checked binding *)
  let check_binds (kind : string) (to_check : bind list) = 
    let name_compare (_, n1) (_, n2) = compare n1 n2 in
    let check_it checked binding = 
      let void_err = "illegal void " ^ kind ^ " " ^ snd binding
      and dup_err = "duplicate " ^ kind ^ " " ^ snd binding
      in match binding with
        (* No void bindings *)
        (Void, _) -> raise (Failure void_err)
      | (_, n1) -> match checked with
                    (* No duplicate bindings *)
                      ((_, n2) :: _) when n1 = n2 -> raise (Failure dup_err)
                    | _ -> binding :: checked

    in let _ = List.fold_left check_it [] (List.sort name_compare to_check) 
       in to_check
  in

  (**** Checking Functions ****)

  (* Collect function declarations for built-in functions: no bodies *)
  let built_in_decls = 
    let add_bind map (name, ty) = StringMap.add name {
      typ = Void; name = name; 
      formals = [(ty, "x")];
      locals = []; body = []; qlist = [] } map
    in List.fold_left add_bind StringMap.empty [ ("prints", String);
			                         ("printb", Bool);
			                         ("printf", Float);
			                         ("printi", Int) ]
  in

  (* Add function name to symbol table *)
  let add_func map fd = 
    let built_in_err = "function " ^ fd.name ^ " may not be defined"
    and dup_err = "duplicate function " ^ fd.name
    and make_err er = raise (Failure er)
    and n = fd.name (* Name of the function *)
    in match fd with (* No duplicate functions or redefinitions of built-ins *)
         _ when StringMap.mem n built_in_decls -> make_err built_in_err
       | _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n fd map 
  in

  (* Collect all other function names into one symbol table *)
  let function_decls = List.fold_left add_func built_in_decls program.functions
  in
  
  (* Return a function from our symbol table *)
  let find_func s = 
    try StringMap.find s function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  (* Ensure "main" is correctly defined *)
  let main_func = find_func "main" 
  in 

  let check_main = 
    match main_func with
      { typ = Void; formals = [(List String, _)]; _ } -> ()
      | _ -> raise (Failure ("main function args or return type incorrect")) 
  in 

  let _ = check_main 
  in
  
  let check_function (func : func_decl) =
    
    (* Make sure no formals or locals are void or duplicates *)
    let formals' = check_binds "formal" func.formals in
    let locals' = check_binds "local" func.locals in

    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
    let check_assign lvaluet rvaluet err =
       if lvaluet = rvaluet then lvaluet else raise (Failure err)
    in   

    (* Build local symbol table of variables for this function *)
    let symbols = List.fold_left (fun m (ty, name) -> StringMap.add name ty m)
	                StringMap.empty (formals' @ locals')
    in

    (* Return a variable from our local symbol table *)
    let type_of_identifier s =
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in 

    (* Return a semantically-checked expression, i.e., with a type *)
    let rec expr = function
        Literal (ILit l) -> (Int, SLiteral (ILit l))
      | Literal (FLit l) -> (Float, SLiteral (FLit l))
      | Literal (SLit l) -> (String, SLiteral (SLit l))
      | Literal (BLit l) -> (Bool, SLiteral (BLit l))
      | Noexpr           -> (Void, SNoexpr)
      | Id s       -> (type_of_identifier s, SId s)
      | Assign(var, e) as ex -> 
          let lt = type_of_identifier var 
          and (rt, e') = expr e in
          let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
            string_of_typ rt ^ " in " ^ string_of_expr ex
          in (check_assign lt rt err, SAssign(var, (rt, e')))
      | Unop(op, e) as ex -> 
          let (t, e') = expr e in
          let ty = match op with
            Neg when t = Int || t = Float -> t
          | Not when t = Bool -> Bool
          | _ -> raise (Failure ("illegal unary operator " ^ 
                                 string_of_uop op ^ string_of_typ t ^
                                 " in " ^ string_of_expr ex))
          in (ty, SUnop(op, (t, e')))
      | Binop(e1, op, e2) as e -> 
          let (t1, e1') = expr e1 
          and (t2, e2') = expr e2 in
          let ints_or_floats = (t1 = Int || t1 = Float) && (t2 = Int || t2 = Float) in
          (* Some binary operators require operands of the same type *)
          let same = t1 = t2 in
          (* Determine expression type based on operator and operand types *)
          let ty = match op with
            Add | Sub | Mult | Div when same && t1 = Int -> Int
          | Add | Sub | Mult | Div when ints_or_floats   -> Float
          | Eq | Neq               when (same && t1 = String || t1 = Bool) || ints_or_floats -> Bool
          | Less | Leq | Greater | Geq when ints_or_floats -> Bool
          | And | Or when same && t1 = Bool -> Bool
          | BitOr | BitAnd | BitXor | Mod | ShiftR | ShiftL when same && t1 = Int -> Int
          | _ -> raise (Failure ("illegal binary operator " ^
                       string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                       string_of_typ t2 ^ " in " ^ string_of_expr e))
          in (ty, SBinop((t1, e1'), op, (t2, e2')))
      | Call(fname, args) as call -> 
          let fd = find_func fname in
          let param_length = List.length fd.formals in
          if List.length args != param_length then
            raise (Failure ("expecting " ^ string_of_int param_length ^ 
                            " arguments in " ^ string_of_expr call))
          else let check_call (ft, _) e = 
            let (et, e') = expr e in 
            let err = "illegal argument found " ^ string_of_typ et ^
              " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e
            in (check_assign ft et err, e')
          in 
          let args' = List.map2 check_call fd.formals args
          in (fd.typ, SCall(fname, args'))
      | ListExpr es -> 
          let ses = List.map expr es in
            (try 
              let t1 = fst (List.hd ses) in
              let all_ts_eq = List.for_all (fun t -> t = t1) (List.map fst ses) in
              if all_ts_eq then
                (List t1, SListExpr ses)
              else
                raise (Failure "list element types differ")
            with Failure _ -> raise (Failure "empty list literal not allowed"))
      | ListItem (s, e) ->  
        let (t, e') = expr e
        in if t = Int 
          then match type_of_identifier s with 
              List ty -> (ty, SListItem (s, (t, e')))
              | _ -> raise (Failure ("attempting to index non-list " ^ s))
         else raise (Failure "index expression not of type int")
      | CompMember (ent, comp, field) -> raise (Failure "not implemented")
      | CompMemberAssign (ent, comp, field, v) -> raise (Failure "not implemented")
    in

     let check_bool_expr e = 
      let (t', e') = expr e
      and err = "expected Boolean expression in " ^ string_of_expr e
      in if t' != Bool then raise (Failure err) else (t', e') 
    in

    (* Return a semantically-checked statement i.e. containing sexprs *)
    let rec check_stmt = function
        Expr e -> SExpr (expr e)
      | If(p, b1, b2) -> SIf(check_bool_expr p, check_stmt b1, check_stmt b2)
      | For(s, e, stmt) -> 
          let (t, e') = expr e
          in (match t with
              List t1 -> if (type_of_identifier s = t1) then
                          SFor (s, (t, e'), check_stmt stmt)
                        else
                          raise (Failure ("for loop variable " ^ s ^ " of type "
                                          ^ string_of_typ (type_of_identifier s)
                                          ^ " does not match list type " ^ string_of_typ t))
            | _ -> raise (Failure ("attempting to iterate over non-list " ^ s)))
      | While(p, s) -> SWhile(check_bool_expr p, check_stmt s)
      | Return e -> let (t, e') = expr e in
          if t = func.typ then SReturn (t, e') 
          else raise (Failure ("return gives " ^ string_of_typ t ^ " expected " ^
                        string_of_typ func.typ ^ " in " ^ string_of_expr e))
	    
	    (* A block is correct if each statement is correct and nothing
	       follows any Return statement.  Nested blocks are flattened. *)
      | Block sl -> 
          let rec check_stmt_list = function
              [Return _ as s] -> [check_stmt s]
            | Return _ :: _   -> raise (Failure "nothing may follow a return")
            | Block sl :: ss  -> check_stmt_list (sl @ ss) (* Flatten blocks *)
            | s :: ss         -> check_stmt s :: check_stmt_list ss
            | []              -> []
          in SBlock(check_stmt_list sl)
      | Spawn (ent, es) -> raise (Failure "spawn not implemented") 

    in (* body of check_function *)

    { styp = func.typ;
      sname = func.name;
      sformals = formals';
      slocals  = locals';
      sqlist = func.qlist;
      sbody = match check_stmt (Block func.body) with
            SBlock(sl) -> sl
            | _ -> let err = "internal error: block didn't become a block?"
          in raise (Failure err) 
    } 
   
  in 
    { scomponents = [];
      sentities = [];
      sfunctions = List.map check_function program.functions;
    }