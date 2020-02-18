open Core
open Ast.Ast_types
open Type_data_races_expr
open Desugaring.Desugared_ast
open Type_region_annotations
open Data_race_checker_env
open Type_function_borrowing

let type_data_races_function_defn class_defns function_defns
    (TFunction (func_name, ret_type, params, body_expr)) =
  let open Result in
  type_params_region_annotations class_defns params
  >>= fun () ->
  let error_prefix =
    Fmt.str "Potential data race in function %s " (Function_name.to_string func_name)
  in
  type_function_reverse_borrowing class_defns error_prefix ret_type body_expr
  >>= fun () ->
  type_data_races_block_expr class_defns function_defns body_expr
    (params_to_obj_vars_and_regions class_defns params)
  >>| fun data_race_checked_body_expr ->
  TFunction (func_name, ret_type, params, data_race_checked_body_expr)
