open OUnit2

module CharMap = Map.Make(struct
    type t = char
    let compare = Char.compare
  end)

module CharTrie = Trie.Make(CharMap)

let () =
  [ "empty" >:: fun _ ->
      let trie = CharTrie.empty in
      CharTrie.is_empty trie
      |> assert_bool "empty trie is empty";
      assert_raises ~msg:"empty trie can't find 'a'" Not_found (fun () ->
        CharTrie.find ['a'] trie);
      assert_bool "empty trie can't mem 'a'"
        (not (CharTrie.mem ['a'] trie));
      assert_bool "empty trie equals empty trie"
        (CharTrie.equal Char.equal trie trie);
      assert_equal ~msg:"empty trie compares equals with empty trie" 0
        (CharTrie.compare Char.compare trie trie) ]
  |> test_list
  |> run_test_tt_main
