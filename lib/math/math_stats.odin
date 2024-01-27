package lib_math
import "core:intrinsics"

cycles :: proc() -> u64 {
	return u64(intrinsics.read_cycle_counter())
}
MILLIS :: 1000
MICROS :: 1000_000
NANOS :: 1000_000

min_i16 :: proc(a, b: i16) -> i16 {
	return (a < b) ? a : b
}
min_f32 :: proc(a, b: f32) -> f32 {
	return (a < b) ? a : b
}
min_f64 :: proc(a, b: f64) -> f64 {
	return (a < b) ? a : b
}
min :: proc {
	min_i16,
	min_f32,
	min_f64,
}
max_i16 :: proc(a, b: i16) -> i16 {
	return (a > b) ? a : b
}
max_f32 :: proc(a, b: f32) -> f32 {
	return (a > b) ? a : b
}
max_f64 :: proc(a, b: f64) -> f64 {
	return (a > b) ? a : b
}
max :: proc {
	max_i16,
	max_f32,
	max_f64,
}
abs_i16 :: proc(a: i16) -> i16 {
	return (a < 0) ? -a : a
}
abs_f32 :: proc(a: f32) -> f32 {
	return (a < 0) ? -a : a
}
abs_f64 :: proc(a: f64) -> f64 {
	return (a < 0) ? -a : a
}
abs :: proc {
	abs_i16,
	abs_f32,
	abs_f64,
}
