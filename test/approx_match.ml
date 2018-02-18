(* A CLI program to read the lines of a file into a trie and then lookup
   words with approximate matches. *)
open Printf

module CharMap = Map.Make(struct
    type t = char
    let compare = Char.compare
  end)

module CharTrie = Trie.Make(CharMap)

let string_to_list s =
  let a = Array.make (String.length s) ' ' in
  String.iteri (fun i c ->
    Array.set a i c)
    s;
  Array.to_list a

let () =
  match Sys.argv with
  | [| _ ; filename |] ->
    let lines =
      let f = Unix.openfile filename [Unix.O_RDONLY] 0 in
      (try
        let { Unix.st_size ; _ } = Unix.fstat f in
        let buf = Bytes.create st_size in
        let i = ref 0 in
        while !i < st_size do
          let read = Unix.read f buf !i (st_size - !i) in
          i := !i + read
        done;
        Unix.close f;
        Bytes.to_string buf
      with e ->
        Unix.close f;
        raise e)
      |> String.split_on_char '\n'
    in
    let trie =
      List.fold_left (fun acc line ->
        let key = string_to_list line in
        CharTrie.add key line acc)
        CharTrie.empty
        lines
    in
    while true do
      print_string "search word? ";
      let word = read_line () in
      print_string "max differences? ";
      let max_differences = read_line () in
      try
        let max_differences = int_of_string max_differences in
        let matches =
          let key = string_to_list word in
          CharTrie.find_approximate ~max_differences key trie
          |> List.sort_uniq compare
        in
        String.concat "\n" matches
        |> printf "matches: \n%s\n"
      with Failure e ->
        eprintf "%s\n" e
    done
  | args ->
    Array.get args 0
    |> eprintf "Usage: %s [word file name]";
    exit 1
