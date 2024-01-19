package lib_math
import win "../windows"
import "core:intrinsics"

when ODIN_OS == .Windows {
	time :: proc() -> f64 {
		counter: win.LARGE_INTEGER
		win.QueryPerformanceCounter(&counter)
		return f64(counter) / win.windows_info.query_performance_frequency
	}
}
cycles :: proc() -> u64 {
	return u64(intrinsics.read_cycle_counter())
}

// TODO: math_stats
min :: proc(a: f64, b: f64) -> f64 {
	return (a < b) ? a : b
}
max :: proc(a: f64, b: f64) -> f64 {
	return (a > b) ? a : b
}
abs :: proc(a: f64) -> f64 {
	return (a < 0) ? -a : a
}
