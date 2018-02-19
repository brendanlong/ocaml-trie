(** A Map module built on sorted arrays and binary search. It's much, much
   slower to build, but slightly faster to do lookups in (due to better cache
   usage). *)
type key = char
type 'a t = (key * 'a) array

let empty = [||]

let is_empty = function
  | [||] -> true
  | _ -> false

let add key value t =
  let new_element = key, value in
  match t with
  | [||] -> [| new_element |]
  | _ ->
    let len = Array.length t in
    let rec loop i =
      if i = len then
        Array.append t [| new_element |]
      else
        let k, _ = Array.unsafe_get t i in
        if k = key then
          let t = Array.copy t in
          Array.unsafe_set t i (key, value);
          t
        else
          loop (i + 1)
    in
    let t = loop 0 in
    Array.fast_sort (fun (a, _) (b, _) -> Char.compare a b) t;
    t

(* find and remove have very similar code, but deduplicating it into a
   [find_index] function makes [find] about 15% slower. *)
let find key = function
  | [||] -> raise Not_found
  | [| k, v |] ->
    if k = key then
      v
    else
      raise Not_found
  | t ->
    let rec find' min max =
      if min > max then
        raise Not_found
      else
        let i = ((max - min) / 2) + min in
        let k, v = Array.unsafe_get t i in
        let c = Char.compare key k in
        if c = 0 then
          v
        else if c < 0 then
          find' min (i - 1)
        else
          find' (i + 1) max
    in
    find' 0 (Array.length t - 1)

let remove key = function
  | [||] -> empty
  | [| k, _ |]  as t ->
    if k = key then
      empty
    else
      t
  | t ->
    let rec find' min max =
      if min > max then
        raise Not_found
      else
        let i = ((max - min) / 2) + min in
        let k, _ = Array.unsafe_get t i in
        let c = Char.compare key k in
        if c = 0 then
          i
        else if c < 0 then
          find' min (i - 1)
        else
          find' (i + 1) max
    in
    try
      let i = find' 0 (Array.length t - 1) in
      (* Note: Removing a single element leaves the array sorted, so we
         don't need to re-sort here *)
      if i = 0 then
        Array.sub t 1 (Array.length t - 1)
      else if i = Array.length t - 1 then
        Array.sub t 0 (Array.length t - 1)
      else
        let before = Array.sub t 0 i in
        let after = Array.sub t (i + 1) (Array.length t - i - 1) in
        Array.append before after
    with Not_found ->
      t

let fold f t acc =
  Array.fold_left (fun acc (key, value) ->
    f key value acc)
    acc t

let compare cmp a b =
  let len_a = Array.length a in
  let len_b = Array.length b in
  if len_a > len_b then
    -1
  else if len_b > len_a then
    1
  else
    Array.map2 (fun (k1, v1) (k2, v2) ->
      let c = Char.compare k1 k2 in
      if c <> 0 then
        c
      else
        cmp v1 v2)
      a b
    |> Array.fold_left (fun acc c ->
      if acc <> 0 || c = 0 then acc
      else c) 0

let equal equal a b =
  try
    Array.map2 (fun (k1, v1) (k2, v2) ->
      k1 = k2 && equal v1 v2)
      a b
    |> Array.for_all (fun v -> v)
  with Invalid_argument _ ->
    false
