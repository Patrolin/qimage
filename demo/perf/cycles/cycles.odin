// odin run demo/perf/cycles -o:speed
package demo_perf_cycles
import "../../../lib/math"
import "../../../lib/os"
import "core:fmt"
import "core:intrinsics"
import "core:strings"
import "core:time"

measureCold :: proc(sb: ^strings.Builder, name: string, f: proc(v: int) -> int, index: int) {
	acc: [1]int // NOTE: make compiler not optimize away our function calls
	diff_cycles: int
	diff_time: f64 // NOTE: windows only gives us precision of 100 ns per sample
	{
		os.SCOPED_CYCLES(&diff_cycles)
		os.SCOPED_TIME(&diff_time)
		{
			acc[0] += f(index)
		}
	}
	intrinsics.atomic_load(&acc[0])
	fmt.sbprintfln(sb, "%v: %v cy, %.0f ns", name, diff_cycles, os.nanos(diff_time))
}
measureHot :: proc(
	sb: ^strings.Builder,
	name: string,
	f: proc(v: int) -> int,
	repeat_count: int = 1e8,
) {
	acc: [1]int // NOTE: make compiler not optimize away our function calls
	diff_cycles: int
	diff_time: f64
	for j in 0 ..= 1 { 	// NOTE: we run twice so the code is in cache
		os.SCOPED_CYCLES(&diff_cycles)
		os.SCOPED_TIME(&diff_time)
		for i in 0 ..< repeat_count {
			acc[0] += f(i)
		}
	}
	intrinsics.atomic_load(&acc[0])
	fmt.sbprintfln(
		sb,
		"%v: %.0f cy, %.0f ns",
		name,
		f64(diff_cycles) / f64(repeat_count),
		f64(os.nanos(diff_time)) / f64(repeat_count),
	)
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
	name: string,
	f:    proc(v: int) -> int,
}
main :: proc() {
	os.initOsInfo()
	for index := 0; true; index += 1 {
		sb: strings.Builder
		for _case in ([]TimingCase {
				{"loadZeroCold", loadZero}, // 874 cy, 100 ns
			}) {
			measureCold(&sb, _case.name, _case.f, index)
		}
		for _case in ([]TimingCase {
				{"loadZero", loadZero}, // 9 cy, 2 ns
				{"returnInput", returnInput}, // 9 cy, 2 ns
				{"addOne", addOne}, // 12 cy, 3 ns
				{"mulTwo", mulTwo}, // 12 cy, 3 ns
				{"square", square}, // 12 cy, 3 ns
				{"sqrt", sqrt}, // 31 cy, 8 ns
				{"lerpDiv", lerpDiv}, // 33 cy, 9 ns
				{"lerpMul", lerpMul}, // 21 cy, 5 ns
			}) {
			measureHot(&sb, _case.name, _case.f)
		}
		fmt.sbprintfln(&sb, "")
		fmt.print(strings.to_string(sb))
		strings.builder_destroy(&sb)
	}
}
