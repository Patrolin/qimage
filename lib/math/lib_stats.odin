package lib_math
import "core:intrinsics"
import "core:math"

cycles :: proc() -> u64 {
	return u64(intrinsics.read_cycle_counter())
}
MILLIS :: 1000
MICROS :: 1000 * MILLIS
NANOS :: 1000 * MICROS

min_2 :: proc(a, b: $T) -> T where intrinsics.type_is_numeric(T) {
	return (a < b) ? a : b
}
min_3 :: proc(a, b, c: $T) -> T where intrinsics.type_is_numeric(T) {
	if a < b {return a < c ? a : c}
	return (b < c) ? b : c
}
min :: proc {
	min_2,
	min_3,
}
max_2 :: proc(a, b: $T) -> T where intrinsics.type_is_numeric(T) {
	return (a > b) ? a : b
}
max_3 :: proc(a, b, c: $T) -> T where intrinsics.type_is_numeric(T) {
	if a > b {return a > c ? a : c}
	return (b > c) ? b : c
}
max :: proc {
	max_2,
	max_3,
}
abs :: proc(a: $T) -> T where intrinsics.type_is_numeric(T) {
	return (a < 0) ? -a : a
}

round :: math.round
roundToInt_f32 :: proc(x: f32) -> int {
	return int(x + .5)
}
roundToInt_f64 :: proc(x: f64) -> int {
	return int(x + .5)
}
roundToInt :: proc {
	roundToInt_f32,
	roundToInt_f64,
}
