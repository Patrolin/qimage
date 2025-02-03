package time_utils
import "../os"
import "base:intrinsics"
import "core:fmt"
import win "core:sys/windows"

// time, cycles
Duration :: distinct int
NANOSECOND :: Duration(1)
MICROSECOND :: Duration(1e3)
MILLISECOND :: Duration(1e6)
SECOND :: Duration(1e9)
as :: #force_inline proc(duration: Duration, unit: Duration) -> f64 {
	return f64(duration) / f64(unit)
}
when ODIN_OS == .Windows {
	time :: proc() -> (nanoseconds: Duration) {
		counter: win.LARGE_INTEGER
		win.QueryPerformanceCounter(&counter)
		return Duration(int(counter) * (int(SECOND) / os.info._time_divisor))
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

sleep_exact :: proc(ns: Duration) {
	start_time := time()
	OS_THREAD_FREQUENCY :: 500 * MICROSECOND
	for diff := time() - start_time; diff > OS_THREAD_FREQUENCY; {
		win.Sleep(u32(diff / OS_THREAD_FREQUENCY))
	}
	for diff := time() - start_time; diff > 0; {
		// noop
	}
	// TODO: test this
	fmt.printfln("got: %v\nexp:", time() - start_time, ns)
}
