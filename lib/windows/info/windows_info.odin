package lib_windows_info
import "core:os"
import coreWin "core:sys/windows"

BOOL :: coreWin.BOOL
DWORD :: coreWin.DWORD
HANDLE :: coreWin.HANDLE
LARGE_INTEGER :: coreWin.LARGE_INTEGER

ATTACH_PARENT_PROCESS :: transmute(DWORD)i32(-1)
STD_INPUT_HANDLE :: transmute(DWORD)i32(-10)
STD_OUTPUT_HANDLE :: transmute(DWORD)i32(-11)
STD_ERROR_HANDLE :: transmute(DWORD)i32(-12)
TIMERR_NOERROR :: coreWin.TIMERR_NOERROR

foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	AllocConsole :: proc() -> BOOL ---
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
	GetStdHandle :: proc(nStdHandle: DWORD) -> HANDLE ---
}
QueryPerformanceFrequency :: coreWin.QueryPerformanceFrequency
timeBeginPeriod :: coreWin.timeBeginPeriod

WindowsInfo :: struct {
	query_performance_frequency: f64,
}
initWindowsInfo :: proc(info: ^WindowsInfo) {
	AttachConsole(ATTACH_PARENT_PROCESS)
	os.stdin = os.Handle(GetStdHandle(STD_INPUT_HANDLE))
	os.stdout = os.Handle(GetStdHandle(STD_OUTPUT_HANDLE))
	os.stderr = os.Handle(GetStdHandle(STD_ERROR_HANDLE))
	query_performance_frequency: LARGE_INTEGER
	assert(bool(QueryPerformanceFrequency(&query_performance_frequency)))
	info.query_performance_frequency = f64(query_performance_frequency)
	// TODO: should you even do this? (do we ever need to sleep?)
	assert(timeBeginPeriod(1) == TIMERR_NOERROR) // set min sleep timeout (from 15ms) to 1ms
}
