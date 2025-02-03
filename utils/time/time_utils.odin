package time_utils
import "../os"
import "base:intrinsics"
import "core:fmt"
import win "core:sys/windows"
import "core:testing"

// time, cycles
Duration :: distinct int
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
mfence :: #force_inline proc() {
	intrinsics.atomic_thread_fence(.Seq_Cst)
}
// SCOPED_TIME, SCOPED_CYCLES
@(deferred_in_out = _SCOPED_TIME_END)
SCOPED_TIME :: proc(diff_time: ^Duration) -> (start_time: Duration) {
	mfence()
	start_time = time()
	mfence()
	return
}
@(private)
_SCOPED_TIME_END :: proc(diff_time: ^Duration, start_time: Duration) {
	mfence()
	diff_time^ = time() - start_time
	mfence()
}
@(deferred_in_out = _SCOPED_CYCLES_END)
SCOPED_CYCLES :: proc(diff_cycles: ^CycleCount) -> (start_cycles: CycleCount) {
	mfence()
	start_cycles = cycles()
	mfence()
	return
}
@(private)
_SCOPED_CYCLES_END :: proc(diff_cycles: ^CycleCount, start_cycles: CycleCount) {
	mfence()
	diff_cycles^ = cycles() - start_cycles
	mfence()
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
		fmt.assertf(diff == 0, "diff: %v", diff)
	} else {
		#assert(false, "Not implemented")
	}
}
@(test)
test_sleep_ns :: proc(t: ^testing.T) {
	// TODO: test random amounts to sleep?
	for i := 0; i < 5; i += 1 {
		sleep_ns(4 * MILLISECOND)
	}
}
