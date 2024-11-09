package demo_perf_cycles
import "../../../utils/math"

C_FLOAT :: 1.0 + 1.0 / 12.0
D_FLOAT :: 17

// base
loadZero_f64 :: proc(v: f64) -> f64 {
	return 0
}
add_f64 :: proc(v: f64) -> f64 {
	return v + C_FLOAT
}
mul_f64 :: proc(v: f64) -> f64 {
	return v * C_FLOAT
}
square_f64 :: proc(v: f64) -> f64 {
	return v * v
}
div_f64 :: proc(v: f64) -> f64 {
	return v / C_FLOAT
}
mod_f64 :: proc(v: f64) -> f64 {
	return math.mod(v, C_FLOAT)
}
// stats
lerpDiv_f64 :: proc(v: f64) -> f64 {
	return (1 - v) * C_FLOAT + v * D_FLOAT
}
lerpMul_f64 :: proc(v: f64) -> f64 {
	return (1 - v) * C_FLOAT + v * D_FLOAT
}
sqrt_f64 :: proc(v: f64) -> f64 {
	return math.sqrt(v)
}
exp_f64 :: proc(v: f64) -> f64 {
	return math.exp(v)
}
pow_f64 :: proc(v: f64) -> f64 {
	return math.pow(v, C_FLOAT)
}
// sincos
sin_f64 :: proc(v: f64) -> f64 {
	return math.sin(v)
}
cos_f64 :: proc(v: f64) -> f64 {
	return math.cos(v)
}
// TODO: cos,sine mod/flip into range
cos_f64_fast :: proc(v: f64) -> f64 {
	A :: math.TAU * math.TAU / 4
	//A :: 9.869604401089358
	vv := v * v
	return 1 - (5 * vv) / (A + vv)
}
cos_f64_fast2 :: proc(v: f64) -> f64 {
	//A :: math.TAU * math.TAU / 4
	A :: 9.869604401089358
	vv := v * v
	return 1 - (5 * vv) / (A + vv)
}
cos_f64_fastest :: proc(v: f64) -> f64 {
	A :: (2 / math.PI) * (2 / math.PI)
	//A :: 0.40528473456935116
	vv := v * v
	return 1 - A * vv
}
cos_f64_fastest2 :: proc(v: f64) -> f64 {
	//A :: (2 / math.PI) * (2 / math.PI)
	A :: 0.40528473456935116
	vv := v * v
	return 1 - A * vv
}
// TODO: cos lookup table
//COS_F64_LOOKUP := precompute_cos_f64_lookup()
//precompute_cos_f64_lookup :: proc() -> [256]f64 {}
//cos_f64_lookup :: proc(v: f64) -> f64 {}
sincos_f64 :: proc(v: f64) -> f64 {
	s, c := math.sincos(v)
	return s + c
}

hot_f64_cases := []TimingCase(f64) {
	// base
	timingCase(f64, "loadZero_f64", loadZero_f64), // 4 cy, 1 ns
	timingCase(f64, "add_f64", add_f64), // 4 cy, 1 ns
	timingCase(f64, "mul_f64", mul_f64), // 4 cy, 1 ns
	timingCase(f64, "square_f64", square_f64), // 4 cy, 1 ns
	timingCase(f64, "div_f64", div_f64), // 4 cy, 1 ns
	// TODO: floor, better mod?
	timingCase(f64, "mod_f64", mod_f64), // 11 cy, 3 ns, 3e+08 runs
	// stats
	timingCase(f64, "lerpDiv", lerpDiv_f64, true), // 5 cy, 1 ns
	timingCase(f64, "lerpMul", lerpMul_f64), // 5 cy, 1 ns
	timingCase(f64, "sqrt_f64", sqrt_f64), // 8 cy, 2 ns
	timingCase(f64, "exp_f64", exp_f64), // 157 cy, 41 ns
	timingCase(f64, "pow_f64", pow_f64), // 64 cy, 17 ns
	// sincos
	timingCase(f64, "sin_f64", sin_f64, true), // 42 cy, 11 ns
	timingCase(f64, "cos_f64", cos_f64), // 42 cy, 11 ns
	timingCase(f64, "cos_f64_fast", cos_f64_fast), // 5 cy, 1 ns, 2e+09 runs
	timingCase(f64, "cos_f64_fast2", cos_f64_fast2), // 6 cy, 2 ns, 2e+09 runs
	timingCase(f64, "cos_f64_fastest", cos_f64_fastest), // 5 cy, 1 ns, 5e+08 runs
	timingCase(f64, "cos_f64_fastest2", cos_f64_fastest2), // 6 cy, 2 ns, 2e+09 runs
	timingCase(f64, "sincos_f64", sincos_f64), // 39 cy, 10 ns
}
