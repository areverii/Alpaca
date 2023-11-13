(* Top-level of the Alpaca compiler: scan & parse the input,
   check the resulting AST and generate an SAST from it, generate LLVM IR,
   and dump the module *)

type action = Ast | Compile

let () =
  let action = ref Compile in
  let set_action a () = action := a in
  let speclist = [
    ("-a", Arg.Unit (set_action Ast), "Print the AST (default)");
  ] in  
  let usage_msg = "usage: ./alpaca.native [-a] [file.mc]" in
  let channel = ref stdin in
  Arg.parse speclist (fun filename -> channel := open_in filename) usage_msg;

  (* let lexbuf = Lexing.from_channel !channel in print_string (Scanner.token lexbuf) *)
  let lexbuf = Lexing.from_channel !channel in (*print_endline lexbuf;*)
  let ast = Parser.program Scanner.token lexbuf in  
  print_string (Ast.string_of_program ast)
