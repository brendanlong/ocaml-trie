(**

   Levenshtein distance algorithm for general array.

   Author: jun.furuse@gmail.com
   License: public domain

*)

(** Minimum of three integers *)
let min3 (x:int) y z =
  let m' (a:int) b = if a < b then a else b in
  m' (m' x y) z

module type S = sig
  type t
  val distance : ?upper_bound: int -> t -> t -> int
  (** Calculate Levenshtein distance of 2 t's *)
end

module type Array = sig
  type t
  type elem
  val compare : elem -> elem -> int
  val get : t -> int -> elem
  val size : t -> int
end

module Make(A : Array) = struct

  type t = A.t

  (* slow_but_simple + memoization + upperbound

     There is a property: d(i-1)(j-1) <= d(i)(j)
     so if d(i-1)(j-1) >= upper_bound then we can immediately say
     d(i)(j) >= upper_bound, and skip the calculation of d(i-1)(j) and d(i)(j-1)
  *)
  let distance ?(upper_bound=max_int) xs ys =
    let size_xs = A.size xs
    and size_ys = A.size ys in
    (* cache: d i j is stored at cache.(i-1).(j-1) *)
    let cache = Array.init size_xs (fun _ -> Array.make size_ys (-1)) in
    let rec d i j =
      match i, j with
      | 0, _ -> j
      | _, 0 -> i
      | _ ->
          let i' = i - 1 in
          let cache_i = Array.unsafe_get cache i' in
          let j' = j - 1 in
          match Array.unsafe_get cache_i j' with
          | -1 ->
              let res =
                let upleft = d i' j' in
                if upleft >= upper_bound then upper_bound
                else
                  let cost = abs (A.compare (A.get xs i') (A.get ys j')) in
                  let upleft' = upleft + cost in
                  if upleft' >= upper_bound then upper_bound
                  else
                    (* This is not tail recursive *)
                    min3 (d i' j + 1)
                         (d i j' + 1)
                         upleft'
              in
              Array.unsafe_set cache_i j' res;
              res
          | res -> res
    in
    min (d size_xs size_ys) upper_bound
end

(** With inter-query cache by hashtbl *)

module type Cache = sig
  type 'a t
  type key
  val create : int -> 'a t
  val alter : 'a t -> key -> ('a option -> 'a option) -> 'a option
end

type result =
  | Exact of int
  | GEQ of int (* the result is culled by upper_bound. We know it is GEQ to this value *)

module type WithCache = sig
  type t
  type cache
  val create_cache : int -> cache
  val distance : cache -> ?upper_bound: int -> t -> t -> result
end

module CacheByHashtbl(H : Hashtbl.HashedType) : Cache with type key = H.t = struct
  include Hashtbl.Make(H)
  let alter t k f =
    let v = f (try Some (find t k) with Not_found -> None) in
    begin match v with
    | None -> remove t k
    | Some v -> replace t k v
    end;
    v
end


module MakeWithCache(A : Array)(C : Cache with type key = A.t * A.t) = struct

  type t = A.t

  type cache = result C.t

  module WithoutCache = Make(A)

  let create_cache = C.create

  let distance cache ?(upper_bound=max_int) xs ys =
    let k = (xs, ys) in
    let vopt = C.alter cache k @@ function
      | Some (Exact _) as vopt -> vopt
      | Some (GEQ res) as vopt when res >= upper_bound -> vopt
      | _ (* not known, or inaccurate with this upper_bound *) ->
          Some (
            let res = WithoutCache.distance ~upper_bound xs ys in
            if res >= upper_bound then GEQ upper_bound
            else Exact res
          )
    in
    match vopt with
    | Some v -> v
    | None -> assert false
end

module StringWithHashtbl = struct

  module Array = struct
    type t = string
    type elem = char
    let compare (c1 : char) c2 = compare c1 c2
    let get = String.unsafe_get
    let size = String.length
  end

  module Cache = CacheByHashtbl(struct
    type t = string * string
    let equal = (=)
    let hash = Hashtbl.hash
  end)

  include MakeWithCache(Array)(Cache)
end

module String = struct

  include Make(struct
    type t = string
    type elem = char
    let compare (c1 : char) c2 = compare c1 c2
    let get = String.unsafe_get
    let size = String.length
  end)

end
