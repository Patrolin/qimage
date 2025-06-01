// odin run demo/perf/cycles -o:speed
package demo_perf_cycles
import "../../../utils/math"
import "../../../utils/os"
import "../../../utils/time"
import "base:intrinsics"
import "core:fmt"
import "core:strings"

TimingCase :: struct($T: typeid) {
	name:           string,
	f:              proc(v: T) -> T,
	break_before:   bool,
	average_cycles: f64,
	average_time:   f64,
	run_count:      int,
}
timingCase :: proc($T: typeid, name: string, f: proc(v: T) -> T, break_before := false) -> TimingCase(T) {
	return TimingCase(T){name, f, break_before, 0, 0, 0}
}
printCase :: proc($T: typeid, sb: ^strings.Builder, _case: TimingCase(T)) {
	if _case.break_before {
		fmt.sbprintln(sb)
	}
	run_count_string := ""
	if _case.run_count > 1000 {
		run_count_string = fmt.aprintf("%.0e", f64(_case.run_count), allocator = context.temp_allocator)
	} else {
		run_count_string = fmt.aprintf("%v", _case.run_count, allocator = context.temp_allocator)
	}
	fmt.sbprintfln(sb, "%v: %.2f cy, %.0f ns, %v runs", _case.name, _case.average_cycles, time.nanos(_case.average_time), run_count_string)
}
printCasesEnd :: proc(sb: ^strings.Builder) {
	fmt.sbprintfln(sb, "")
	fmt.print(strings.to_string(sb^))
	strings.builder_destroy(sb)
}
measureCold :: proc($T: typeid, _cases: []TimingCase(T)) {
	sb: strings.Builder
	for &_case in _cases {
		acc: [1]T // NOTE: make compiler not optimize away our function calls
		diff_cycles: int
		diff_time: f64 // NOTE: windows only gives us precision of 100 ns per sample
		{
			time.SCOPED_TIME(&diff_time)
			time.SCOPED_CYCLES(&diff_cycles)
			acc[0] += _case.f(int(_case.run_count))
		}
		intrinsics.atomic_load(&acc[0])
		run_count := f64(_case.run_count)
		_case.average_cycles = (_case.average_cycles * run_count + f64(diff_cycles)) / (run_count + 1)
		_case.average_time = (_case.average_time * run_count + diff_time) / (run_count + 1)
		_case.run_count += 1
		printCase(T, &sb, _case)
	}
	printCasesEnd(&sb)
}
measureHot :: proc($T: typeid, _cases: []TimingCase(T)) {
	sb: strings.Builder
	for &_case in _cases {
		acc: [1]T // NOTE: make compiler not optimize away our function calls
		diff_cycles: int
		diff_time: f64
		REPEAT_COUNT :: 1e8
		for j in 0 ..= 1 { 	// NOTE: we run twice so the code is in cache
			time.SCOPED_TIME(&diff_time)
			time.SCOPED_CYCLES(&diff_cycles)
			for i in 0 ..< REPEAT_COUNT {
				acc[0] += _case.f(T(i))
			}
		}
		intrinsics.atomic_load(&acc[0])
		run_count := f64(_case.run_count)
		_case.average_cycles = (_case.average_cycles * run_count + f64(diff_cycles)) / (run_count + REPEAT_COUNT)
		_case.average_time = (_case.average_time * run_count + diff_time) / (run_count + REPEAT_COUNT)
		_case.run_count += REPEAT_COUNT
		printCase(T, &sb, _case)
	}
	printCasesEnd(&sb)
}
main :: proc() {
	// ?TODO: rewrite everything in test_case: testCase = TestCase()
	os.initInfo()
	for {
		fmt.println()
		measureCold(int, cold_int_cases)
		measureHot(int, hot_int_cases)
		measureHot(f16, hot_f16_cases)
		measureHot(f32, hot_f32_cases)
		measureHot(f64, hot_f64_cases)
		fmt.println(" ------------------------ ")
		free_all(context.temp_allocator)
	}
}
