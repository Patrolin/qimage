// odin run demo/perf/cycles -o:speed
package demo_perf_cycles
import "../../../utils/math"
import "../../../utils/os"
import "../../../utils/time"
import "base:intrinsics"
import "core:fmt"
import "core:strings"

// types
TimingCase :: struct($T: typeid) {
	name:           string,
	f:              proc(v: T) -> T,
	break_before:   bool,
	average_cycles: f64,
	average_time:   f64,
	run_count:      int,
}
timing_case :: proc($T: typeid, name: string, f: proc(v: T) -> T, break_before := false) -> TimingCase(T) {
	return TimingCase(T){name, f, break_before, 0, 0, 0}
}

// procedures
main :: proc() {
	os.init()
	for {
		// NOTE: ideally we would be #force_inline-ing every case, which could lower the timing on load_zero_int()?
		measure_cold(int, cold_int_cases)
		measure_hot(int, hot_int_cases)
		measure_hot(f16, hot_f16_cases)
		measure_hot(f32, hot_f32_cases)
		measure_hot(f64, hot_f64_cases, true)
		free_all(context.temp_allocator)
	}
}
print_case :: proc($T: typeid, sb: ^strings.Builder, _case: TimingCase(T)) {
	if _case.break_before {
		fmt.sbprintln(sb)
	}
	run_count_string := ""
	if _case.run_count > 1000 {
		run_count_string = fmt.aprintf("%.0e", f64(_case.run_count), allocator = context.temp_allocator)
	} else {
		run_count_string = fmt.aprintf("%v", _case.run_count, allocator = context.temp_allocator)
	}
	fmt.sbprintfln(sb, "%v: %.1f cy, %.1f ns, %v runs", _case.name, _case.average_cycles, _case.average_time, run_count_string)
}
print_cases_end :: proc(sb: ^strings.Builder, is_last_set_of_cases: bool) {
	fmt.sbprintfln(sb, is_last_set_of_cases ? " ------------------------ " : " ... ")
	fmt.print(strings.to_string(sb^))
	strings.builder_destroy(sb)
}
measure_cold :: proc($T: typeid, _cases: []TimingCase(T), is_last_set_of_cases := false) {
	sb: strings.Builder
	for &_case in _cases {
		acc: [1]T // NOTE: make compiler not optimize away our function calls
		diff_cycles: time.CycleCount
		diff_time: time.Duration // NOTE: windows only gives us precision of 100 ns per sample
		{
			time.scoped_time(&diff_time)
			time.scoped_cycles(&diff_cycles)
			acc[0] += _case.f(int(_case.run_count))
		}
		intrinsics.atomic_load(&acc[0])
		run_count := f64(_case.run_count)
		_case.average_cycles = (_case.average_cycles * run_count + f64(diff_cycles)) / (run_count + 1)
		_case.average_time = (_case.average_time * run_count + f64(diff_time)) / (run_count + 1)
		_case.run_count += 1
		print_case(T, &sb, _case)
	}
	print_cases_end(&sb, is_last_set_of_cases)
}
measure_hot :: proc($T: typeid, _cases: []TimingCase(T), is_last_set_of_cases := false) {
	sb: strings.Builder
	for &_case in _cases {
		acc: [1]T // NOTE: make compiler not optimize away our function calls
		diff_cycles: time.CycleCount
		diff_time: time.Duration
		REPEAT_COUNT :: 1e8
		for j in 0 ..= 1 { 	// NOTE: we run twice so the code is in cache
			time.scoped_time(&diff_time)
			time.scoped_cycles(&diff_cycles)
			for i in 0 ..< REPEAT_COUNT {
				acc[0] += _case.f(T(i))
			}
		}
		intrinsics.atomic_load(&acc[0])
		run_count := f64(_case.run_count)
		_case.average_cycles = (_case.average_cycles * run_count + f64(diff_cycles)) / (run_count + REPEAT_COUNT)
		_case.average_time = (_case.average_time * run_count + f64(diff_time)) / (run_count + REPEAT_COUNT)
		_case.run_count += REPEAT_COUNT
		print_case(T, &sb, _case)
	}
	print_cases_end(&sb, is_last_set_of_cases)
}
