package lib_math
// NOTE: we assume builtins min(), max() and abs() are fast
import "core:intrinsics"
import "core:math"

nanos :: proc(value: $T) -> T {return value * 1e9}
micros :: proc(value: $T) -> T {return value * 1e6}
millis :: proc(value: $T) -> T {return value * 1e3}
seconds :: proc(value: $T) -> T {return value}

cycles :: proc() -> int {
	return int(intrinsics.read_cycle_counter())
}
roundToInt :: proc(x: $T) -> int where intrinsics.type_is_float(T) {
	return int(x + .5)
}
