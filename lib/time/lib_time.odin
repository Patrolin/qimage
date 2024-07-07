package lib_time
import "../os"
import "base:intrinsics"
import win "core:sys/windows"

seconds :: proc(value: $T) -> T {return value}
millis :: proc(value: $T) -> T {return value * 1e3}
micros :: proc(value: $T) -> T {return value * 1e6}
nanos :: proc(value: $T) -> T {return value * 1e9}
when ODIN_OS == .Windows {
	time :: proc() -> (seconds: f64) {
		counter: win.LARGE_INTEGER
		win.QueryPerformanceCounter(&counter)
		return f64(counter) / os.info._time_divisor
	}
}

mfence :: #force_inline proc() {
	intrinsics.atomic_thread_fence(.Seq_Cst)
}
// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
cycles :: #force_inline proc() -> int {
	return int(intrinsics.read_cycle_counter())
}
@(deferred_in_out = _SCOPED_CYCLES_END)
SCOPED_CYCLES :: proc(diff_cycles: ^int) -> (start_cycles: int) {
	mfence()
	start_cycles = cycles()
	mfence()
	return
}
@(private)
_SCOPED_CYCLES_END :: proc(diff_cycles: ^int, start_cycles: int) {
	mfence()
	diff_cycles^ = int(cycles() - start_cycles)
	mfence()
}

@(deferred_in_out = _SCOPED_TIME_END)
SCOPED_TIME :: proc(diff_time: ^f64) -> (start_time: f64) {
	mfence()
	start_time = time()
	mfence()
	return
}
@(private)
_SCOPED_TIME_END :: proc(diff_time: ^f64, start_time: f64) {
	mfence()
	diff_time^ = time() - start_time
	mfence()
}
