package lib_windows
import "../math"
import "core:os"
import coreWin "core:sys/windows"

foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	@(private)
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
}
time :: proc() -> f64 {
	counter: LARGE_INTEGER
	coreWin.QueryPerformanceCounter(&counter)
	return f64(counter) / windows_info.query_performance_frequency
}
HeapAlloc :: coreWin.HeapAlloc
HeapFree :: coreWin.HeapFree
HeapReAlloc :: coreWin.HeapReAlloc

WindowsInfo :: struct {
	query_performance_frequency: f64,
	process_heap:                HANDLE,
	min_page_size:               uint,
	min_page_size_mask:          uint,
	min_large_page_size:         uint,
	min_large_page_size_mask:    uint,
}
windows_info: WindowsInfo
initWindowsInfo :: proc() {
	// fmt.print()
	ATTACH_PARENT_PROCESS :: transmute(DWORD)i32(-1)
	STD_INPUT_HANDLE :: transmute(DWORD)i32(-10)
	STD_OUTPUT_HANDLE :: transmute(DWORD)i32(-11)
	STD_ERROR_HANDLE :: transmute(DWORD)i32(-12)
	AttachConsole(ATTACH_PARENT_PROCESS)
	os.stdin = os.Handle(coreWin.GetStdHandle(STD_INPUT_HANDLE))
	os.stdout = os.Handle(coreWin.GetStdHandle(STD_OUTPUT_HANDLE))
	os.stderr = os.Handle(coreWin.GetStdHandle(STD_ERROR_HANDLE))
	// time()
	query_performance_frequency: LARGE_INTEGER
	assert(bool(coreWin.QueryPerformanceFrequency(&query_performance_frequency)))
	windows_info.query_performance_frequency = f64(query_performance_frequency)
	// TODO?: should you even do this? (do we ever need to sleep?)
	assert(coreWin.timeBeginPeriod(1) == coreWin.TIMERR_NOERROR) // set min sleep timeout (from 15ms) to 1ms
	// HeapAlloc()
	windows_info.process_heap = coreWin.GetProcessHeap()
	// pageAlloc()
	systemInfo: coreWin.SYSTEM_INFO
	coreWin.GetSystemInfo(&systemInfo)
	windows_info.min_page_size = uint(systemInfo.dwAllocationGranularity)
	windows_info.min_page_size_mask = math.maskUpperBits(math.ctz(windows_info.min_page_size))
	// NOTE: windows large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
	windows_info.min_large_page_size = coreWin.GetLargePageMinimum()
	windows_info.min_large_page_size_mask = math.maskUpperBits(
		math.ctz(windows_info.min_large_page_size),
	)
}
