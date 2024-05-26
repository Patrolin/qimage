package lib_math
import "core:intrinsics"

// NOTE: Odin vector types (.xyzw, .rgba)
i32x2 :: [2]i32 // 8 B
i32x3 :: [3]i32 // 12 B
i32x4 :: [4]i32 // 16 B
f32x2 :: [2]f32 // 8 B
f32x3 :: [3]f32 // 12 B
f32x4 :: [4]f32 // 16 B
AbsoluteRect :: struct {
	left, top, right, bottom: i32,
}
RelativeRect :: struct {
	left, top, width, height: i32,
}

inBounds :: proc(pos: i32x2, rect: AbsoluteRect) -> bool {
	return(
		(pos.x >= rect.left) &
		(pos.x <= rect.right) &
		(pos.y >= rect.bottom) &
		(pos.y <= rect.top) \
	)
}
clamp_int :: proc(x, min, max: $T) -> T where intrinsics.type_is_numeric(T) {
	x := x + (min - x) * T(x < min)
	x = x + (max - x) * T(x > max)
	return x
}
clamp_v2i :: proc(pos: i32x2, rect: AbsoluteRect) -> i32x2 {
	return {clamp(pos.x, rect.left, rect.right), clamp(pos.y, rect.top, rect.bottom)}
}
clamp :: proc {// TODO!: simd clamp?
	clamp_int,
	clamp_v2i,
}
