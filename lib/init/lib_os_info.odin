package lib_init
OsInfo :: struct {
	timer_resolution:   f64,
	page_size:          int,
	large_page_size:    int,
	logical_core_count: int,
}
os_info: OsInfo
