package libWindowsConsole
import "core:fmt"
import "core:os"
import coreWin "core:sys/windows"

BOOL :: coreWin.BOOL
DWORD :: coreWin.DWORD
LPDWORD :: coreWin.LPDWORD
LPVOID :: coreWin.LPVOID
wstring :: coreWin.wstring
HANDLE :: coreWin.HANDLE

ATTACH_PARENT_PROCESS :: transmute(DWORD)i32(-1)
STD_INPUT_HANDLE :: transmute(DWORD)i32(-10)
STD_OUTPUT_HANDLE :: transmute(DWORD)i32(-11)
STD_ERROR_HANDLE :: transmute(DWORD)i32(-12)

foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	AllocConsole :: proc() -> BOOL ---
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
	GetStdHandle :: proc(nStdHandle: DWORD) -> HANDLE ---
	WriteConsoleA :: proc(hConsoleOutput: HANDLE, lpBuffer: cstring, nNumberOfCharsToWrite: DWORD, lpNumberOfCharsWritten: LPDWORD, lpReserved: LPVOID) -> BOOL ---
	WriteConsoleW :: proc(hConsoleOutput: HANDLE, lpBuffer: wstring, nNumberOfCharsToWrite: DWORD, lpNumberOfCharsWritten: LPDWORD, lpReserved: LPVOID) -> BOOL ---
}

initStdout :: proc() -> os.Handle {
	AttachConsole(ATTACH_PARENT_PROCESS)
	os.stdin = os.Handle(GetStdHandle(STD_INPUT_HANDLE))
	os.stdout = os.Handle(GetStdHandle(STD_OUTPUT_HANDLE))
	os.stderr = os.Handle(GetStdHandle(STD_ERROR_HANDLE))
	return os.stdout
}

string_to_wstring :: coreWin.utf8_to_wstring
wstring_to_string :: proc(str: wstring, allocator := context.temp_allocator) -> string {
	res, err := coreWin.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
