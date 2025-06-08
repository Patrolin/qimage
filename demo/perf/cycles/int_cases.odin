package demo_perf_cycles
import "base:intrinsics"

// function calls
load_zero_int :: proc(v: int) -> int {
	return 0
}
return_input_int :: proc(v: int) -> int {
	return v
}
int_to_f64_to_int :: proc(v: int) -> int {
	return int(f64(v) * 0.3)
}
// base
add_int :: proc(v: int) -> int {
	return v + 1
}
mul_int :: proc(v: int) -> int {
	return v * 2
}
div_int :: proc(v: int) -> int {
	return v / 3
}
mod_int :: proc(v: int) -> int {
	return v % 3
}

cold_int_cases := []TimingCase(int) {
	timing_case(int, "load_zero_int_cold", load_zero_int), // 654 cy, 280 ns, 5 runs
}
hot_int_cases := []TimingCase(int) {
	// base
	timing_case(int, "load_zero_int", load_zero_int), // 4.2 cy, 1.1 ns, 1e+08 runs
	timing_case(int, "return_input_int", return_input_int), // 4.1 cy, 1.1 ns, 1e+08 runs
	timing_case(int, "int_to_f64_to_int", int_to_f64_to_int), // 6.6 cy, 1.7 ns, 1e+08 runs
	timing_case(int, "add_int", add_int), // 4.9 cy, 1.3 ns, 1e+08 runs
	timing_case(int, "mul_int", mul_int), // 4.1 cy, 1.1 ns, 1e+08 runs
	timing_case(int, "div_int", div_int), // 5.6 cy, 1.5 ns, 1e+08 runs
	timing_case(int, "mod_int", mod_int), // 5.0 cy, 1.3 ns, 1e+08 runs
	// TODO: better mod?
}
