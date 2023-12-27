package windows

import "core:c"
import coreWin "core:sys/windows"

foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	ExitProcess :: proc(exit_code: u32) ---
	GetLastError :: proc() -> DWORD ---
	GetModuleHandleW :: proc(lpModuleName: LPCWSTR) -> HMODULE ---
	OutputDebugStringA :: proc(lpOutputString: LPCSTR) ---
	AllocConsole :: proc() -> BOOL ---
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
	GetStdHandle :: proc(nStdHandle: DWORD) -> HANDLE ---
	WriteConsoleA :: proc(hConsoleOutput: HANDLE, lpBuffer: cstring, nNumberOfCharsToWrite: DWORD, lpNumberOfCharsWritten: LPDWORD, lpReserved: LPVOID) -> BOOL ---
}

foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(windowHandle: HWND, body: LPCSTR, title: LPCSTR, type: UINT) ---
	CreateWindowExW :: proc(dwExStyle: DWORD, lpClassName: LPCWSTR, lpWindowName: LPCWSTR, dwStyle: DWORD, X: c.int, Y: c.int, nWidth: c.int, nHeight: c.int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID) -> HWND ---
	RegisterClassW :: proc(windowClass: ^WNDCLASSW) -> ATOM ---
	GetMessageA :: proc(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---
	GetMessageW :: proc(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---
	TranslateMessage :: proc(lpMsg: LPMSG) -> BOOL ---
	DispatchMessageA :: proc(lpMsg: LPMSG) -> LRESULT ---
	DispatchMessageW :: proc(lpMsg: LPMSG) -> LRESULT ---
	ShowWindow :: proc(hWnd: HWND, nCmdShow: c.int) -> BOOL ---
}

utf8_to_wstring :: coreWin.utf8_to_wstring
wstring_to_utf8 :: coreWin.wstring_to_utf8

didAttachConsole := false
print :: proc(message: cstring) {
	if !didAttachConsole {
		didAttachConsole = bool(AttachConsole(ATTACH_PARENT_PROCESS))
	}
	stdout := GetStdHandle(STD_OUTPUT_HANDLE)
	WriteConsoleA(stdout, message, u32(len(message)), nil, nil)
}
