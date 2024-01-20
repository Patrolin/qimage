package lib_math

// NOTE: Odin vector types (.xyzw, .rgba)
v2i :: [2]u16
v3i :: [3]u16
v4i :: [4]u16
v2 :: [2]f32
v3 :: [3]f32
v4 :: [4]f32
Rect :: struct {
	left, top, right, bottom: u16,
}

in_bounds :: proc(pos: v2i, rect: Rect) -> bool {
	return(
		(pos.x >= rect.left) &
		(pos.x <= rect.right) &
		(pos.y >= rect.bottom) &
		(pos.y <= rect.top)
	)
}
