module Char_map = Map.Make(Char)

include Trie.Make(struct
    type key = char
    type 'a t =
      | None
      | One of key * 'a
      | Many of 'a Char_map.t

    let empty = None

    let is_empty = function
      | None -> true
      | _ -> false

    let add key value = function
      | None -> One (key, value)
      | One (exist_key, exist_value) ->
        Many (Char_map.empty
              |> Char_map.add exist_key exist_value
              |> Char_map.add key value)
      | Many m ->
        Many (Char_map.add key value m)

    let find key = function
      | None -> raise Not_found
      | One (k, v) ->
        if k <> key then
          raise Not_found
        else
          v
      | Many m -> Char_map.find key m

    let remove key = function
      | One (k, _) when k = key -> None
      | Many m ->
        let m = Char_map.remove key m in
        if Char_map.is_empty m then
          None
        else if Char_map.cardinal m = 1 then
          let key, value = Char_map.choose m in
          One (key, value)
        else
          Many m
      | t -> t

    let fold f t acc =
      match t with
      | None -> acc
      | One (key, value) -> f key value acc
      | Many m -> Char_map.fold f m acc

    let compare (cmp : 'a -> 'a -> int) a b =
      match a, b with
      | None, None -> 0
      | None, One _ -> 1
      | One _, None -> -1
      | None, Many _ -> 1
      | Many _, None -> -1
      | One _, Many _ -> 1
      | Many _, One _ -> -1
      | One (k1, v1), One (k2, v2) ->
        let c = Char.compare k1 k2 in
        if c = 0 then
          cmp v1 v2
        else c
      | Many a, Many b ->
        Char_map.compare cmp a b

    let equal equal a b =
      match a, b with
      | None, None -> true
      | One (k1, v1), One (k2, v2) when k1 = k2 && equal v1 v2 -> true
      | Many a, Many b -> Char_map.equal equal a b
      | _ -> false
  end)
