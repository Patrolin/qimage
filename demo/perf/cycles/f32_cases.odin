package demo_perf_cycles
import "../../../utils/math"

div_f32 :: proc(v: f32) -> f32 {
	return v / C_FLOAT
}
sqrt_f32 :: proc(v: f32) -> f32 {
	return math.sqrt(v)
}
exp_f32 :: proc(v: f32) -> f32 {
	return math.exp(v)
}
pow_f32 :: proc(v: f32) -> f32 {
	return math.pow(v, C_FLOAT)
}
sin_f32 :: proc(v: f32) -> f32 {
	return math.sin(v)
}
cos_f32 :: proc(v: f32) -> f32 {
	return math.cos(v)
}
sincos_f32 :: proc(v: f32) -> f32 {
	s, c := math.sincos(v)
	return s + c
}

hot_f32_cases := []TimingCase(f32) {
	// base
	timing_case(f32, "div_f32", div_f32), // 4 cy, 1 ns
	// stats
	timing_case(f32, "sqrt_f32", sqrt_f32, true), // 4 cy, 1 ns
	timing_case(f32, "exp_f32", exp_f32), // 173 cy, 46 ns
	timing_case(f32, "pow_f32", pow_f32), // 23 cy, 6 ns
	// sincos
	timing_case(f32, "sin_f32", sin_f32, true), // 31 cy, 8 ns
	timing_case(f32, "cos_f32", cos_f32), // 31 cy, 8 ns
	timing_case(f32, "sincos_f32", sincos_f32), // 45 cy, 12 ns
}
