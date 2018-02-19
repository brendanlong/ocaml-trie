let medium_list x =
  QCheck.(list_of_size (Gen.int_bound 100) x)

let list_values_are_unique l =
  List.length (List.sort_uniq compare l) = List.length l

let assume_unique_keys (type a) : (char list * a) list -> unit =
  fun kv_list ->
    let keys = List.map fst kv_list in
    QCheck.assume (list_values_are_unique keys)

let make_tests m =
  let module Char_trie = (val m : Trie.S with type key = char list) in
  let trie_of_key_value_list (type a) : (Char_trie.key * a) list -> a Char_trie.t =
    fun l ->
      List.fold_left (fun acc (key, value) ->
        Char_trie.add key value acc)
        Char_trie.empty l
  in
  let trie_key_with_size max =
    QCheck.(list_of_size (Gen.int_bound max) char)
  in
  let trie_key = trie_key_with_size 10 in
  let open QCheck in
  [ Test.make ~name:"empty trie is empty"
      ~count:1 unit (fun () -> Char_trie.(is_empty empty))

  ; Test.make ~name: "empty trie mem always false"
      (list char) (fun key -> not Char_trie.(mem key empty))

  ; Test.make ~name:"empty trie find always raises"
    (list char) (fun key ->
    try
      ignore Char_trie.(find key empty);
      false
    with Not_found -> true)

  ; Test.make ~name:"empty trie remove returns empty trie"
    (list char) (fun key ->
    Char_trie.(remove key empty |> equal (=) empty))

  ; Test.make ~name:"non-empty trie is not empty"
    (list (pair trie_key int64)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    not (Char_trie.is_empty trie))

  ; Test.make ~name:"trie mem all keys"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    List.for_all (fun (key, _) ->
      Char_trie.mem key trie) kv_list)

  ; Test.make ~name:"trie find all keys"
    (list (pair trie_key int64)) (fun kv_list ->
    assume (kv_list <> []);
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    List.for_all (fun (key, value) ->
      Char_trie.find key trie = value) kv_list)

  ; Test.make ~name:"trie minus first key is not equal"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie1 = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie2 = Char_trie.remove key trie1 in
    not (Char_trie.equal (=) trie1 trie2))

  ; Test.make ~name:"trie minus first key compares <> original trie"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie1 = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie2 = Char_trie.remove key trie1 in
    Char_trie.compare compare trie1 trie2 <> 0
    && Char_trie.compare compare trie2 trie1 <> 0)

  ; Test.make ~name:"trie minus first key compare is ordered"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie1 = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie2 = Char_trie.remove key trie1 in
    Char_trie.compare compare trie1 trie2
    <> Char_trie.compare compare trie2 trie1)

  ; Test.make ~name:"trie without first key not mem first key"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie = Char_trie.remove key trie in
    not (Char_trie.mem key trie))

  ; Test.make ~name:"trie without first key not find first key"
    (list (pair trie_key bool)) (fun kv_list ->
    assume (kv_list <> []);
    let trie = trie_of_key_value_list kv_list in
    let (key, _) = List.hd kv_list in
    let trie = Char_trie.remove key trie in
    try
      ignore (Char_trie.find key trie);
      false
    with Not_found -> true)

  ; Test.make ~name:"same trie is equal"
    (list (pair trie_key int)) (fun kv_list ->
    let trie1 = trie_of_key_value_list kv_list in
    let trie2 = trie_of_key_value_list kv_list in
    Char_trie.equal (=) trie1 trie2)

  ; Test.make ~name:"same trie compares equal"
    (list (pair trie_key string)) (fun kv_list ->
    let trie1 = trie_of_key_value_list kv_list in
    let trie2 = trie_of_key_value_list kv_list in
    Char_trie.compare String.compare trie1 trie2 = 0)

  ; Test.make ~name:"list -> trie -> list (using fold) is same list"
    (list (pair trie_key string)) (fun kv_list ->
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    let l =
      Char_trie.fold (fun key value acc ->
        (key, value) :: acc) trie []
      |> List.sort compare
    in
    List.sort compare kv_list = l)

  ; Test.make ~name:"list -> trie -> list (using iter) is same list"
    (list (pair trie_key string)) (fun kv_list ->
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    let l = ref [] in
    Char_trie.iter (fun key value ->
      l := (key, value) :: !l) trie;
    let l = List.sort compare !l in
    List.sort compare kv_list = l)

  ; Test.make ~name:"map add int"
    (pair (list (pair trie_key int)) small_int) (fun (kv_list, n) ->
    assume_unique_keys kv_list;
    let actual =
      let trie =
        trie_of_key_value_list kv_list
        |> Char_trie.map ((+) n)
      in
      Char_trie.fold (fun key value acc ->
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
        |> Char_trie.mapi (fun key v ->
          v - List.length key)
      in
      Char_trie.fold (fun key value acc ->
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
      |> Char_trie.keys
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
      |> Char_trie.data
      |> List.sort compare
    in
    let expect =
      List.map snd kv_list
      |> List.sort compare
    in
    expect = actual)

  ; Test.make ~name:"find_approximate finds nothing in empty trie"
    (pair trie_key small_int) (fun (key, max_differences) ->
    Char_trie.(find_approximate ~max_differences key empty) = [])

  ; Test.make ~name:"find_approximate ~max_differences:0 = find"
    (list (pair trie_key int)) (fun kv_list ->
    assume_unique_keys kv_list;
    let trie = trie_of_key_value_list kv_list in
    List.for_all (fun (key, value) ->
      Char_trie.find_approximate ~max_differences:0 key trie = [value])
      kv_list)

  ; Test.make ~name:"find_approximate >= find"
    (pair (medium_list (pair trie_key int)) (int_bound 5))
    (fun (kv_list, max_differences) ->
      assume_unique_keys kv_list;
      let trie = trie_of_key_value_list kv_list in
      List.for_all (fun (key, value) ->
        let found = Char_trie.find_approximate ~max_differences key trie in
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
        let found = Char_trie.find_approximate ~max_differences:drop_prefix key
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
        let found = Char_trie.find_approximate ~max_differences:drop_prefix key
            trie in
        List.mem value found)
        kv_list)

  ; Test.make ~name:"find_approximate random changes"
    (pair (medium_list (trie_key_with_size 6))
       (list_of_size (Gen.int_range 0 5) (int_range 0 4)))
    (fun (key_list, change_indexes) ->
      assume (list_values_are_unique change_indexes);
      let kv_list = List.map (fun key -> key, key) key_list in
      assume_unique_keys kv_list;
      let max_differences = List.length change_indexes in
      let trie = trie_of_key_value_list kv_list in
      List.for_all (fun (key, value) ->
        let key =
          let a = Array.of_list key in
          List.iter (fun i ->
            assume (Array.length a > i);
            let replace_with =
              match Array.get a i with
              | 'x' -> 'y'
              | _ -> 'x'
            in
            Array.set a i replace_with)
            change_indexes;
          Array.to_list a
        in
        let found = Char_trie.find_approximate ~max_differences key trie in
        List.mem value found)
        kv_list)

  ; Test.make ~name:"find_approximate missing prefix too many differences"
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
        let found = Char_trie.find_approximate
            ~max_differences:(drop_prefix - 1) key trie in
        not (List.mem value found))
        kv_list)

  ; Test.make ~name:"find_approximate missing suffix too many differences"
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
        let found = Char_trie.find_approximate
            ~max_differences:(drop_prefix - 1) key trie in
        not (List.mem value found))
        kv_list)

  ; Test.make ~name:"find_approximate random changes too many differences"
    (pair (medium_list (trie_key_with_size 6))
       (list_of_size (Gen.int_range 0 5) (int_range 0 4)))
    (fun (key_list, change_indexes) ->
      assume (not (List.exists (fun key -> key = []) key_list));
      assume (change_indexes <> []);
      assume (list_values_are_unique change_indexes);
      let kv_list = List.map (fun key -> key, key) key_list in
      assume_unique_keys kv_list;
      let max_differences = (List.length change_indexes) - 1 in
      let trie = trie_of_key_value_list kv_list in
      List.for_all (fun (key, value) ->
        let key =
          let a = Array.of_list key in
          List.iter (fun i ->
            assume (Array.length a > i);
            let replace_with =
              match Array.get a i with
              | 'x' -> 'y'
              | _ -> 'x'
            in
            Array.set a i replace_with)
            change_indexes;
          Array.to_list a
        in
        let found = Char_trie.find_approximate ~max_differences key trie in
        not (List.mem value found))
        kv_list) ]

let () =
  let tests =
    [ (module Char_trie : Trie.S with type key = char list)
    ; (module Array_char_trie : Trie.S with type key = char list) ]
    |> List.map make_tests
    |> List.concat
  in
  QCheck_runner.run_tests_main tests
