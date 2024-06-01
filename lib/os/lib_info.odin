package lib_os
import "core:intrinsics"

os_info: struct {
	_time_divisor:      f64,
	page_size:          int,
	large_page_size:    int,
	logical_core_count: int,
}
cycles :: proc() -> int {
	return int(intrinsics.read_cycle_counter())
}
