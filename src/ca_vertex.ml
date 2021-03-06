(* type declarations {{{ *)

type node_id = int

(* }}} *)

(* data structure type declarations {{{ *)

module Node = struct
  type t = node_id
  let compare = Pervasives.compare
end
module NodeSet = struct
  include Set.Make(Node)
  let pprint s = "{" ^ (String.concat "," (List.map string_of_int (elements s))) ^ "}"
end
module NodeMap = struct
  include Map.Make(Node)
  let pprint_binding (n,n') = Printf.sprintf "%d:%d" n n'
  let pprint m =
    let bindings_string = String.concat "," (List.map pprint_binding (bindings m)) in
    Printf.sprintf "{%s}" bindings_string
end

module VariableMap = Util.DS.IdentifierMap

(* }}} *)

(* structure type declarations {{{ *)

type node_set = NodeSet.t
type succ_map = node_id NodeMap.t
type var_map = node_id VariableMap.t
type ploc = int
type structure = { nodes : node_set ; succ : succ_map ; var : var_map }
type ca_loc = ploc * structure

(* }}} *)

(* equal / compare / hash {{{ *)

(* Caveat: we cannot use polymorphic compare / equal / hash here:
 * https://blog.janestreet.com/the-perils-of-polymorphic-compare/ *)
let compare (loc,s) (loc',s') = match Pervasives.compare loc loc' with
| 0 -> begin match NodeSet.compare s.nodes s'.nodes with
  | 0 -> begin match NodeMap.compare Node.compare s.succ s'.succ with
    | 0 -> VariableMap.compare Node.compare s.var s'.var
    | c -> c
  end
  | c -> c
end
| c -> c

(* https://stackoverflow.com/a/27952689/1161037 *)
let combine_hash a b = (a lsl 1) + a + b
let hash (ploc, { nodes ; succ ; var })  =
  let hash_ploc = Hashtbl.hash ploc in
  let hash_nodes = NodeSet.fold (fun elt hash ->
    (Hashtbl.hash elt) + hash
  ) nodes 0 in
  let hash_succ = NodeMap.fold (fun n n' hash ->
    (Hashtbl.hash n) + (Hashtbl.hash n') + hash
  ) succ 0 in
  let hash_var = VariableMap.fold (fun v n hash ->
    (Hashtbl.hash v) + (Hashtbl.hash n) + hash
  ) var 0 in
  List.fold_left (fun hash part_hash -> combine_hash hash part_hash) 0 [
    hash_ploc ; hash_nodes ; hash_succ ; hash_var ]

let equal
  (loc1, { nodes = n1 ; succ = s1 ; var = v1 })
  (loc2, { nodes = n2 ; succ = s2 ; var = v2 }) =
  loc1 = loc2 &&
  NodeSet.equal n1 n2 &&
  NodeMap.equal Pervasives.(=) s1 s2 &&
  VariableMap.equal Pervasives.(=) v1 v2

(* }}} *)

(* pretty printing functions {{{ *)

let pprint_structure ?(sep=", ") structure =
  Printf.sprintf "nodes: %s%ssuccs: %s%svars: %s"
    (NodeSet.pprint structure.nodes) sep
    (NodeMap.pprint structure.succ) sep
    (VariableMap.pprint structure.var)

let pprint ?(sep=", ") (p, s) =
  Printf.sprintf "pc: %d%s%s" p sep (pprint_structure ~sep s)

(* }}} *)

(* partial graph module for CA vertices {{{ *)

module Vertex = struct
  type vertex = ca_loc

  let compare_vertex = compare
  let hash_vertex    = hash
  let equal_vertex   = equal
  let get_ploc (p,_) = p

  let pprint_vertex v = Printf.sprintf "\"%s\"" (pprint v)
end

(* }}} *)

(* permutation {{{ *)

let permute heap permutation =
  let elements = NodeSet.elements heap.nodes in
  let permuted_node = function
    | 0 -> 0
    | node ->
        let index = Util.List.find node elements in
        List.nth permutation index
  in
  let nodes = heap.nodes in
  let succ = NodeMap.fold (fun from to_ permuted_map ->
    let permuted_from = permuted_node from in
    let permuted_to = permuted_node to_ in
    NodeMap.add permuted_from permuted_to permuted_map
  ) heap.succ NodeMap.empty
  in
  let var = VariableMap.fold (fun var node permuted_map ->
    let permuted_node = permuted_node node in
    VariableMap.add var permuted_node permuted_map
  ) heap.var VariableMap.empty
  in
  { nodes ; succ ; var }

(* }}} *)
