package demo_perf_cycles
import "../../../utils/math"

// ?TODO: use intrinsics.procedure_of(div(f16, f16(0)))
// TODO: automatically save timings to a file
div_f16 :: proc(v: f16) -> f16 {
	return v / C_FLOAT
}
sqrt_f16 :: proc(v: f16) -> f16 {
	return math.sqrt(v)
}
exp_f16 :: proc(v: f16) -> f16 {
	return math.exp(v)
}
pow_f16 :: proc(v: f16) -> f16 {
	return math.pow(v, C_FLOAT)
}
sin_f16 :: proc(v: f16) -> f16 {
	return math.sin(v)
}
cos_f16 :: proc(v: f16) -> f16 {
	return math.cos(v)
}
cos_f16_fast :: proc(v: f16) -> f16 {
	A :: math.TAU * math.TAU / 4
	vv := v * v
	return 1 - (5 * vv) / (A + vv)
}
cos_f16_through_f64 :: proc(v: f16) -> f16 {
	v := f64(v)
	A :: math.TAU * math.TAU / 4
	vv := v * v
	return f16(1 - (5 * vv) / (A + vv))
}
sincos_f16 :: proc(v: f16) -> f16 {
	s, c := math.sincos(v)
	return f16(s + c)
}

hot_f16_cases := []TimingCase(f16) {
	// base
	timing_case(f16, "div_f16", div_f16), // 25.5 cy, 6.7 ns, 1e+08 runs
	// stats
	timing_case(f16, "sqrt_f16", sqrt_f16, true), // 25.5 cy, 6.7 ns, 1e+08 runs
	timing_case(f16, "exp_f16", exp_f16), // 29.3 cy, 7.7 ns, 1e+08 runs
	timing_case(f16, "pow_f16", pow_f16), // 31.8 cy, 8.4 ns, 1e+08 runs
	// sincos
	timing_case(f16, "sin_f16", sin_f16, true), // 150.7 cy, 39.7 ns, 1e+08 runs
	timing_case(f16, "cos_f16", cos_f16), // 151.6 cy, 40.0 ns, 1e+08 runs
	timing_case(f16, "cos_f16_fast", cos_f16_fast), // 94.3 cy, 24.9 ns, 1e+08 runs
	timing_case(f16, "cos_f16_through_f64", cos_f16_through_f64), // 30.7 cy, 8.1 ns, 1e+08 runs
	timing_case(f16, "sincos_f16", sincos_f16), // 53.6 cy, 14.1 ns, 1e+08 runs
}
