module CharMap = Map.Make(struct
    type t = char
    let compare = Char.compare
  end)

module CharTrie = Trie.Make(CharMap)

let trie_of_key_value_list (type a) : (CharTrie.key * a) list -> a CharTrie.t =
  fun l ->
    List.fold_left (fun acc (key, value) ->
      CharTrie.add key value acc)
      CharTrie.empty l

let trie_key =
  QCheck.(list_of_size (Gen.int_range 1 10) char)

let assume_unique_keys (type a) : (CharTrie.key * a) list -> unit =
  fun kv_list ->
    let keys = List.map fst kv_list in
    QCheck.assume (List.length (List.sort_uniq compare keys) = List.length keys)

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

  ; Test.make ~name:"non-empty trie is not empty"
    (list (pair trie_key int64)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    not (CharTrie.is_empty trie))

  ; Test.make ~name:"trie mem all keys"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    List.for_all (fun (key, _) ->
      CharTrie.mem key trie) kv_list)

  ; Test.make ~name:"trie find all keys"
    (list (pair trie_key int64)) (fun kv_list ->
    assume (kv_list <> []);
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    List.for_all (fun (key, value) ->
      CharTrie.find key trie = value) kv_list)

  ; Test.make ~name:"trie minus first key is not equal"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie1 = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie2 = CharTrie.remove key trie1 in
    not (CharTrie.equal (=) trie1 trie2))

  ; Test.make ~name:"trie minus first key compares <> original trie"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie1 = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie2 = CharTrie.remove key trie1 in
    CharTrie.compare compare trie1 trie2 <> 0
    && CharTrie.compare compare trie2 trie1 <> 0)

  ; Test.make ~name:"trie minus first key compare is ordered"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie1 = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie2 = CharTrie.remove key trie1 in
    CharTrie.compare compare trie1 trie2
    <> CharTrie.compare compare trie2 trie1)

  ; Test.make ~name:"trie without first key not mem first key"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie = CharTrie.remove key trie in
    not (CharTrie.mem key trie))

  ; Test.make ~name:"trie without first key not find first key"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie = CharTrie.remove key trie in
    try
      ignore (CharTrie.find key trie);
      false
    with Not_found -> true)

  ; Test.make ~name:"same trie is equal"
    (list (pair trie_key int)) (fun kv_list ->
    let trie1 = trie_of_key_value_list kv_list in
    let trie2 = trie_of_key_value_list kv_list in
    CharTrie.equal (=) trie1 trie2)

  ; Test.make ~name:"same trie compares equal"
    (list (pair trie_key string)) (fun kv_list ->
    let trie1 = trie_of_key_value_list kv_list in
    let trie2 = trie_of_key_value_list kv_list in
    CharTrie.compare String.compare trie1 trie2 = 0)

  ; Test.make ~name:"list -> trie -> list (using fold) is same list"
    (list (pair trie_key string)) (fun kv_list ->
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    let l =
      CharTrie.fold (fun key value acc ->
        (key, value) :: acc) trie []
      |> List.sort compare
    in
    List.sort compare kv_list = l)

  ; Test.make ~name:"list -> trie -> list (using iter) is same list"
    (list (pair trie_key string)) (fun kv_list ->
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    let l = ref [] in
    CharTrie.iter (fun key value ->
      l := (key, value) :: !l) trie;
    let l = List.sort compare !l in
    List.sort compare kv_list = l)

  ; Test.make ~name:"Trie.map add int"
    (pair (list (pair trie_key int)) small_int) (fun (kv_list, n) ->
    assume_unique_keys kv_list;
    let actual =
      let trie =
        trie_of_key_value_list kv_list
        |> CharTrie.map ((+) n)
      in
      CharTrie.fold (fun key value acc ->
        (key, value) :: acc) trie []
      |> List.sort compare
    in
    let expect =
      List.map (fun (k, v) -> k, v + n) kv_list
      |> List.sort compare
    in
    expect = actual)

  ; Test.make ~name:"Trie.mapi minus key len"
    (list (pair trie_key int)) (fun kv_list ->
    assume_unique_keys kv_list;
    let actual =
      let trie =
        trie_of_key_value_list kv_list
        |> CharTrie.mapi (fun key v ->
          v - List.length key)
      in
      CharTrie.fold (fun key value acc ->
        (key, value) :: acc) trie []
      |> List.sort compare
    in
    let expect =
      List.map (fun (k, v) -> k, v - List.length k) kv_list
      |> List.sort compare
    in
    expect = actual) ]

let () =
  QCheck_runner.run_tests_main suite
