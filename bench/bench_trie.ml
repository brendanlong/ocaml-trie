open Core
open Core_bench

let () =
  let strings =
    let state = Caml.Random.State.make_self_init () in
    let string_gen = QCheck.small_printable_string in
    List.init 500 ~f:(fun _ ->
      string_gen.gen state, ())
  in
  let map = String.Map.of_alist_multi strings in
  let hash_table = String.Table.of_alist_multi strings in
  let trie = List.fold strings ~init:Char_trie.empty ~f:(fun acc (key, value) ->
      let key = String.to_list key in
      Char_trie.add key value acc)
  in
  [ Bench.Test.create ~name:"populate map"
      (fun () ->
        String.Map.of_alist_multi strings)
  ; Bench.Test.create ~name:"populate hash table"
      (fun () ->
        String.Table.of_alist_multi strings)
  ; Bench.Test.create ~name:"populate trie"
    (fun () ->
      List.fold strings ~init:Char_trie.empty ~f:(fun acc (key, value) ->
        let key = String.to_list key in
        Char_trie.add key value acc))
  ; Bench.Test.create ~name:"lookup keys in map"
    (fun () ->
      List.map strings ~f:(fun (key, _) ->
        Map.find map key))
  ; Bench.Test.create ~name:"lookup keys in mash table"
    (fun () ->
      List.map strings ~f:(fun (key, _) ->
        String.Table.find hash_table key))
  ; Bench.Test.create ~name:"lookup keys in trie"
    (fun () ->
      List.map strings ~f:(fun (key, _) ->
        let key = String.to_list key in
        Char_trie.find key trie))
  ; Bench.Test.create ~name:"lookup keys with find_approximate ~max_differences:0 in trie"
    (fun () ->
      List.map strings ~f:(fun (key, _) ->
        let key = String.to_list key in
        Char_trie.find_approximate ~max_differences:0 key trie))
  ; Bench.Test.create ~name:"lookup keys with find_approximate ~max_differences:1 in trie"
    (fun () ->
      List.map strings ~f:(fun (key, _) ->
        let key = String.to_list key in
        Char_trie.find_approximate ~max_differences:1 key trie))
  ; Bench.Test.create ~name:"lookup keys with find_approximate ~max_differences:2 in trie"
    (fun () ->
      List.map strings ~f:(fun (key, _) ->
        let key = String.to_list key in
        Char_trie.find_approximate ~max_differences:2 key trie))
  ; Bench.Test.create ~name:"lookup keys with find_approximate ~max_differences:3 in trie"
    (fun () ->
      List.map strings ~f:(fun (key, _) ->
        let key = String.to_list key in
        Char_trie.find_approximate ~max_differences:3 key trie)) ]
  |> Bench.make_command
  |> Command.run
