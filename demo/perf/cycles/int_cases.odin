package demo_perf_cycles
import "core:intrinsics"

// function calls
loadZero_int :: proc(v: int) -> int {
	return 0
}
returnInput_int :: proc(v: int) -> int {
	return v
}
intToF64ToInt :: proc(v: int) -> int {
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
	timingCase(int, "loadZero_int_cold", loadZero_int), // 654 cy, 280 ns, 5 runs
}
hot_int_cases := []TimingCase(int) {
	// base
	timingCase(int, "loadZero_int", loadZero_int), // 5 cy, 1 ns, 5e+08 runs
	timingCase(int, "returnInput_int", returnInput_int), // 5 cy, 1 ns, 5e+08 runs
	timingCase(int, "intToF64ToInt", intToF64ToInt), // 5 cy, 1 ns, 5e+08 runs
	timingCase(int, "add_int", add_int), // 5 cy, 1 ns, 5e+08 runs
	timingCase(int, "mul_int", mul_int), // 6 cy, 1 ns, 5e+08 runs
	timingCase(int, "div_int", div_int), // 5 cy, 1 ns, 5e+08 runs
	timingCase(int, "mod_int", mod_int), // 7 cy, 2 ns, 4e+08 runs
}
