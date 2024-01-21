package lib_math
import win "../windows"
import "core:intrinsics"

when ODIN_OS == .Windows {
	time :: win.time
} else {
	time :: nil
}
cycles :: proc() -> u64 {
	return u64(intrinsics.read_cycle_counter())
}

min :: proc(a: f64, b: f64) -> f64 {
	return (a < b) ? a : b
}
max :: proc(a: f64, b: f64) -> f64 {
	return (a > b) ? a : b
}
abs :: proc(a: f64) -> f64 {
	return (a < 0) ? -a : a
}
