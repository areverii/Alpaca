(* Code generation: translate takes a semantically checked AST and
Produces LLVM IR

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
open Ast

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
  and void_ptr_t = L.pointer_type (L.i64_type context) 

  (* Create an LLVM module -- this is a "container" into which we'll 
    generate actual code *) 
  and the_module = L.create_module context "Alpaca" in

  (*Create the registry struct*)
  let query_struct_typ = L.named_struct_type context "QueryResult" in
  L.struct_set_body query_struct_typ [| i64_t; L.pointer_type (L.pointer_type void_ptr_t)|] false; 
  
  (* Convert Alpaca types to LLVM types *)
  let rec ltype_of_typ = function
      A.Int      -> i64_t
    | A.Bool     -> i1_t
    | A.String   -> char_ptr_t
    | A.Float    -> float_t
    | A.Void     -> void_t
    (* Lists and entities not implemented yet *)
    | A.List t   -> 
      let element_type = ltype_of_typ t in
      let length_type = i64_t in
      let data_type = L.pointer_type element_type in
      L.struct_type context [| length_type; data_type |]
    | A.Entity _ -> (L.pointer_type void_ptr_t) (*A double void pointer*)
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

  let stderr_global = L.declare_global void_ptr_t "stderr" the_module in
  let fprintf_t : L.lltype = 
      L.var_arg_function_type i32_t [| void_ptr_t; L.pointer_type i8_t |] in
  let fprintf_func : L.llvalue = 
      L.declare_function "fprintf" fprintf_t the_module in

  (*TODO: how to fix the issue where void_t as a return type causes issues?*)
  let registry_init_t : L.lltype = L.function_type void_t [| |] in
  let registry_init_func : L.llvalue = L.declare_function "reg_init" registry_init_t the_module in 

  let registry_add_t : L.lltype = L.function_type void_t [|L.pointer_type void_ptr_t |] in
  let registry_add_func : L.llvalue = L.declare_function "reg_add" registry_add_t the_module in

  let registry_query_t : L.lltype = L.function_type (L.pointer_type query_struct_typ) [| L.pointer_type i64_t ; i64_t|] in
  let registry_query_func : L.llvalue = L.declare_function "reg_query" registry_query_t the_module in
  
  let exit_t : L.lltype = 
      L.function_type void_t [| i32_t |] in
  let exit_func : L.llvalue = 
      L.declare_function "exit" exit_t the_module in
  
  let memcpy_t : L.lltype = 
      L.function_type void_t [| void_ptr_t; void_ptr_t; i64_t |] in
  let memcpy_func : L.llvalue = 
      L.declare_function "memcpy" memcpy_t the_module in


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

  (*Remember the index of each member in a component*)
  let assign_member_id map scomp = 
    let assign_id map (_, mem) =
      StringMap.add (scomp.cname ^ ":" ^ mem) (StringMap.cardinal map) map in
    let comp_map = List.fold_left assign_id StringMap.empty scomp.members in 
    StringMap.fold (fun key value acc_map -> StringMap.add key value acc_map) map comp_map
  in

  let comp_member_ids = List.fold_left assign_member_id StringMap.empty program.scomponents in

  (*Build a struct type for each component *)
  let build_comp_struct map scomp = 
    let types_arr = List.map (fun (ty, _) -> ltype_of_typ ty) scomp.members in
    let struct_type = L.named_struct_type context scomp.cname in
    L.struct_set_body struct_type (Array.of_list (List.rev types_arr)) false; (*TODO: should this reversal be happening elsewhere? *)
    StringMap.add scomp.cname struct_type map in
    
  (* Assign each component a numeric identifier*)
  let assign_comp_id map scomp = 
    StringMap.add scomp.cname (StringMap.cardinal map) map in

  (* Mapping from components to IDs *)
    let comp_ids = List.fold_left assign_comp_id StringMap.empty program.scomponents
  in 

  (*Mapping from components to struct types*)
  let struct_types = List.fold_left build_comp_struct StringMap.empty program.scomponents in

  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let (the_function, _) = StringMap.find fdecl.sname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in
    let int_format_str = L.build_global_stringptr "%lld\n" "fmt" builder
    and float_format_str = L.build_global_stringptr "%g\n" "fmt" builder
    and bool_format_str = L.build_global_stringptr "%hhd\n" "fmt" builder
    and string_format_str = L.build_global_stringptr "%s\n" "fmt" builder in

  (* Init registry if this is main *)
  let _ = if fdecl.sname = "main" then 
    ignore(L.build_call registry_init_func [| |] "" builder) in

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
          | A.List et       -> L.const_named_struct (ltype_of_typ t)
                                [| L.const_int i64_t 0;
                                    L.const_pointer_null (L.pointer_type (ltype_of_typ et)) |]
    in 
      let local_var = L.build_alloca (ltype_of_typ t) n builder in
        let _ = L.build_store (initial_value_of_typ t) local_var builder
        in StringMap.add n local_var m 
      in
      (* let _ = print_endline "in local var" in *)
     
    let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals
          (Array.to_list (L.params the_function)) in

    List.fold_left add_local formals fdecl.slocals in

     (* adds the query list name to locals *)
    let add_query_list map curr_query =

      (* Get the query result *)
      let ids = List.map (fun comp -> StringMap.find comp comp_ids) curr_query.qcomponents in 
      let comp_ids_len = (L.const_int i64_t (List.length ids)) in 
      (* let _ = print_endline ("num of comp ids " ^ (string_of_int (List.length ids))) in *)
      let comp_arr = L.build_array_alloca i64_t comp_ids_len  "comp_arr_heap" builder in
      (* let _ = print_endline "about to allocate comp_ids arr" in *)
      let rec put ls arr index = match ls with 
        [] -> arr 
        | x :: xs -> 
            let idx = L.const_int i32_t index in 
            let value = L.const_int i64_t x in 
            let _ = L.build_store value (L.build_gep arr [| idx |] "element_ptr" builder) builder in
            put xs arr (index + 1) in

      let init_comp_arr = put ids comp_arr 0 in  
      let query_strct_ptr = L.build_call registry_query_func [| init_comp_arr; comp_ids_len|] "registry_query" builder in

      (* let _ = L.dump_value ret in  *)
      let size_int = L.build_load ( L.build_struct_gep query_strct_ptr 0 "field_ptr" builder) "" builder in 
      let ent_arr = L.build_load (L.build_struct_gep query_strct_ptr 1 "field_ptr" builder) "" builder in
      let _ = L.dump_value size_int in 
      let _ = L.dump_value ent_arr in
      (*Create an alpaca array *)
      (* let struct_ty = ltype_of_typ (A.List (Entity curr_query.tname)) in 
      let malloc_result = L.build_malloc struct_ty "mallocResult" builder in
      let struct_ptr = L.build_bitcast malloc_result (L.pointer_type struct_ty) "struct_ptr" builder in
    
      (*init alpaca array*)
      let size_ptr = L.build_struct_gep struct_ptr 0 "field_ptr" builder in
      let arr_ptr = L.build_struct_gep struct_ptr 1 "field_ptr" builder in
      let _ = L.build_store size_int size_ptr builder in
      let _ = L.build_store ent_val arr_ptr builder in

      (*Put arr in locals *)
      let actual_struct = L.build_load struct_ptr "" builder in 
      let _ = print_endline ("listname is " ^ curr_query.lname) in  *)

      (*Switched to allocating struct on the stack. Issues later?*)
      let struct_typ = ltype_of_typ (A.List (Entity curr_query.tname)) in
      (* struct_instance *)
      let tmp_struct = L.const_named_struct struct_typ [| L.const_int i64_t 34; L.const_pointer_null ( L.pointer_type (ltype_of_typ (Entity curr_query.tname)))|] in
      (* allocate space for a struct_typ variable on the stack *)
      let tmp_struct_ptr = L.build_alloca struct_typ "tmp_struct_var" builder in
      (* Store the initial constant initialized struct in the allocated space *)
      let _ = L.build_store tmp_struct tmp_struct_ptr builder in
      let arr_field_ptr = L.build_struct_gep tmp_struct_ptr 1 "arr_field_ptr" builder in
      let _ = L.build_store ent_arr arr_field_ptr builder in 
      (* Load the final modified struct and return it (return value is the struct itself, NOT a pointer to a struct)
      let _ = L.build_load tmp_struct_ptr "load_tmp_struct" builder in *)

      StringMap.add curr_query.lname tmp_struct_ptr map in
      (*TODO: compiles but is it CORRECT?! *)

    (* Add all query lists to locals *)
    let local_vars = List.fold_left add_query_list local_vars fdecl.sqlist in
    
    (* Return the value for a variable or formal argument *)
    let lookup n = StringMap.find n local_vars
    in

    (* Returns a basic block that prints a message to strerr and exits the program *)
    let build_runtime_error_block err_msg =
      let error_bb = L.append_block context "error" the_function in  
      let builder = L.builder_at_end context error_bb in
      let message_str = L.build_global_stringptr err_msg "message" builder in
      ignore (L.build_call fprintf_func [| stderr_global; string_format_str; message_str |] "" builder);
      ignore (L.build_call exit_func [| L.const_int i32_t 1 |] "" builder);
      error_bb
    in

    (* Given a list llvalue (i.e. a list struct), returns the length and the pointer to the heap block *)
    let read_list list builder =
      let list_struct_ptr = L.build_alloca (L.type_of list) "list" builder in
      let _ = L.build_store list list_struct_ptr builder in
      let length_field_ptr = L.build_struct_gep list_struct_ptr 0 "length_field_ptr" builder in
      let length = L.build_load length_field_ptr "length" builder
      and arr_field_ptr = L.build_struct_gep list_struct_ptr 1 "arr_field_ptr" builder in
      let arr_ptr = L.build_load arr_field_ptr "arr_ptr" builder in
      (length, arr_ptr)
    in
    let new_list len elem_typ builder = 
      let arr_ptr = L.build_array_malloc (ltype_of_typ elem_typ) len "2" builder
      and struct_typ = ltype_of_typ (A.List elem_typ) in
      let tmp_struct_ptr = L.build_alloca struct_typ "tmp_struct_var" builder in
      let length_field_ptr = L.build_struct_gep tmp_struct_ptr 0 "length_field_ptr" builder
      and arr_field_ptr = L.build_struct_gep tmp_struct_ptr 1 "arr_field_ptr" builder in
      let _ = L.build_store arr_ptr arr_field_ptr builder
      and _ = L.build_store len length_field_ptr builder in
      (L.build_load tmp_struct_ptr  "new_list" builder, arr_ptr)
    in
    (*Given a list pointer and a value, copy the data to a new list and append 
      the value to the new list. Return the new list struct*)
    let append_value_to_list old_list (A.List et) value builder =
      (*Get the pointer and length of the old list. Copy the data from the old 
    into a new list that has + 1 memory and append value to that location. 
    Create a new struct with that pointer and size, then return it*)
      let old_len, old_arr_ptr = read_list old_list builder in
      let new_len = L.build_add old_len (L.const_int i64_t 1) "new_len" builder in
      (* print out new_len*)
      let new_list, new_arr_ptr = new_list new_len et builder in
      (*Perform the copy*)
      let elem_size = L.size_of (ltype_of_typ et) in
      let copy_size = L.build_mul old_len elem_size "copy_size" builder in
      let cast_old_arr_ptr = L.build_bitcast old_arr_ptr void_ptr_t "cast_old_arr_ptr" builder
      and cast_new_arr_ptr = L.build_bitcast new_arr_ptr void_ptr_t "cast_new_arr_ptr" builder in
      let _ = L.build_call memcpy_func [| cast_new_arr_ptr; cast_old_arr_ptr; copy_size |] "" builder in
      (*Append the final value*)
      (* let end_ptr_idx = L.build_mul new_len elem_size "copy_size" builder in  *)
      let end_ptr = L.build_gep new_arr_ptr [| new_len |] "end_ptr" builder in
      let _ = L.build_store value end_ptr builder in
      (*Return the struct representing the list with the pointe*)
      new_list

    in
      
    (* Slice a list given the element type, start index, and end index (as llvalues), returning a new list *)
    let slice_list old_list (A.List et) start_idx end_idx builder =
      let _, old_arr_ptr = read_list old_list builder in
      let new_len = L.build_sub end_idx start_idx "new_len" builder in
      let start_ptr = L.build_gep old_arr_ptr [| start_idx |] "start_ptr" builder in
      let new_list, new_arr_ptr = new_list new_len et builder in
      let elem_size = L.size_of (ltype_of_typ et) in
      let copy_size = L.build_mul new_len elem_size "copy_size" builder in
      let cast_start_ptr = L.build_bitcast start_ptr void_ptr_t "cast_start_ptr" builder
      and cast_new_arr_ptr = L.build_bitcast new_arr_ptr void_ptr_t "cast_new_arr_ptr" builder in
      let _ = L.build_call memcpy_func [| cast_new_arr_ptr; cast_start_ptr; copy_size |] "" builder in
      new_list
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
      | SCompMember (ent_name, comp, member) -> 
        let ent_ptr = lookup ent_name in (*pointer to entityt??*)
        (* let _ = if L.is_null ent_ptr then print_endline "ent arr is null!" in
        let _ = L.dump_value ent_ptr in
        let _ = print_endline "retreived ent_arr " in  *)
        let index = StringMap.find comp comp_ids in 
        (* let _ = print_endline ("index of comp " ^ comp ^ " is " ^ string_of_int index) in  *)
        let struct_ty = StringMap.find comp struct_types in
        (* let _ = L.dump_type struct_ty in  *)
        (* let _ = print_endline "found struct_ty in map " in  *)
        let comp_ptr = L.build_gep ent_ptr [| L.const_int i64_t index |] "element_ptr" builder in
        (* let _ = print_endline "got component is ent arr " in *)
        let struct_ptr = L.build_bitcast comp_ptr (L.pointer_type struct_ty) "void_ptr" builder in

        let member_index = StringMap.find (comp ^ ":" ^ member) comp_member_ids in
        let member_ptr = L.build_struct_gep struct_ptr member_index "field_ptr" builder in
        L.build_load member_ptr "loaded_value" builder  
      | SCompMemberAssign (ent_name, comp, member, e) -> 
        let e' = expr builder e in
        let ent_ptr = lookup ent_name in
        let index = StringMap.find comp comp_ids in 
        let struct_ty = StringMap.find comp struct_types in
        let comp_ptr = L.build_gep ent_ptr [| L.const_int i64_t index |] "element_ptr" builder in
        let struct_ptr = L.build_bitcast comp_ptr (L.pointer_type struct_ty) "void_ptr" builder in
        let member_index = StringMap.find (comp ^ ":" ^ member) comp_member_ids in
        let member_ptr = L.build_struct_gep struct_ptr member_index "field_ptr" builder in
         L.build_store e' member_ptr builder  
      | SListExpr (es) ->
          let vs = (List.map (expr builder) es)
          and typ = fst (List.hd es) in
          let ltyp = ltype_of_typ typ in
          let arr_ptr = L.build_array_malloc ltyp (L.const_int i64_t (List.length es)) "list_heap_arr" builder in
          (* Assign to each element of the allocated array *)
          let _ = List.fold_left
            (fun idx v -> (let elem_ptr = L.build_gep arr_ptr [| L.const_int i64_t idx |] "list_arr init" builder in 
                       let _ = L.build_store v elem_ptr builder in (idx + 1))) 0 vs in
          
          let struct_typ = ltype_of_typ (A.List typ) in
          (* struct_instance. Not filling in the pointer yet because the struct needs to be a constant expression. *)
          let tmp_struct = L.const_named_struct struct_typ [| L.const_int i64_t (List.length es); L.const_pointer_null (L.pointer_type ltyp)|] in
          (* allocate space for a struct_typ variable on the stack *)
          let tmp_struct_ptr = L.build_alloca struct_typ "tmp_struct_var" builder in
          (* Store the initial constant initialized struct in the allocated space *)
          let _ = L.build_store tmp_struct tmp_struct_ptr builder in
          let arr_field_ptr = L.build_struct_gep tmp_struct_ptr 1 "arr_field_ptr" builder in
          let _ = L.build_store arr_ptr arr_field_ptr builder in 
          (* Load the final modified struct and return it (return value is the struct itself, NOT a pointer to a struct) *)
          L.build_load tmp_struct_ptr "load_tmp_struct" builder
      | SListItem (list_name, idx_expr) ->
          let list_struct_ptr = lookup list_name
          and idx = expr builder idx_expr in
          (* check if index exists first*)
          (* let length_field_ptr = L.build_struct_gep list_struct_ptr 0 "length_field_ptr" builder in
          let length = L.build_load length_field_ptr "length" builder in
          let length_check = L.build_icmp L.Icmp.Sge idx length "len_check" builder in
          let error_bb = build_runtime_error_block "Index out of bounds" in
          let cont_bb = L.append_block context "cont" the_function in
          ignore (L.build_cond_br length_check error_bb cont_bb builder);
          let builder = L.builder_at_end context cont_bb in *)
          (* Follow second element pointer, then get index within the allocated heap block *)
          let arr_field_ptr = L.build_struct_gep list_struct_ptr 1 "arr_field_ptr" builder in
          let arr_ptr = L.build_load arr_field_ptr "arr_ptr" builder in
          let element_ptr = L.build_gep arr_ptr [| idx |] "element_ptr" builder in
          L.build_load element_ptr "element" builder
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
      | SCall ("len", [e]) ->
        let le = expr builder e in
          fst (read_list le builder)
      | SCall ("back", [e]) ->
        let le = expr builder e in
        let length, arr_ptr = (read_list le builder) in
        let idx = L.build_sub length (L.const_int i64_t 1) "idx" builder in
        let elem_ptr = L.build_gep arr_ptr [| idx |] "elem_ptr" builder in
        L.build_load elem_ptr "elem_val" builder
      | SCall ("pop_back", [e]) ->
        let le = expr builder e in
        let length, _ = (read_list le builder) in
        let new_len = L.build_sub length (L.const_int i64_t 1) "new_len" builder in
        let list_typ, _ = e in
        slice_list le list_typ (L.const_int i64_t 0) new_len builder
      | SCall ("slice", args) ->
        let args' = List.map (expr builder) args in
        (match args' with
          [l; start_idx; end_idx] ->
            let list_typ, _ = (List.hd args) in
            slice_list l list_typ start_idx end_idx builder
        | _ -> raise (Failure "Invalid slice call")
        )
        | SCall ("append", args) ->
          let args' = List.map (expr builder) args in
        (match args' with
          [l; value] -> append_value_to_list l (fst (List.hd args)) value builder
        | _ -> raise (Failure "Invalid append call"))
      (* | SCall ("range", args) -> 
        let args' = List.map (expr builder) args in
        (match args' with
          [start_idx; end_idx] ->
        | _ -> raise (Failure "Invalid range call")
        ) *)
      | SCall (f, args) ->
         let (fdef, fdecl) = StringMap.find f function_decls in
	        let llargs = List.rev (List.map (expr builder) (List.rev args)) in
	        let result = (match fdecl.styp with 
                        A.Void -> ""
                      | _ -> f ^ "_result") in
         L.build_call fdef (Array.of_list llargs) result builder
      
    in
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
      | SReturn e -> let _ = match fdecl.styp with
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

        (* string * (string * ((string * sexpr) list)) list)*)
        |  SSpawn (_, comp_assigns) ->
            (* NOTE: If member access does not work it is likely because regular values are being
               stored in the field pointers rather than being pointed to *)

            (*Allocate memory entity array *)
            let entity_size = StringMap.cardinal comp_ids in
            let array_size = L.const_int i32_t entity_size in
            let ent_arr_ptr = L.build_array_malloc void_ptr_t array_size "entity_ptr" builder in


            (*Initialize everything in array to null*)
            for i = 0 to entity_size do 
              let null_ptr = L.build_bitcast (L.const_null void_ptr_t) void_ptr_t "void_ptr" builder in
              let idx = L.const_int i32_t i in 
              ignore( L.build_store null_ptr (L.build_gep ent_arr_ptr [| idx |] "element_ptr" builder) builder);
            done;

            (*Initialize a struct for the current component, and return the struct ptr*)
            let init_comp_struct (c_name, mem_assigns) = 
              try 
              
              (*allocate struct memory*)
              (let struct_ty = StringMap.find c_name struct_types in 
              (* let _ = print_endline ("got struct type" ^ L.string_of_lltype struct_ty) in *)
              let _ = L.build_call printf_func [| int_format_str ; L.const_int i64_t entity_size |] "printf" builder in 
              let malloc_result = L.build_alloca struct_ty "mallocResult" builder in
              let _ = L.build_call printf_func [| int_format_str ; L.const_int i64_t entity_size |] "printf" builder in 
              let struct_ptr = L.build_bitcast malloc_result (L.pointer_type struct_ty) "struct_ptr" builder in
              
              (*init all struct fields *)
              let init_mem index (_, e) =
                let field_ptr = L.build_struct_gep struct_ptr index "field_ptr" builder in
                ignore (L.build_store (expr builder e) field_ptr builder); index + 1;
              in
              let _ = List.fold_left init_mem 0 mem_assigns in 
              struct_ptr)              
              with Not_found -> raise (Failure ("Could not find type of struct " ^ c_name))
            in

            (*Initialize components in entity and add to ent list*)
            let add_ent_struct (cname, mem_assigns) = 
              let struct_ptr = init_comp_struct (cname, mem_assigns) in
              let index = StringMap.find cname comp_ids in
              let element_ptr = L.build_gep ent_arr_ptr [|L.const_int i32_t index|] "entity_ptr" builder in
              ignore (L.build_store (L.build_bitcast struct_ptr void_ptr_t "struct_void_ptr" builder) element_ptr builder);
            in

            (*Add entity to registry*)
            let _ = List.map add_ent_struct comp_assigns in 
            let ent_void_ptr_ptr = L.build_bitcast ent_arr_ptr (L.pointer_type void_ptr_t) "struct_void_ptr" builder in
            (* let _ = print_endline "about to call reg_add" in *)
            let _ = L.build_call registry_add_func [| ent_void_ptr_ptr |] "" builder
          in builder
        
            (* in builder *)
        | _ -> raise (Failure "Not implemented")
      (* Implement for loops as while loops! *)
      (*| SFor (e1, e2, e3, body) -> stmt builder
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