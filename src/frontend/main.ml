open Core
open Compile_program_ir

let get_file_extension filename =
  String.split_on_chars filename ~on:['.'] |> List.last |> Option.value ~default:""

let rec remove_last_elem_list = function
  | []      -> []
  | [_]     -> []
  | x :: xs -> x :: remove_last_elem_list xs

let get_output_file filename =
  String.split_on_chars filename ~on:['.']
  |> fun split_filename ->
  remove_last_elem_list split_filename
  (* remove file ending *)
  |> fun filename_without_ending ->
  String.concat ~sep:"." (filename_without_ending @ ["ir"])

let bolt_file =
  let error_not_file filename =
    eprintf "'%s' is not a bolt file. Hint: use the .bolt extension\n%!" filename ;
    exit 1 in
  Command.Spec.Arg_type.create (fun filename ->
      match Sys.is_file filename with
      | `Yes           ->
          if get_file_extension filename = "bolt" then filename
          else error_not_file filename
      | `No | `Unknown -> error_not_file filename)

let command =
  Command.basic ~summary:"Run bolt programs"
    ~readme:(fun () -> "A list of execution options")
    Command.Let_syntax.(
      let%map_open should_pprint_past =
        flag "-print-parsed-ast" no_arg ~doc:" Pretty print the parsed AST of the program"
      and should_pprint_tast =
        flag "-print-typed-ast" no_arg ~doc:" Pretty print the typed AST of the program"
      and should_pprint_dast =
        flag "-print-desugared-ast" no_arg
          ~doc:" Pretty print the desugared AST of the program"
      and should_pprint_fir =
        flag "-print-frontend-ir" no_arg
          ~doc:" Pretty print the last IR generated by the frontend "
      and _check_data_races =
        flag "-check-data-races" no_arg ~doc:"Check programs for potential data-races"
      and filename = anon (maybe_with_default "-" ("filename" %: bolt_file)) in
      fun () ->
        In_channel.with_file filename ~f:(fun file_ic ->
            let lexbuf =
              Lexing.from_channel file_ic
              (*Create a lex buffer from the file to read in tokens *) in
            compile_program_ir lexbuf ~should_pprint_past ~should_pprint_tast
              ~should_pprint_dast ~should_pprint_fir
              ~compile_out_file:(get_output_file filename)))

let () = Command.run ~version:"1.0" ~build_info:"RWO" command
