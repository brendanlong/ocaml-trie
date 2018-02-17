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

let trie_key_with_size max =
  QCheck.(list_of_size (Gen.int_bound max) char)

let trie_key = trie_key_with_size 10

let medium_list x =
  QCheck.(list_of_size (Gen.int_bound 100) x)

let list_values_are_unique l =
  List.length (List.sort_uniq compare l) = List.length l

let assume_unique_keys (type a) : (CharTrie.key * a) list -> unit =
  fun kv_list ->
    let keys = List.map fst kv_list in
    QCheck.assume (list_values_are_unique keys)

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

  ; Test.make ~name:"map add int"
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

  ; Test.make ~name:"mapi minus key len"
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
    expect = actual)

  ; Test.make ~name:"keys"
    (list (pair trie_key int)) (fun kv_list ->
    assume_unique_keys kv_list;
    let actual =
      trie_of_key_value_list kv_list
      |> CharTrie.keys
      |> List.sort compare
    in
    let expect =
      List.map fst kv_list
      |> List.sort compare
    in
    expect = actual)

  ; Test.make ~name:"data"
    (list (pair trie_key int)) (fun kv_list ->
    assume_unique_keys kv_list;
    let actual =
      trie_of_key_value_list kv_list
      |> CharTrie.data
      |> List.sort compare
    in
    let expect =
      List.map snd kv_list
      |> List.sort compare
    in
    expect = actual)

  ; Test.make ~name:"find_approximate finds nothing in empty trie"
    (pair trie_key small_int) (fun (key, max_differences) ->
    CharTrie.(find_approximate ~max_differences key empty) = [])

  ; Test.make ~name:"find_approximate ~max_differences:0 = find"
    (list (pair trie_key int)) (fun kv_list ->
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    List.for_all (fun (key, value) ->
      CharTrie.find_approximate ~max_differences:0 key trie = [value])
      kv_list)

  ; Test.make ~name:"find_approximate >= find"
    (pair (medium_list (pair trie_key int)) (int_bound 5))
    (fun (kv_list, max_differences) ->
      assume_unique_keys kv_list;
      let trie = trie_of_key_value_list kv_list in
      List.for_all (fun (key, value) ->
        let found = CharTrie.find_approximate ~max_differences key trie in
        List.mem value found)
        kv_list)

  ; Test.make ~name:"find_approximate missing prefix"
    (pair (medium_list (trie_key_with_size 6)) (int_range 1 5))
    (fun (key_list, drop_prefix) ->
      List.iter (fun key -> assume (List.length key >= drop_prefix)) key_list;
      let kv_list = List.map (fun key -> key, key) key_list in
      assume_unique_keys kv_list;
      let trie = trie_of_key_value_list kv_list in
      List.for_all (fun (key, value) ->
        let key = 
          let a = Array.of_list key in
          Array.sub a drop_prefix ((Array.length a) - drop_prefix)
          |> Array.to_list
        in
        let found = CharTrie.find_approximate ~max_differences:drop_prefix key
            trie in
        List.mem value found)
        kv_list)

  ; Test.make ~name:"find_approximate missing suffix"
    (pair (medium_list (trie_key_with_size 6)) (int_range 1 5))
    (fun (key_list, drop_prefix) ->
      List.iter (fun key -> assume (List.length key >= drop_prefix)) key_list;
      let kv_list = List.map (fun key -> key, key) key_list in
      assume_unique_keys kv_list;
      let trie = trie_of_key_value_list kv_list in
      List.for_all (fun (key, value) ->
        let key =
          let a = Array.of_list key in
          Array.sub a 0 ((Array.length a) - drop_prefix)
          |> Array.to_list
        in
        let found = CharTrie.find_approximate ~max_differences:drop_prefix key
            trie in
        List.mem value found)
        kv_list)

  ; Test.make ~name:"find_approximate random changes"
    (pair (medium_list (trie_key_with_size 6))
       (list_of_size (Gen.int_range 0 5) (int_range 0 4)))
    (fun (key_list, change_indexes) ->
      let kv_list = List.map (fun key -> key, key) key_list in
      assume_unique_keys kv_list;
      let max_differences = List.length change_indexes in
      let trie = trie_of_key_value_list kv_list in
      List.for_all (fun (key, value) ->
        let key =
          let a = Array.of_list key in
          List.iter (fun i ->
            assume (Array.length a > i);
            Array.set a i 'x')
            change_indexes;
          Array.to_list a
        in
        let found = CharTrie.find_approximate ~max_differences key trie in
        List.mem value found)
        kv_list) ]

let () =
  QCheck_runner.run_tests_main suite
