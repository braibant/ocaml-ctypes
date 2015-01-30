(*
 * Copyright (c) 2014 Jeremy Yallop.
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

(* C stub customization options. These options are documented in
   [Cstubs_inverted]. *)

type inverted_stubs_options =
  {
    (* will wrap [caml_release_runtime_system] and
       [caml_acquire_runtime_system] around callbacks.*)
    use_runtime_system_lock: bool;

    (* will call [caml_c_thread_register] in the prelude of each
       function. *)
    use_register_thread: bool;
  }

(* C stub generation *)

val fn : cname:string -> stub_name:string -> Format.formatter ->
         'a Ctypes.fn -> unit

val value : cname:string -> stub_name:string -> Format.formatter ->
         'a Ctypes.typ -> unit

val inverse_fn : ?options:inverted_stubs_options -> stub_name:string -> Format.formatter ->
         'a Ctypes.fn -> unit

val inverse_fn_decl : stub_name:string -> Format.formatter ->
         'a Ctypes.fn -> unit
