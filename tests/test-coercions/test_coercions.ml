(*
 * Copyright (c) 2013 Jeremy Yallop.
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

open OUnit
open Ctypes


(* 
   Check coercions between pointers.
*)
let test_pointer_coercions () =
  let module M = struct
    type boxed_type = T : 'a typ -> boxed_type
    let types = [
      T void;
      T int8_t;
      T uint16_t;
      T int;
      T float;
      T short;
      T complex64;
      T (ptr double);
      T string;
      T (bigarray array1 10 Bigarray.int32);
      T (array 5 int32_t);
      T (structure "s");
      T (union "u");
      T (abstract ~name:"a" ~size:12 ~alignment:4);
    ]

    (* Check that we can construct a coercion between any two pointer types *)
    let () = ListLabels.iter2 types types
      ~f:(fun (T t1) (T t2) -> let _ = coerce (ptr t1) (ptr t2) in ())

    (* Check that pointer coercions are value-preserving. *)
    let v = 10
    let p = allocate int v
    let p' = coerce (ptr float) (ptr int) (coerce (ptr int) (ptr float) p)

    let () = assert_equal p p'
  end in ()


(*
  Check that coercions between a pointer to a struct and a pointer to
  its first member succeed.
*)
let test_struct_first_member_coercions () =
  let module M = struct
    let s = structure "s"
    let f = field s "f" double
    let i = field s "i" int
    let () = seal s

    let () = begin
      let v = make s in
      let p = coerce (ptr s) (ptr double) (addr v) in

      setf v f 5.5;
      assert_equal !@p 5.5;

      p <-@ 6.6;
      assert_equal (getf v f) 6.6
    end
  end in ()


(* 
   Check that coercions between a pointer to a union and a pointer to
   a member succeed.
*)
let test_union_coercions () =
  let module M = struct
    let u = union "u"
    let f = field u "f" double
    let i = field u "i" int
    let () = seal u

    let () = begin
      let v = make u in
      let pf = coerce (ptr u) (ptr double) (addr v) in
      let pi = coerce (ptr u) (ptr int) (addr v) in

      setf v f 5.5;
      assert_equal !@pf 5.5;

      pi <-@ 12;
      assert_equal (getf v i) 12;

      setf v i 14;
      assert_equal !@pi 14;
      
      pf <-@ 6.6;
      assert_equal (getf v f) 6.6;
    end

  end in ()


(* 
   Check coercions between views.
*)
let test_view_coercions () =
  let module M = struct
    type 'a variant = V of 'a
    let unV (V v) = v and inV v = V v
    let variant_view v = view v ~read:inV ~write:unV

    type 'a record = { r : 'a }
    let record_view v = view v
      ~read:(fun r -> {r})
      ~write:(fun {r} -> r)
      
    let pintvv = variant_view (variant_view (ptr int))
    let pintr = record_view (ptr int)
      
    let () = begin
      let pi = allocate int 100 in
      let v = allocate pintvv (V (V pi)) in

      assert_equal
        !@((coerce pintvv pintr !@v).r)
        100
    end

  end in ()


(* 
   Check that coercions between unsupported types raise an exception
*)
let test_unsupported_coercions () =
  let module M = struct
    type boxed_type = T : 'a typ -> boxed_type
    let types = [
      T int8_t;
      T uint16_t;
      T int;
      T float;
      T short;
      T complex64;
      T (bigarray array1 10 Bigarray.int32);
      T (array 5 int32_t);
      T (structure "s");
      T (union "u");
      T (abstract ~name:"a" ~size:12 ~alignment:4);
    ]

    (* None of the types in the list are currently intercoercible. *)
    let () = ListLabels.iter2 types types
      ~f:(fun (T t1) (T t2) -> 
        assert_raises Uncoercible
          (fun () -> coerce t1 t2))
  end in ()


let suite = "Coercsion tests" >:::
  ["test pointer coercions"
    >:: test_pointer_coercions;

   "test struct first member coercions"
    >:: test_struct_first_member_coercions;

   "test union coercions"
    >:: test_union_coercions;

   "test view coercions"
    >:: test_view_coercions;

   "test unsupported coercions"
    >:: test_unsupported_coercions;
  ]


let _ =
  run_test_tt_main suite
