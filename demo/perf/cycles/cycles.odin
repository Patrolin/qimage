// odin run demo/perf/cycles -o:speed
package demo_perf_cycles
import "../../../lib/math"
import "../../../lib/os"
import "core:fmt"
import "core:intrinsics"
import "core:strings"
import "core:time"

measureCold :: proc(_case: ^TimingCase) {
	acc: [1]int // NOTE: make compiler not optimize away our function calls
	diff_cycles: int
	diff_time: f64 // NOTE: windows only gives us precision of 100 ns per sample
	{
		os.SCOPED_TIME(&diff_time)
		os.SCOPED_CYCLES(&diff_cycles)
		acc[0] += _case.f(int(_case.run_count))
	}
	intrinsics.atomic_load(&acc[0])
	run_count := f64(_case.run_count)
	_case.average_cycles = (_case.average_cycles * run_count + f64(diff_cycles)) / (run_count + 1)
	_case.average_time = (_case.average_time * run_count + diff_time) / (run_count + 1)
	_case.run_count += 1
}
measureHot :: proc(_case: ^TimingCase) {
	acc: [1]int // NOTE: make compiler not optimize away our function calls
	diff_cycles: int
	diff_time: f64
	REPEAT_COUNT :: 1e8
	for j in 0 ..= 1 { 	// NOTE: we run twice so the code is in cache
		os.SCOPED_TIME(&diff_time)
		os.SCOPED_CYCLES(&diff_cycles)
		for i in 0 ..< REPEAT_COUNT {
			acc[0] += _case.f(i)
		}
	}
	intrinsics.atomic_load(&acc[0])
	_case.average_cycles = f64(diff_cycles) / REPEAT_COUNT
	_case.average_time = diff_time / REPEAT_COUNT
	_case.run_count = REPEAT_COUNT
}

loadZero_int :: proc(v: int) -> int {
	return 0
}
loadZero_f64 :: proc(v: int) -> int {
	f := f64(0.4)
	return int(f)
}
returnInput :: proc(v: int) -> int {
	return v
}
intToFloatToInt :: proc(v: int) -> int {
	return int(f64(v) * 0.3)
}

add_int :: proc(v: int) -> int {
	return v + 1
}
K :: 1.12
add_f64 :: proc(v: int) -> int {
	return int(f64(v) + K)
}
mul_int :: proc(v: int) -> int {
	return v * 2
}
mul_f64 :: proc(v: int) -> int {
	return int(f64(v) * K)
}
square_int :: proc(v: int) -> int {
	return v * v
}
square_f64 :: proc(v: int) -> int {
	f := f64(v)
	return int(f * f)
}
div_int :: proc(v: int) -> int {
	return v / 3
}
div_f16 :: proc(v: int) -> int {
	return int(f16(v) / K)
}
div_f32 :: proc(v: int) -> int {
	return int(f32(v) / K)
}
div_f64 :: proc(v: int) -> int {
	return int(f64(v) / K)
}
lerpDiv :: proc(v: int) -> int {
	t := f64(v) / 1000
	return int((1 - t) * 7 + t * 13)
}
lerpMul :: proc(v: int) -> int {
	t := f64(v) * 1e-3
	return int((1 - t) * 7 + t * 13)
}
sqrt_f16 :: proc(v: int) -> int {
	return int(math.sqrt(f16(v)))
}
sqrt_f32 :: proc(v: int) -> int {
	return int(math.sqrt(f32(v)))
}
sqrt_f64 :: proc(v: int) -> int {
	return int(math.sqrt(f64(v)))
}
exp_f16 :: proc(v: int) -> int {
	return int(math.exp(f16(v)))
}
exp_f32 :: proc(v: int) -> int {
	return int(math.exp(f32(v)))
}
exp_f64 :: proc(v: int) -> int {
	return int(math.exp(f64(v)))
}
B :: 1.0 + 1.0 / 12.0
pow_f16 :: proc(v: int) -> int {
	return int(math.pow(f16(v), B))
}
pow_f32 :: proc(v: int) -> int {
	return int(math.pow(f32(v), B))
}
pow_f64 :: proc(v: int) -> int {
	return int(math.pow(f64(v), B))
}
sin_f16 :: proc(v: int) -> int {
	return int(math.sin(f16(v)))
}
sin_f32 :: proc(v: int) -> int {
	return int(math.sin(f32(v)))
}
sin_f64 :: proc(v: int) -> int {
	return int(math.sin(f64(v)))
}
cos_f16 :: proc(v: int) -> int {
	return int(math.cos(f16(v)))
}
cos_f32 :: proc(v: int) -> int {
	return int(math.cos(f32(v)))
}
cos_f64 :: proc(v: int) -> int {
	return int(math.cos(f64(v)))
}
sincos_f16 :: proc(v: int) -> int {
	s, c := math.sincos(f64(v))
	return int(s + c)
}
sincos_f32 :: proc(v: int) -> int {
	s, c := math.sincos(f64(v))
	return int(s + c)
}
sincos_f64 :: proc(v: int) -> int {
	s, c := math.sincos(f64(v))
	return int(s + c)
}
TimingCase :: struct {
	name:           string,
	f:              proc(v: int) -> int,
	break_before:   bool,
	average_cycles: f64,
	average_time:   f64,
	run_count:      int,
}
timingCase :: proc(name: string, f: proc(v: int) -> int, break_before := false) -> TimingCase {
	return TimingCase{name, f, break_before, 0, 0, 0}
}
main :: proc() {
	// TODO?: rewrite everything in test_case: testCase = TestCase()
	os.initOsInfo()
	cold_cases := []TimingCase {
		timingCase("loadZero_int_cold", loadZero_int, true), // 587 cy, 336 ns, 11 runs
	}
	hot_cases := []TimingCase { 	// TODO: also do multiple runs?
		timingCase("loadZero_int", loadZero_int, true), // 4 cy, 1 ns // TODO: double check comments
		timingCase("loadZero_f64", loadZero_f64), // 4 cy, 1 ns
		timingCase("returnInput", returnInput), // 4 cy, 1 ns
		timingCase("intToFloatToInt", intToFloatToInt), // 6 cy, 1 ns
		timingCase("add_int", add_int, true), // 4 cy, 1 ns
		timingCase("add_f64", add_f64), // 5 cy, 1 ns
		timingCase("mul_int", mul_int), // 4 cy, 1 ns
		timingCase("mul_f64", mul_f64), // 5 cy, 1 ns
		timingCase("square_int", square_int), // 4 cy, 1 ns
		timingCase("square_f64", square_f64), // 5 cy, 1 ns
		timingCase("div_int", div_int), // 5 cy, 1 ns
		timingCase("div_f16", div_f16), // 14 cy, 1 ns
		timingCase("div_f32", div_f32), // 14 cy, 1 ns
		timingCase("div_f64", div_f64), // 14 cy, 1 ns
		timingCase("lerpDiv", lerpDiv, true), // 21 cy, 6 ns
		timingCase("lerpMul", lerpMul), // 13 cy, 3 ns
		timingCase("sqrt_f16", sqrt_f16), // 74 cy, 20 ns
		timingCase("sqrt_f32", sqrt_f32), // 15 cy, 4 ns
		timingCase("sqrt_f64", sqrt_f64), // 20 cy, 5 ns
		timingCase("exp_f16", exp_f16), // 62 cy, 16 ns
		timingCase("exp_f32", exp_f32), // 171 cy, 45 ns
		timingCase("exp_f64", exp_f64), // 156 cy, 41 ns
		timingCase("pow_f16", pow_f16), // 39 cy, 10 ns
		timingCase("pow_f32", pow_f32), // 67 cy, 18 ns
		timingCase("pow_f64", pow_f64), // 127 cy, 33 ns
		timingCase("sin_f16", sin_f16, true), // 164 cy, 43 ns
		timingCase("sin_f32", sin_f32), // 71 cy, 19 ns
		timingCase("sin_f64", sin_f64), // 90 cy, 24 ns
		timingCase("cos_f16", cos_f16), // 166 cy, 44 ns
		timingCase("cos_f32", cos_f32), // 71 cy, 19 ns
		timingCase("cos_f64", cos_f64), // 96 cy, 25 ns
		timingCase("sincos_f16", sincos_f16), // 61 cy, 16 ns
		timingCase("sincos_f32", sincos_f32), // 61 cy, 16 ns
		timingCase("sincos_f64", sincos_f64), // 61 cy, 16 ns
		// TODO!: more math functions
	}
	for {
		sb: strings.Builder
		for &_case in cold_cases {
			measureCold(&_case)
			if _case.break_before {
				fmt.sbprintln(&sb)
			}
			fmt.sbprintfln(
				&sb,
				"%v: %.0f cy, %.0f ns, %v runs",
				_case.name,
				_case.average_cycles,
				os.nanos(_case.average_time),
				_case.run_count,
			)
		}
		for &_case in hot_cases {
			measureHot(&_case)
			if _case.break_before {
				fmt.sbprintln(&sb)
			}
			fmt.sbprintfln(
				&sb,
				"%v: %.0f cy, %.0f ns",
				_case.name,
				_case.average_cycles,
				os.nanos(_case.average_time),
			)
		}
		fmt.sbprintfln(&sb, "")
		fmt.print(strings.to_string(sb))
		strings.builder_destroy(&sb)
	}
}
