let get_color i =
  let colors = [ 0xff0000 ; 0x0000ff ; 0x00ff00 ] in
  match i with
  | 0 -> 0
  | i -> List.nth colors ((i-1) mod (List.length colors))