module CharMap = Map.Make(struct
    type t = char
    let compare = Char.compare
  end)

include Trie.Make(CharMap)
