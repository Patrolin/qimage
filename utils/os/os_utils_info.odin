package lib_os
import "../math"

info: struct {
	_time_divisor:      int,
	page_size:          int,
	large_page_size:    int,
	logical_core_count: int,
	window_border:      math.AbsoluteRect,
}
