(* Semantic checking for the MicroC compiler *)
(*
Authors: 
Elliot Bonner
Phila Dlamini
Nathan Solomon
Nicholas Woodward
*)
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

  (**** Checking Components ****)
  let add_comp map (cd : comp_decl) = 
    let dup_err = "duplicate component " ^ cd.cname in
    let make_err er = raise (Failure er) in
    let n = cd.cname (* Name of the component *) 
    in match cd with (* No duplicate components *)
         _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n cd map 
  in

  (* Collect all component names into a symbol table*)
  let comp_decls = List.fold_left add_comp StringMap.empty program.components
  in

  (* Check all component members *)
  let check_comp (cd : comp_decl) = 
    let members' = check_binds "member" cd.members in
    {
      cname = cd.cname;
      members = members'
    }
  in

  (**** Checking Entities ****)
  let add_ent map (ed : entity_decl) = 
    let dup_err = "duplicate entity " ^ ed.ename in
    let make_err er = raise (Failure er) in
    let n = ed.ename (* Name of the component *) 
    in match ed with (* No duplicate entities *)
         _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n ed map 
  in

  (* Ensure non-duplicate entity declarations *)
  let ent_decls = List.fold_left add_ent StringMap.empty program.entities
  in

  (* Ensure component list is valid *)
  let check_complist checked curr = 
    let dup_err = "duplicate comp name " ^ curr in
    let undefined_err = "undefined comp name " ^ curr in
    let make_err er = raise (Failure er)
    in match checked with 
     n1 :: _ when curr = n1 -> raise (Failure dup_err)
     | _ when StringMap.mem curr comp_decls -> curr :: checked 
     | _ -> make_err undefined_err
  in

  (* Check that all components are valid *)
  let check_ent (ed : entity_decl) = 
     let components' = List.fold_left check_complist [] (List.sort (fun n1 n2 -> compare n1 n2) ed.components) 
    in
    {
      ename = ed.ename;
      components = components'
    }
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

  (**** Check entity list names in query ****)
  let add_query_list_name map (q : query) = 
    let dup_err = "duplicate query list name " ^ q.lname in
    let make_err er = raise (Failure er) in
    let n = q.lname
    in match n with (* No duplicate components *)
         _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n (List(Entity(q.tname))) map 
  in

  (* Collect all component names into a symbol table*)
  let query_list_names = StringMap.empty
  in

   (**** Check query type names in query ****)
   let add_query_type map (q : query) = 
    let dup_err = "duplicate query list type " ^ q.tname in
    let make_err er = raise (Failure er) in
    let n = q.tname
    in match n with (* No duplicate components *)
         _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n q.qcomponents map 
  in

  (* Collect all component names into a symbol table*)
  let query_types = StringMap.empty
  in
  
  let check_function (func : func_decl) =
    
    (* Make sure no formals or locals are void or duplicates *)
    let formals' = check_binds "formal" func.formals in
    let locals' = check_binds "local" func.locals in
    
    let check_query (q : query) = 
      let components' = List.fold_left check_complist [] (List.sort (fun n1 n2 -> compare n1 n2) q.qcomponents) in
      {
        tname = q.tname;
        qcomponents = components';
        lname = q.lname;
      }
    in 
    
    let query_list_names_map = List.fold_left add_query_list_name query_list_names func.qlist in
    let query_types = List.fold_left add_query_type query_types func.qlist in
    let qlist' = List.map check_query func.qlist in
    let symbols = List.fold_left (fun m (ty, name) -> StringMap.add name ty m)
	                StringMap.empty (formals' @ locals' @ (StringMap.fold (fun k v accum -> (v, k) :: accum) query_list_names_map []))
    in
    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
    let check_assign lvaluet rvaluet err =
       if lvaluet = rvaluet then lvaluet else raise (Failure err)
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
      | Call("len", args) as call ->
        if List.length args != 1 then
          raise (Failure ("expecting 1 argument in " ^ string_of_expr call))
        else let (argt, sarg) = expr (List.hd args) in
          (match argt with
              List _ -> (Int, SCall("len", [(argt, sarg)]))
            | _ -> raise (Failure "Got non-list argument to len")
        )
      | Call("append", args) as call ->
        if List.length args != 2 then
          raise (Failure ("expecting 2 arguments in " ^ string_of_expr call))
        else let args' = List.map expr args in
          (match args' with
              [(List et, _); (et', _)] when et = et' -> (List et, SCall("append", args'))
            | [(t1, _); (t2, _)] -> raise (Failure ("Got invalid arguments to append expected (list, elem) found " 
                                                    ^ string_of_typ t1 ^ ", " ^ string_of_typ t2))
            | _ -> raise (Failure "Internal error in append args check")
        )
      | Call("slice", args) as call ->
        if List.length args != 3 then
          raise (Failure ("expecting 3 arguments in " ^ string_of_expr call))
        else let args' = List.map expr args in
          (match args' with
              [(List et, _); (Int, _); (Int, _)] -> (List et, SCall("slice", args'))
            | [(t1, _); (t2, _); (t3, _)] -> raise (Failure ("Got invalid arguments to slice expected (list, int, int) found " 
                                                    ^ string_of_typ t1 ^ ", " ^ string_of_typ t2 ^ ", " ^ string_of_typ t3))
            | _ -> raise (Failure "Internal error in slice args check")
        )
      | Call("pop_back", args) as call ->
        if List.length args != 1 then
          raise (Failure ("expecting 1 argument in " ^ string_of_expr call))
        else let (argt, sarg) = expr (List.hd args) in
          (match argt with
              List _ -> (argt, SCall("pop_back", [(argt, sarg)]))
            | _ -> raise (Failure "Got non-list argument to pop_back")
        )
      | Call("back", args) as call ->
        if List.length args != 1 then
          raise (Failure ("expecting 1 argument in " ^ string_of_expr call))
        else let (argt, sarg) = expr (List.hd args) in
          (match argt with
              List et -> (et, SCall("back", [(argt, sarg)]))
            | _ -> raise (Failure "Got non-list argument to back")
        )
      | Call("range", args) as call -> 
        if List.length args != 2 then
          raise (Failure ("expecting 2 arguments in " ^ string_of_expr call))
        else let args' = List.map expr args in
          (match args' with
              [(Int, _); (Int, _)] -> (List Int, SCall("range", args'))
            | [(t1, _); (t2, _)] -> raise (Failure ("Got invalid arguments to range expected (int, int) found " 
                                                    ^ string_of_typ t1 ^ ", " ^ string_of_typ t2))
            | _ -> raise (Failure "Internal error in range args check")
        )
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
     
      | CompMember (ent, comp, member) ->

          (* ensure ent is in ent symbol table and retrieve its type*)

        let ret = 
          try 
            (match StringMap.find ent symbols with
              Entity (ty_name ) ->
                let ent_ty_components = StringMap.find ty_name query_types in
                if not (List.exists (fun curr -> curr = comp) ent_ty_components)
                  then raise (Failure ("entity " ^ ent ^ " does not contain component " ^ comp))
                else 
                    let comp_rec = StringMap.find comp comp_decls in 
                    let rec find_member_type = function
                      [] -> raise (Failure ("component " ^ comp ^ " does not contain member " ^ member))
                    | (t, m) :: ms -> if m = member then t else find_member_type ms
                    in (find_member_type comp_rec.members, SCompMember (ent, comp, member))
              | _ -> raise (Failure ("entity " ^ ent ^ " has not been declared")))
          with Not_found -> raise (Failure ("undeclared identifier " ^ ent ))
        in ret
      | CompMemberAssign (ent, comp, member, e) ->
          let (ty, e') = expr e in
          let ret = 
            try 
              (* let ent_rec = StringMap.find ent ent_decls in  *)
              (match StringMap.find ent symbols with
                Entity (ty_name ) -> 
                  let ent_ty_components = StringMap.find ty_name query_types in
                  if not (List.exists (fun curr -> curr = comp) ent_ty_components)
                    then raise (Failure ("entity " ^ ent ^ " does not contain component " ^ comp))
                  else 
                    let comp_rec = StringMap.find comp comp_decls in 
                    let rec find_member_type = function
                      [] -> raise (Failure ("component " ^ comp ^ " does not contain member " ^ member))
                    | (t, m) :: ms -> if m = member then t
                          else find_member_type ms
                    in 
                      let t = find_member_type comp_rec.members in
                      if ty = t then (ty, SCompMemberAssign(ent, comp, member, (ty, e')))
                      else raise (Failure ("attempted to assign mismatched type to " ^ member))
                | _ -> raise (Failure ("entity " ^ ent ^ " has not been declared")))
            
            with Not_found -> raise (Failure ("undeclared identifier " ^ ent))
          in ret
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
      | Spawn (ent, comp_assigns) -> 
          
        (* 1. Ensure ent exists
          2. For each component:
            - ensure comp exists and is in entity 
            - for each member:
              - ensure member exists
              - ensure assignment is valid

        spawn Ent_Name: 

          comp_name1:
            x: 231
            name: "string"

          comp_name2:
            pi: 23.3
            done: false
           
        *)
        let check_dups checked (curr, t) = 
          let dup_err = "duplicate assignment in spawn"
          in match checked with
                        (* No duplicate bindings *)
                          ((n2, _) :: _) when curr = n2 -> raise (Failure dup_err)
                        | _ -> (curr, t) :: checked
        in

        let ret =
          try
            let ent_rec = StringMap.find ent ent_decls in
            let name_compare n1 n2 = compare n1 n2 in
            let rec lists_equal list1 list2 =
              match (list1, list2) with
              | ([], []) -> true
              | (h1 :: t1, h2 :: t2) when h1 = h2 -> lists_equal t1 t2
              | _ -> false
            in
            (*Ensure all components are instantiated *)
            let comp_names = List.map (fun (n, _) -> n) comp_assigns in
            let sorted_comp_names = List.sort name_compare comp_names in
            let sorted_ent_comps = List.sort name_compare ent_rec.components in
            if (not (lists_equal sorted_comp_names sorted_ent_comps))
              then raise (Failure ("spawn does not instantiate every component of entity " ^ ent_rec.ename))
            else 
            (*comp = string, assigns = (string * expr) list) *)
            let check_comp_assign accum (comp, assigns) = 
              let comp_rec = StringMap.find comp comp_decls in 

              (*Make sure all members are instantiated*)
              let mem_names = List.map (fun (n, _) -> n) assigns in
              let sorted_mem_names = List.sort name_compare mem_names in
              let sorted_m_comps = List.sort name_compare (List.map (fun (_, n) -> n) comp_rec.members) in
              let same = lists_equal sorted_m_comps sorted_mem_names in
              if (not same)
                then raise (Failure ("spawn does not instantiate every member of one or more components in " ^ ent_rec.ename))
              else

              (* Avoid duplicate member assignments *)
              let _ = List.fold_left check_dups [] (List.sort (fun (n1, _) (n2, _) -> compare n1 n2) assigns) in

              (* check that the component is part of entity *)
              if not (List.exists (fun curr -> curr = comp) ent_rec.components)
                then raise (Failure ("entity " ^ ent ^ " does not contain component " ^ comp))
              else 
              (* check the member assignment types for component*)
              let check_assigns accum (name, e) =
                let (ty1, _) = List.find (fun (_, mem) -> name = mem) comp_rec.members in
                let (ty2, e') = expr e in
                if ty1 = ty2 then (name, (ty2, e')) :: accum
                else raise (Failure ("attempted to assign mismatched type to " ^ name))
                
              in 
              (comp, List.rev (List.fold_left check_assigns [] assigns)) :: accum
            in 
              let comp_assign_list = List.fold_left check_comp_assign [] comp_assigns in

          
              (* Avoid duplicate component assignments *)
              let _ = List.fold_left check_dups [] (List.sort (fun (n1, _) (n2, _) -> compare n1 n2) comp_assigns) 
          in SSpawn (ent, comp_assign_list)
        with Not_found -> raise (Failure ("unrecognized entity " ^ ent))
        in ret
    in 

    { styp = func.typ;
      sname = func.name;
      sformals = formals';
      slocals  = locals';
      sqlist = qlist';
      sbody = match check_stmt (Block func.body) with
            SBlock(sl) -> sl
            | _ -> let err = "internal error: block didn't become a block?"
          in raise (Failure err) 
    } 
   
  in 
    { scomponents = List.map check_comp program.components;
      sentities = List.map check_ent program.entities;
      sfunctions = List.map check_function program.functions;
    }


(*TODO: in a spawn, ensure that the members appear in the same order as the component declaration *)