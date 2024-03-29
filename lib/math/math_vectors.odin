package lib_math

// NOTE: Odin vector types (.xyzw, .rgba)
v2i :: [2]i16
v3i :: [3]i16
v4i :: [4]i16
v2 :: [2]f32
v3 :: [3]f32
v4 :: [4]f32
Rect :: struct {
	left, top, right, bottom: i16,
}

inBounds :: proc(pos: v2i, rect: Rect) -> bool {
	return(
		(pos.x >= rect.left) &
		(pos.x <= rect.right) &
		(pos.y >= rect.bottom) &
		(pos.y <= rect.top)
	)
}
clamp_i16 :: proc(x, min, max: i16) -> i16 {
	x := x + (min-x)*i16(x < min)
	x = x + (max-x)*i16(x > max)
	return x
}
clamp_v2_rect :: proc(pos: v2i, rect: Rect) -> v2i {
	return {clamp(pos.x, rect.left, rect.right), clamp(pos.y, rect.top, rect.bottom)}
}
clamp :: proc{clamp_i16, clamp_v2_rect}
