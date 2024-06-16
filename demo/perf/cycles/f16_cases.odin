package demo_perf_cycles
import "../../../lib/math"

// TODO?: use intrinsics.procedure_of(div(f16, f16(0)))
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
	timingCase(f16, "div_f16", div_f16), // 44 cy, 12 ns
	// stats
	timingCase(f16, "sqrt_f16", sqrt_f16, true), // 46 cy, 12 ns
	timingCase(f16, "exp_f16", exp_f16), // 46 cy, 12 ns
	timingCase(f16, "pow_f16", pow_f16), // 47 cy, 12 ns
	// sincos
	timingCase(f16, "sin_f16", sin_f16, true), // 162 cy, 43 ns
	timingCase(f16, "cos_f16", cos_f16), // 164 cy, 43 ns
	timingCase(f16, "cos_f16_fast", cos_f16_fast), // 125 cy, 33 ns
	timingCase(f16, "sincos_f16", sincos_f16), // 83 cy, 22 ns
}
