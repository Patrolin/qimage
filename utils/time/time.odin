package time_utils
import "../mem"
import "../os"
import "../test"
import "base:intrinsics"
import "core:fmt"
import win "core:sys/windows"
import "core:testing"
import core_time "core:time"

// time, cycles
Duration :: core_time.Duration
NANOSECOND :: Duration(1)
MICROSECOND :: Duration(1e3)
MILLISECOND :: Duration(1e6)
SECOND :: Duration(1e9)
as :: #force_inline proc(duration: Duration, unit: Duration) -> f64 {
	return f64(duration) / f64(unit)
}
time :: proc() -> (nanoseconds: Duration) {
	when ODIN_OS == .Windows {
		counter: win.LARGE_INTEGER
		win.QueryPerformanceCounter(&counter)
		return Duration(int(counter) * (int(SECOND) / os.info._time_divisor))
	} else {
		#assert(false, "Not implemented")
	}
}
CycleCount :: distinct int
// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
cycles :: #force_inline proc() -> CycleCount {
	return CycleCount(intrinsics.read_cycle_counter())
}

// SCOPED_TIME
@(deferred_in_out = _SCOPED_TIME_END)
SCOPED_TIME :: proc(diff_time: ^Duration) -> (start_time: Duration) {
	mem.mfence()
	start_time = time()
	mem.mfence()
	return
}
@(private)
_SCOPED_TIME_END :: proc(diff_time: ^Duration, start_time: Duration) {
	mem.mfence()
	diff_time^ = time() - start_time
	mem.mfence()
}
// SCOPED_CYCLES
@(deferred_in_out = _SCOPED_CYCLES_END)
SCOPED_CYCLES :: proc(diff_cycles: ^CycleCount) -> (start_cycles: CycleCount) {
	mem.mfence()
	start_cycles = cycles()
	mem.mfence()
	return
}
@(private)
_SCOPED_CYCLES_END :: proc(diff_cycles: ^CycleCount, start_cycles: CycleCount) {
	mem.mfence()
	diff_cycles^ = cycles() - start_cycles
	mem.mfence()
}

sleep_ns :: proc(ns: Duration) {
	when ODIN_OS == .Windows {
		end_time := time() + ns
		diff := end_time - time()
		//fmt.printfln("  0: %v ns", diff)
		OS_PREEMPT_FREQUENCY :: 500 * MICROSECOND
		MAX_OS_THREAD_WAIT :: 3 * OS_PREEMPT_FREQUENCY
		for diff > MAX_OS_THREAD_WAIT {
			ms_to_sleep := max(0, diff / MILLISECOND - 2)
			win.Sleep(u32(ms_to_sleep))
			diff = end_time - time()
			//fmt.printfln("1.a: %v ns (slept for %v ms)", diff, ms_to_sleep)
		}
		for diff > 0 {
			intrinsics.cpu_relax()
			diff = end_time - time()
		}
		//fmt.printfln("  2: %v ns", diff)
		test.expectf(diff == 0, "diff: %v", diff)
	} else {
		#assert(false, "Not implemented")
	}
}
