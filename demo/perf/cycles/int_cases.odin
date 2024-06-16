package demo_perf_cycles

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

cold_int_cases := []TimingCase(int) {
	timingCase(int, "loadZero_int_cold", loadZero_int), // 587 cy, 336 ns, 11 runs
}
hot_int_cases := []TimingCase(int) {
	// base
	timingCase(int, "loadZero_int", loadZero_int), // 4 cy, 1 ns
	timingCase(int, "returnInput_int", returnInput_int), // 4 cy, 1 ns
	timingCase(int, "intToF64ToInt", intToF64ToInt), // 6 cy, 1 ns
	timingCase(int, "add_int", add_int), // 4 cy, 1 ns
	timingCase(int, "mul_int", mul_int), // 4 cy, 1 ns
	timingCase(int, "div_int", div_int), // 5 cy, 1 ns
}
