// odin run demo/perf/cycles -o:speed
package demo_perf_cycles
import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:strings"
import win "core:sys/windows"
import "core:time"

mfence :: #force_inline proc "contextless" () {
	intrinsics.atomic_thread_fence(.Seq_Cst)
}
// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
cycles :: proc "contextless" () -> (total_cycles: int) {
	return int(intrinsics.read_cycle_counter())
}

@(deferred_in_out = _scoped_cycles_end)
SCOPED_CYCLES :: proc "contextless" (diff_cycles: ^int) -> (start_cycles: int) {
	mfence()
	start_cycles = cycles()
	mfence()
	return
}
_scoped_cycles_end :: proc "contextless" (diff_cycles: ^int, start_cycles: int) {
	mfence()
	diff_cycles^ = int(cycles() - start_cycles)
	mfence()
}
measure :: proc(
	sb: ^strings.Builder,
	name: string,
	f: proc(v: int) -> int,
	repeat_count: int = 1e8,
) {
	acc: [1]int
	diff_cycles: int
	diff_time: time.Duration
	for j in 0 ..= 1 { 	// NOTE: we run twice so the code is in cache
		SCOPED_CYCLES(&diff_cycles)
		time.SCOPED_TICK_DURATION(&diff_time)
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
		f64(diff_time) / f64(repeat_count),
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
	if ODIN_OS == .Windows {
		win.SetConsoleOutputCP(win.CP_UTF8)
	}
	for index := 0; true; index += 1 {
		sb: strings.Builder
		fmt.sbprintfln(&sb, "")
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
			measure(&sb, _case.name, _case.f, index)
		}
		fmt.print(strings.to_string(sb))
		strings.builder_destroy(&sb)
		time.sleep(10 * time.Millisecond)
	}
}
