module CharMap = Map.Make(struct
    type t = char
    let compare = Char.compare
  end)

module CharTrie = Trie.Make(CharMap)

let suite =
  let open QCheck in
  [ Test.make ~name:"empty trie is empty"
      ~count:1 unit (fun () -> CharTrie.(is_empty empty))
  ; Test.make ~name: "empty trie mem always false"
      (list char) (fun key -> not CharTrie.(mem key empty))
  ; Test.make ~name:"empty trie find always raises"
    (list char) (fun key ->
    try
      ignore CharTrie.(find key empty);
      false
    with Not_found -> true)
  ; Test.make ~name:"empty trie remove returns empty trie"
    (list char) (fun key ->
    CharTrie.(remove key empty |> equal (=) empty))
  ; Test.make ~name:"same trie is equal"
    (list (pair (small_list char) int)) (fun kv_list ->
    let make_trie () =
      List.fold_left (fun acc (key, value) ->
        CharTrie.add key value acc)
        CharTrie.empty kv_list
    in
    let trie1 = make_trie () in
    let trie2 = make_trie () in
    CharTrie.equal (=) trie1 trie2)
  ; Test.make ~name:"same trie compares equal"
    (list (pair (small_list char) string)) (fun kv_list ->
    let make_trie () =
      List.fold_left (fun acc (key, value) ->
        CharTrie.add key value acc)
        CharTrie.empty kv_list
    in
    let trie1 = make_trie () in
    let trie2 = make_trie () in
    CharTrie.compare String.compare trie1 trie2 = 0) ]

let () =
  QCheck_runner.run_tests_main suite
