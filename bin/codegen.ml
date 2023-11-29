(* Code generation: translate takes a semantically checked AST and
produces LLVM IR

LLVM tutorial: Make sure to read the OCaml version of the tutorial

http://llvm.org/docs/tutorial/index.html

Detailed documentation on the OCaml LLVM library:

http://llvm.moe/
http://llvm.moe/ocaml/

*)

(* We'll refer to Llvm and Ast constructs with module names *)
module L = Llvm
module A = Ast
open Sast 

module StringMap = Map.Make(String)

(* Code Generation from the SAST. Returns an LLVM module if successful,
   throws an exception if something is wrong. *)
let translate program =
  (* let _ = print_endline "entered translate" in *)
  let context    = L.global_context () in
  (* Add types to the context so we can use them in our LLVM code *)
  (* let i32_t      = L.i32_type    context *)
  let i64_t      = L.i64_type    context
  and i8_t       = L.i8_type     context
  and i32_t      = L.i32_type    context
  and i1_t       = L.i1_type     context
  and float_t    = L.double_type context
  and void_t     = L.void_type   context 
  and char_ptr_t = L.pointer_type (L.i8_type context)
  (* Create an LLVM module -- this is a "container" into which we'll 
     generate actual code *)
  and the_module = L.create_module context "Alpaca" in

  (* let _ = print_endline "defined types" in *)


  (* Convert MicroC types to LLVM types *)
  let ltype_of_typ = function
      A.Int      -> i64_t
    | A.Bool     -> i1_t
    | A.String   -> char_ptr_t
    | A.Float    -> float_t
    | A.Void     -> void_t
    (* Lists and entities not implemented yet *)
    | A.List _   -> i1_t
    | A.Entity _ -> i1_t
    
  in

  (* Declare each global variable; remember its value in a map 
  let global_vars : L.llvalue StringMap.t =
    let global_var m (t, n) = 
      let init = match t with
          A.Float -> L.const_float (ltype_of_typ t) 0.0
        | _ -> L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in*)

  (* TODO Maybe useful for implementing printb in C?
  let printb_t : L.lltype = 
      L.function_type void_t [| i8_t |] in
  let printb_func : L.llvalue = 
     L.declare_function "printb" printb_t the_module in*)

  let strcmp_t : L.lltype = 
      L.function_type i32_t [| char_ptr_t; char_ptr_t |] in
  let strcmp_func : L.llvalue = 
     L.declare_function "strcmp" strcmp_t the_module in

  let printf_t : L.lltype = 
      L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func : L.llvalue = 
      L.declare_function "printf" printf_t the_module in

  (* let _ = print_endline "declared print functions" in *)


  (* Define each function (arguments and return type) so we can 
   * define its body and call it later *)
  let function_decls : (L.llvalue * sfunc_decl) StringMap.t =
    let function_decl m fdecl =
      let name = fdecl.sname
      and formal_types = 
        Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.sformals)
      in let ftype = L.function_type (ltype_of_typ fdecl.styp) formal_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty program.sfunctions in
    
  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let (the_function, _) = StringMap.find fdecl.sname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in

    let int_format_str = L.build_global_stringptr "%lld\n" "fmt" builder
    and float_format_str = L.build_global_stringptr "%g\n" "fmt" builder
    and bool_format_str = L.build_global_stringptr "%hhd\n" "fmt" builder
    and string_format_str = L.build_global_stringptr "%s\n" "fmt" builder in
    (* let _ = print_endline "built function body" in *)
    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
  let local_vars =
      let add_formal m (t, n) p = 
      (* let _ = print_endline "top of add_formal" in *)
      let () = L.set_value_name n p in
      (* let _ = print_endline "finished calling set_value_name" in *)
	    let local = L.build_alloca (ltype_of_typ t) n builder in
      (* let _ = print_endline "called build_alloca" in *)
      let _  = L.build_store p local builder in
      (* let _ = print_endline "called build_store" in *)

	      StringMap.add n local m 
  in
  
      (* Allocate space for any locally declared variables and add the
       * resulting registers to our map *)
  let add_local m (t, n) =
    let initial_value_of_typ = function
        A.Int           -> L.const_of_int64 i64_t Int64.zero true
      | A.Float         -> L.const_float float_t 0.0
      | A.String        -> L.build_global_stringptr "" "empty" builder
      | A.Bool | A.Void -> L.const_int i1_t 0
      | A.Entity _      -> L.const_null (ltype_of_typ t)
      (*TODO: Decide what initial value of list is*)
      | A.List _        -> L.const_null (ltype_of_typ t)
    in
    let local_var = L.build_alloca (ltype_of_typ t) n builder
    in let _ = L.build_store (initial_value_of_typ t) local_var builder
    in StringMap.add n local_var m 
      in
      (* let _ = print_endline "in local var" in *)
      let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals
          (Array.to_list (L.params the_function)) in
      (* let _ = print_endline "created list of formals" in *)
      List.fold_left add_local formals fdecl.slocals 
    in

    (* Return the value for a variable or formal argument. First check
     * locals, then globals *)
    let lookup n = StringMap.find n local_vars
    in

    (* Construct code for an expression; return its value *)
    (* let _ = print_endline "before expr" in *)
    let rec expr builder ((_, e) : sexpr) = match e with
	      SLiteral (ILit i) -> L.const_of_int64 i64_t i true
      | SLiteral (BLit b) -> L.const_int i1_t (if b then 1 else 0)
      | SLiteral (FLit f) -> L.const_float float_t f
      | SLiteral (SLit s) -> L.build_global_stringptr s "strlit" builder
      | SNoexpr -> L.const_int i32_t 0
      | SId s -> L.build_load (lookup s) s builder
      | SAssign (s, e) -> let e' = expr builder e in
                          let _  = L.build_store e' (lookup s) builder in e'
      | SCompMember (_, _, _) -> raise (Failure "Components not implemented")
      | SCompMemberAssign (_, _, _, _) -> raise (Failure "Components not implemented")
      | SListExpr (_) -> raise (Failure "Lists not implemented")
      | SListItem (_, _) -> raise (Failure "Lists not implemented")
      | SBinop (e1, op, e2) ->
        let (t1, _) = e1
        and (t2, _) = e2
        and e1' = expr builder e1
        and e2' = expr builder e2 in
        let build_mixed_int_float int_func float_func = 
          match (t1, t2) with
            (A.Int, A.Int)     -> int_func e1' e2' "tmp" builder
          | (A.Float, A.Float) -> float_func e1' e2' "tmp" builder
          | (A.Int, A.Float)   -> float_func (L.build_sitofp e1' float_t "tmp" builder) e2' "tmp" builder
          | (A.Float, A.Int)   -> float_func e1' (L.build_sitofp e2' float_t "tmp" builder) "tmp" builder
          | _                  -> raise (Failure "build_mixed_int_float got types other than int/float")
        in
        let build_equality_check int_func float_func =
          match (t1, t2) with
            (A.Int, _) | (A.Float, _) -> build_mixed_int_float int_func float_func
          | (A.Bool, A.Bool)          -> int_func e1' e2' "tmp" builder
          | (A.String, A.String)      -> let cmp_result = L.build_call strcmp_func [|e1'; e2'|] "tmp" builder in 
                                         int_func cmp_result (L.const_int i32_t 0) "tmp" builder
          | _                         -> raise (Failure "Semant failed to catch invalid equality comparison")
        in
        (match op with 
          A.Add     -> build_mixed_int_float L.build_add L.build_fadd
        | A.Sub     -> build_mixed_int_float L.build_sub L.build_fsub
        | A.Mult    -> build_mixed_int_float L.build_mul L.build_fmul
        | A.Div     -> build_mixed_int_float L.build_sdiv L.build_fdiv
        | A.Eq      -> build_equality_check (L.build_icmp L.Icmp.Eq) (L.build_fcmp L.Fcmp.Oeq)
        | A.Neq     -> build_equality_check (L.build_icmp L.Icmp.Ne) (L.build_fcmp L.Fcmp.One)
        | A.Less    -> build_mixed_int_float (L.build_icmp L.Icmp.Slt) (L.build_fcmp L.Fcmp.Olt)
        | A.Leq     -> build_mixed_int_float (L.build_icmp L.Icmp.Sle) (L.build_fcmp L.Fcmp.Ole)
        | A.Greater -> build_mixed_int_float (L.build_icmp L.Icmp.Sgt) (L.build_fcmp L.Fcmp.Ogt)
        | A.Geq     -> build_mixed_int_float (L.build_icmp L.Icmp.Sge) (L.build_fcmp L.Fcmp.Oge)
        | A.And | A.BitAnd -> L.build_and e1' e2' "tmp" builder
        | A.Or | A.BitOr   -> L.build_or e1' e2' "tmp" builder
        | A.BitXor         -> L.build_xor e1' e2' "tmp" builder
        | A.ShiftL         -> L.build_shl e1' e2' "tmp" builder
        | A.ShiftR         -> L.build_ashr e1' e2' "tmp" builder
        | A.Mod     -> L.build_srem e1' e2' "tmp" builder
        )
      | SUnop(op, e) ->
        let (t, _) = e in
              let e' = expr builder e in
        (match op with
          A.Neg when t = A.Float -> L.build_fneg 
        | A.Neg                  -> L.build_neg
        | A.Not                  -> L.build_not) e' "tmp" builder
      | SCall ("printi", [e]) ->
	      L.build_call printf_func [| int_format_str ; (expr builder e) |]
	        "printf" builder
      | SCall ("printb", [e]) ->
	      L.build_call printf_func [| bool_format_str ; (expr builder e) |]
	        "printf" builder
      | SCall ("prints", [e]) ->
	      L.build_call printf_func [| string_format_str ; (expr builder e) |] "printf" builder
      | SCall ("printf", [e]) -> 
	      L.build_call printf_func [| float_format_str ; (expr builder e) |]
	        "printf" builder
      | SCall (f, args) ->
         let (fdef, fdecl) = StringMap.find f function_decls in
	        let llargs = List.rev (List.map (expr builder) (List.rev args)) in
	        let result = (match fdecl.styp with 
                        A.Void -> ""
                      | _ -> f ^ "_result") in
         L.build_call fdef (Array.of_list llargs) result builder
      
        in
        (* let _ = print_endline "declared builder stuff" in *)
        (* Each basic block in a program ends with a "terminator" instruction i.e.
        one that ends the basic block. By definition, these instructions must
        indicate which basic block comes next -- they typically yield "void" value
        and produce control flow, not values *)
        (* Invoke "instr builder" if the current block doesn't already
          have a terminator (e.g., a branch). *)
        let add_terminal builder instr =
                              (* The current block where we're inserting instr *)
          match L.block_terminator (L.insertion_block builder) with
      Some _ -> ()
          | None -> ignore (instr builder) in
      
    (* Build the code for the given statement; return the builder for
      the statement's successor (i.e., the next instruction will be built
      after the one generated by this call) *)
    (* Imperative nature of statement processing entails imperative OCaml *)
    let rec stmt builder = function
	      SBlock sl ->  List.fold_left stmt builder sl
        (* Generate code for this expression, return resulting builder *)
      | SExpr e -> let _ = expr builder e in builder 
      | _ -> raise (Failure "Not implemented")
      (*| SReturn e -> let _ = match fdecl.styp with
                              (* Special "return nothing" instr *)
                              A.Void -> L.build_ret_void builder 
                              (* Build return statement *)
                            | _ -> L.build_ret (expr builder e) builder 
                     in builder
      (* The order that we create and add the basic blocks for an If statement
      doesnt 'really' matter (seemingly). What hooks them up in the right order
      are the build_br functions used at the end of the then and else blocks (if
      they don't already have a terminator) and the build_cond_br function at
      the end, which adds jump instructions to the "then" and "else" basic blocks *)
      | SIf (predicate, then_stmt, else_stmt) ->
         let bool_val = expr builder predicate in
         (* Add "merge" basic block to our function's list of blocks *)
	 let merge_bb = L.append_block context "merge" the_function in
         (* Partial function used to generate branch to merge block *) 
         let branch_instr = L.build_br merge_bb in

         (* Same for "then" basic block *)
	 let then_bb = L.append_block context "then" the_function in
         (* Position builder in "then" block and build the statement *)
         let then_builder = stmt (L.builder_at_end context then_bb) then_stmt in
         (* Add a branch to the "then" block (to the merge block) 
           if a terminator doesn't already exist for the "then" block *)
	 let () = add_terminal then_builder branch_instr in

         (* Identical to stuff we did for "then" *)
	 let else_bb = L.append_block context "else" the_function in
         let else_builder = stmt (L.builder_at_end context else_bb) else_stmt in
	 let () = add_terminal else_builder branch_instr in

         (* Generate initial branch instruction perform the selection of "then"
         or "else". Note we're using the builder we had access to at the start
         of this alternative. *)
	 let _ = L.build_cond_br bool_val then_bb else_bb builder in
         (* Move to the merge block for further instruction building *)
	 L.builder_at_end context merge_bb

      | SWhile (predicate, body) ->
          (* First create basic block for condition instructions -- this will
          serve as destination in the case of a loop *)
	  let pred_bb = L.append_block context "while" the_function in
          (* In current block, branch to predicate to execute the condition *)
	  let _ = L.build_br pred_bb builder in

          (* Create the body's block, generate the code for it, and add a branch
          back to the predicate block (we always jump back at the end of a while
          loop's body, unless we returned or something) *)
	  let body_bb = L.append_block context "while_body" the_function in
          let while_builder = stmt (L.builder_at_end context body_bb) body in
	  let () = add_terminal while_builder (L.build_br pred_bb) in

          (* Generate the predicate code in the predicate block *)
	  let pred_builder = L.builder_at_end context pred_bb in
	  let bool_val = expr pred_builder predicate in

          (* Hook everything up *)
	  let merge_bb = L.append_block context "merge" the_function in
	  let _ = L.build_cond_br bool_val body_bb merge_bb pred_builder in
	  L.builder_at_end context merge_bb

      (* Implement for loops as while loops! *)
      | SFor (e1, e2, e3, body) -> stmt builder
	    ( SBlock [SExpr e1 ; SWhile (e2, SBlock [body ; SExpr e3]) ] ) *)
    in

    (* Build the code for each statement in the function *)
    let builder = stmt builder (SBlock fdecl.sbody) in
    (* let _ = print_endline "created builder" in *)
    (* Add a return if the last block falls off the end *)
    add_terminal builder (match fdecl.styp with
        A.Void -> L.build_ret_void
      | A.Float -> L.build_ret (L.const_float float_t 0.0)
      | A.String -> L.build_ret (L.build_global_stringptr "" "empty" builder)
      | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
  in

  List.iter build_function_body program.sfunctions;
  the_module
