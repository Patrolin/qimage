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
		os.SCOPED_CYCLES(&diff_cycles)
		os.SCOPED_TIME(&diff_time)
		{
			acc[0] += _case.f(int(_case.run_count))
		}
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
		os.SCOPED_CYCLES(&diff_cycles)
		os.SCOPED_TIME(&diff_time)
		for i in 0 ..< REPEAT_COUNT {
			acc[0] += _case.f(i)
		}
	}
	intrinsics.atomic_load(&acc[0])
	_case.average_cycles = f64(diff_cycles) / REPEAT_COUNT
	_case.average_time = diff_time / REPEAT_COUNT
	_case.run_count = REPEAT_COUNT
}

loadZero :: proc(v: int) -> int {
	return 0
}
returnInput :: proc(v: int) -> int {
	return v
}
addOne :: proc(v: int) -> int {
	return v + 1
}
mulTwo :: proc(v: int) -> int {
	return v * 2
}
square :: proc(v: int) -> int {
	return v * v
}
sqrt :: proc(v: int) -> int {
	return int(math.sqrt(f64(v)))
}
lerpDiv :: proc(v: int) -> int {
	t := f64(v) / 1000
	return int((1 - t) * 7 + t * 13)
}
lerpMul :: proc(v: int) -> int {
	t := f64(v) * 1e-3
	return int((1 - t) * 7 + t * 13)
}
TimingCase :: struct {
	name:           string,
	f:              proc(v: int) -> int,
	average_cycles: f64,
	average_time:   f64,
	run_count:      int,
}
timingCase :: proc(name: string, f: proc(v: int) -> int) -> TimingCase {
	return TimingCase{name, f, 0, 0, 0}
}
main :: proc() {
	os.initOsInfo()
	cold_cases := []TimingCase {
		timingCase("loadZeroCold", loadZero), // 1856 cy, 266 ns, 50 runs
	}
	hot_cases := []TimingCase {
		timingCase("loadZero", loadZero), // 5 cy, 1 ns
		timingCase("returnInput", returnInput), // 5 cy, 1 ns
		timingCase("addOne", addOne), // 5 cy, 1 ns
		timingCase("mulTwo", mulTwo), // 5 cy, 1 ns
		timingCase("square", square), // 5 cy, 1 ns
		timingCase("sqrt", sqrt), // 20 cy, 5 ns
		timingCase("lerpDiv", lerpDiv), // 22 cy, 6 ns
		timingCase("lerpMul", lerpMul), // 13 cy, 3 ns
	}
	for index := 0; true; index += 1 {
		sb: strings.Builder
		for &_case in cold_cases {
			measureCold(&_case)
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
