module Char_map = Map.Make(Char)

include Trie.Make(Char_map)
