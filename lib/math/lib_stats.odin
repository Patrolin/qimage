package lib_math
// NOTE: we assume builtins min(), max() and abs() are fast
import "core:intrinsics"
import "core:math"

nanos :: proc(value: $T) -> T {return value * 1e9}
micros :: proc(value: $T) -> T {return value * 1e6}
millis :: proc(value: $T) -> T {return value * 1e3}
seconds :: proc(value: $T) -> T {return value}

roundToInt :: proc(x: $T) -> int where intrinsics.type_is_float(T) {
	return int(x + .5)
}
round :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	return T(int(x + .5)) // TODO: is there a better way to round?
}
