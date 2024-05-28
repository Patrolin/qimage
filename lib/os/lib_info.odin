package lib_os

os_info: struct {
	_time_divisor:      f64,
	page_size:          int,
	large_page_size:    int,
	logical_core_count: int,
}
