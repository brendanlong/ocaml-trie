module Char_map = Map.Make(Char)

include Trie.Make(struct
    type key = char
    type 'a t = (key * 'a) list

    let empty = []

    let is_empty = function
      | [] -> true
      | _ -> false

    let rec add key value = function
      | [] -> [ key, value ]
      | (exist_key, exist_value) :: rest ->
        if exist_key = key then
          (key, value) :: rest
        else
          (exist_key, exist_value) :: add key value rest

    let rec find key = function
      | [] -> raise Not_found
      | (k, value) :: rest ->
        if k = key then
          value
        else
          find key rest

    let rec remove key = function
      | [] -> []
      | (exist_key, exist_value) :: rest ->
        if exist_key = key then
          rest
        else
          (exist_key, exist_value) :: remove key rest

    let rec fold f t acc =
      match t with
      | [] -> acc
      | (key, value) :: rest ->
        f key value acc
        |> fold f rest

    let compare (cmp : 'a -> 'a -> int) (a : 'a t) (b : 'a t) =
      let cmp_el (k1, v1) (k2, v2) =
        let c = Char.compare k1 k2 in
        if c = 0 then
          cmp v1 v2
        else
          c
      in
      let a = List.sort cmp_el a in
      let b = List.sort cmp_el b in
      let rec compare' = function
        | [], [] -> 0
        | (a :: a_rest), (b :: b_rest) ->
          let c = cmp_el a b in
          if c = 0 then
            compare' (a_rest, b_rest)
          else
            c
        | _ :: _ , [] -> -1
        | [], _ :: _ -> 1
      in
      compare' (a, b)

    let equal _equal _a _b =
      assert false
  end)
