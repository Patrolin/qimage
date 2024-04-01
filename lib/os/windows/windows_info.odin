package lib_windows
import "../../math"
import "core:os"
import win "core:sys/windows"

foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	@(private)
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
}
time :: proc() -> f64 {
	counter: LARGE_INTEGER
	win.QueryPerformanceCounter(&counter)
	return f64(counter) / info.query_performance_frequency
}
HeapAlloc :: win.HeapAlloc
HeapFree :: win.HeapFree
HeapReAlloc :: win.HeapReAlloc

WindowsInfo :: struct {
	is_initialized:              bool,
	query_performance_frequency: f64,
	process_heap:                HANDLE,
	min_page_size:               int,
	min_page_size_mask:          int,
	min_large_page_size:         int,
	min_large_page_size_mask:    int,
}
info: WindowsInfo
initInfo :: proc() {
	if (info.is_initialized) {
		return
	}
	// fmt.print()
	ATTACH_PARENT_PROCESS :: transmute(DWORD)i32(-1)
	STD_INPUT_HANDLE :: transmute(DWORD)i32(-10)
	STD_OUTPUT_HANDLE :: transmute(DWORD)i32(-11)
	STD_ERROR_HANDLE :: transmute(DWORD)i32(-12)
	AttachConsole(ATTACH_PARENT_PROCESS)
	os.stdin = os.Handle(win.GetStdHandle(STD_INPUT_HANDLE))
	os.stdout = os.Handle(win.GetStdHandle(STD_OUTPUT_HANDLE))
	os.stderr = os.Handle(win.GetStdHandle(STD_ERROR_HANDLE))
	// time()
	query_performance_frequency: LARGE_INTEGER
	assert(bool(win.QueryPerformanceFrequency(&query_performance_frequency)))
	info.query_performance_frequency = f64(query_performance_frequency)
	// TODO?: should you even do this? (do we ever need to sleep?)
	assert(win.timeBeginPeriod(1) == win.TIMERR_NOERROR) // set min sleep timeout (from 15ms) to 1ms
	// HeapAlloc()
	info.process_heap = win.GetProcessHeap()
	// pageAlloc()
	systemInfo: win.SYSTEM_INFO
	win.GetSystemInfo(&systemInfo)
	info.min_page_size = int(systemInfo.dwAllocationGranularity)
	info.min_page_size_mask = int(math.upperBitsMask(math.ctz(uint(info.min_page_size))))
	// NOTE: windows large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
	info.min_large_page_size = int(win.GetLargePageMinimum())
	info.min_large_page_size_mask = int(
		math.upperBitsMask(math.ctz(uint(info.min_large_page_size))),
	)
	info.is_initialized = true
}
