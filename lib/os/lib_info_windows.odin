package lib_os
import "../math"
import "core:fmt"
import core_os "core:os"
import win "core:sys/windows"

foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	@(private)
	AttachConsole :: proc(dwProcessId: win.DWORD) -> win.BOOL ---
	@(private)
	ExitThread :: proc(dwExitCode: win.DWORD) ---
}

initOsInfo :: proc "contextless" () {
	context = emptyContext()
	// console
	ATTACH_PARENT_PROCESS :: transmute(win.DWORD)i32(-1)
	STD_INPUT_HANDLE :: transmute(win.DWORD)i32(-10)
	STD_OUTPUT_HANDLE :: transmute(win.DWORD)i32(-11)
	STD_ERROR_HANDLE :: transmute(win.DWORD)i32(-12)
	AttachConsole(ATTACH_PARENT_PROCESS)
	core_os.stdin = core_os.Handle(win.GetStdHandle(STD_INPUT_HANDLE))
	core_os.stdout = core_os.Handle(win.GetStdHandle(STD_OUTPUT_HANDLE))
	core_os.stderr = core_os.Handle(win.GetStdHandle(STD_ERROR_HANDLE))
	win.SetConsoleOutputCP(win.CP_UTF8)
	// _time_divisor
	query_performance_frequency: win.LARGE_INTEGER
	assert(bool(win.QueryPerformanceFrequency(&query_performance_frequency)))
	os_info._time_divisor = f64(query_performance_frequency)
	assert(win.timeBeginPeriod(1) == win.TIMERR_NOERROR) // set min sleep timeout (from 15ms) to 1ms
	// page_size, large_page_size
	systemInfo: win.SYSTEM_INFO
	win.GetSystemInfo(&systemInfo)
	os_info.page_size = int(systemInfo.dwAllocationGranularity)
	os_info.large_page_size = int(win.GetLargePageMinimum()) // NOTE: windows large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
	// logical_core_count
	system_info: win.SYSTEM_INFO
	win.GetSystemInfo(&system_info)
	os_info.logical_core_count = int(system_info.dwNumberOfProcessors) // NOTE: this cannot go above 64
	// window_border
	window_border: win.RECT
	win.AdjustWindowRectEx(&window_border, win.WS_OVERLAPPEDWINDOW, win.FALSE, 0)
	os_info.window_border = {
		-window_border.left,
		-window_border.top,
		window_border.right,
		window_border.bottom,
	}
}

seconds :: proc(value: $T) -> T {return value}
millis :: proc(value: $T) -> T {return value * 1e3}
micros :: proc(value: $T) -> T {return value * 1e6}
nanos :: proc(value: $T) -> T {return value * 1e9}
time :: proc() -> (seconds: f64) {
	counter: win.LARGE_INTEGER
	win.QueryPerformanceCounter(&counter)
	return f64(counter) / os_info._time_divisor
}
@(deferred_in_out = _scoped_time_end)
SCOPED_TIME :: proc(diff_time: ^f64) -> (start_time: f64) {
	mfence()
	start_time = time()
	mfence()
	return
}
@(private)
_scoped_time_end :: proc(diff_time: ^f64, start_time: f64) {
	mfence()
	diff_time^ = time() - start_time
	mfence()
}
