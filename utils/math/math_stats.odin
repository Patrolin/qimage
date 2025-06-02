package math_utils
// NOTE: we assume builtins min(), max() and abs() are fast
import "base:intrinsics"
import "core:math"

round_to_int :: #force_inline proc "contextless" (x: $T) -> int where intrinsics.type_is_float(T) {
	return int(x + .5)
}
round :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	return T(int(x + .5)) // TODO: is there a better way to round?
}
floor :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	return math.floor(x)
}
ceil :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	return math.ceil(x)
}

percentile :: proc(sorted_slice: $A/[]$T, fraction: T) -> T {
	index_float := fraction * T(len(x) - 1)
	index := int(index)
	remainder := index_float % 1
	return lerp(remainder, sorted_slice[index], sorted_slice[index + 1])
}
