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
	f := f16(v)
	A :: math.TAU * math.TAU / 4
	ff := f * f
	return f16(1 - (5 * ff) / (A + ff))
}
sincos_f16 :: proc(v: f16) -> f16 {
	s, c := math.sincos(v)
	return f16(s + c)
}

hot_f16_cases := []TimingCase(f16) {
	// base
	timingCase(f16, "div_f16", div_f16), // 46 cy, 12 ns, 5e+08 runs
	// stats
	timingCase(f16, "sqrt_f16", sqrt_f16, true), // 47 cy, 12 ns, 5e+08 runs
	timingCase(f16, "exp_f16", exp_f16), // 51 cy, 13 ns, 5e+08 runs
	timingCase(f16, "pow_f16", pow_f16), // 52 cy, 14 ns, 5e+08 runs
	// sincos
	timingCase(f16, "sin_f16", sin_f16, true), // 165 cy, 44 ns, 5e+08 runs
	timingCase(f16, "cos_f16", cos_f16), // 167 cy, 44 ns, 5e+08 runs
	timingCase(f16, "cos_f16_fast", cos_f16_fast), // 130 cy, 34 ns, 5e+08 runs
	timingCase(f16, "sincos_f16", sincos_f16), // 83 cy, 22 ns, 5e+08 runs
}
