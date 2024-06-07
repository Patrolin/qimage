package lib_os
import "../math"
import "core:intrinsics"

os_info: struct {
	_time_divisor:      f64,
	page_size:          int,
	large_page_size:    int,
	logical_core_count: int,
	window_border:      math.AbsoluteRect,
}
mfence :: #force_inline proc() {
	intrinsics.atomic_thread_fence(.Seq_Cst)
}
// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
cycles :: #force_inline proc() -> int {
	return int(intrinsics.read_cycle_counter())
}
@(deferred_in_out = _scoped_cycles_end)
SCOPED_CYCLES :: proc(diff_cycles: ^int) -> (start_cycles: int) {
	mfence()
	start_cycles = cycles()
	mfence()
	return
}
@(private)
_scoped_cycles_end :: proc(diff_cycles: ^int, start_cycles: int) {
	mfence()
	diff_cycles^ = int(cycles() - start_cycles)
	mfence()
}
