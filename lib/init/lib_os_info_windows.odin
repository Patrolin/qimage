package lib_init
import "../math"
import "core:os"
import win "core:sys/windows"

foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	@(private)
	AttachConsole :: proc(dwProcessId: win.DWORD) -> win.BOOL ---
}

initOsInfo :: proc "contextless" () {
	context = emptyContext()
	ATTACH_PARENT_PROCESS :: transmute(win.DWORD)i32(-1)
	STD_INPUT_HANDLE :: transmute(win.DWORD)i32(-10)
	STD_OUTPUT_HANDLE :: transmute(win.DWORD)i32(-11)
	STD_ERROR_HANDLE :: transmute(win.DWORD)i32(-12)
	AttachConsole(ATTACH_PARENT_PROCESS)
	os.stdin = os.Handle(win.GetStdHandle(STD_INPUT_HANDLE))
	os.stdout = os.Handle(win.GetStdHandle(STD_OUTPUT_HANDLE))
	os.stderr = os.Handle(win.GetStdHandle(STD_ERROR_HANDLE))
	// time()
	query_performance_frequency: win.LARGE_INTEGER
	assert(bool(win.QueryPerformanceFrequency(&query_performance_frequency)))
	os_info.timer_resolution = f64(query_performance_frequency)
	assert(win.timeBeginPeriod(1) == win.TIMERR_NOERROR) // set min sleep timeout (from 15ms) to 1ms
	// pageAlloc()
	systemInfo: win.SYSTEM_INFO
	win.GetSystemInfo(&systemInfo)
	os_info.page_size = int(systemInfo.dwAllocationGranularity)
	os_info.large_page_size = int(win.GetLargePageMinimum()) // NOTE: windows large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
	// core count
	system_info: win.SYSTEM_INFO
	win.GetSystemInfo(&system_info)
	os_info.logical_core_count = int(system_info.dwNumberOfProcessors) // NOTE: this cannot go above 64
}
time :: proc() -> f64 {
	counter: win.LARGE_INTEGER
	win.QueryPerformanceCounter(&counter)
	return f64(counter) / os_info.timer_resolution
}
