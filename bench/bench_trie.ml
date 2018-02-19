open Core
open Core_bench

let naive_search ~max_differences key =
  List.filter ~f:(fun candidate ->
    Levenshtein.String.distance
      ~upper_bound:max_differences candidate key <= max_differences)

let () =
  let strings =
    let state = Caml.Random.State.make_self_init () in
    let string_gen = QCheck.(printable_string_of_size Gen.(int_bound 37)) in
    List.init 1000 ~f:(fun _ ->
      string_gen.gen state |> String.lowercase)
  in
  let lookup_strings = Array.of_list strings in
  let random_key () =
    let i = Random.int (Array.length lookup_strings - 1) in
    Array.get lookup_strings i
  in
  let kv_list = List.map strings ~f:(fun key -> key, ()) in
  let map = String.Map.of_alist_multi kv_list in
  let hash_table = String.Table.of_alist_multi kv_list in
  let trie = List.fold kv_list ~init:Char_trie.empty
      ~f:(fun acc (key, value) ->
        let key = String.to_list key in
        Char_trie.add key value acc)
  in
  let array_trie = List.fold kv_list ~init:Array_char_trie.empty
      ~f:(fun acc (key, value) ->
        let key = String.to_list key in
        Array_char_trie.add key value acc)
  in
  [ Bench.Test.create ~name:"populate map"
      (fun () ->
        String.Map.of_alist_multi kv_list)
  ; Bench.Test.create ~name:"populate hash table"
      (fun () ->
        String.Table.of_alist_multi kv_list)
  ; Bench.Test.create ~name:"populate trie"
    (fun () ->
      List.fold kv_list ~init:Char_trie.empty ~f:(fun acc (key, value) ->
        let key = String.to_list key in
        Char_trie.add key value acc))
  ; Bench.Test.create ~name:"populate array trie"
    (fun () ->
      List.fold kv_list ~init:Array_char_trie.empty ~f:(fun acc (key, value) ->
        let key = String.to_list key in
        Array_char_trie.add key value acc))
  ; Bench.Test.create ~name:"lookup keys map"
    (fun () ->
      random_key ()
      |> Map.find map)
  ; Bench.Test.create ~name:"lookup keys hash table"
    (fun () ->
      random_key ()
      |> String.Table.find hash_table)
  ; Bench.Test.create ~name:"lookup keys trie"
    (fun () ->
      let key =
        random_key ()
        |> String.to_list
      in
      Char_trie.find key trie)
  ; Bench.Test.create ~name:"lookup keys array trie"
    (fun () ->
      let key =
        random_key ()
        |> String.to_list
      in
      Array_char_trie.find key array_trie)
  ; Bench.Test.create_indexed ~args:[ 0 ; 1 ; 2 ; 3 ]
    ~name:"find_approximate trie ~max_differences"
    (fun max_differences ->
      stage (fun () ->
        let key =
          random_key ()
          |> String.to_list
        in
        Char_trie.find_approximate ~max_differences key trie))
  ; Bench.Test.create_indexed ~args:[ 0 ; 1 ; 2 ; 3 ]
    ~name:"find_approximate array trie ~max_differences"
    (fun max_differences ->
      stage (fun () ->
        let key =
          random_key ()
          |> String.to_list
        in
        Array_char_trie.find_approximate ~max_differences key array_trie))
  ; Bench.Test.create_indexed ~args:[ 0 ; 1 ; 2 ; 3 ]
    ~name:"find_approximate naive ~max_differences"
    (fun max_differences ->
      stage (fun () ->
        let key =
          random_key ()
        in
        naive_search ~max_differences:0 key strings)) ]
  |> Bench.make_command
  |> Command.run
