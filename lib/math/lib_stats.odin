package lib_math
// NOTE: we assume builtins min(), max() and abs() are fast
import "base:intrinsics"
import "core:math"

roundToInt :: proc(x: $T) -> int where intrinsics.type_is_float(T) {
	return int(x + .5)
}
round :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	return T(int(x + .5)) // TODO: is there a better way to round?
}
