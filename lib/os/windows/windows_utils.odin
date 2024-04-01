package lib_windows
import win "core:sys/windows"

GetLastError :: win.GetLastError
ExitProcess :: win.ExitProcess
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(window: HWND, body: win.LPCSTR, title: win.LPCSTR, type: UINT) ---
}

LOWORD :: win.LOWORD
HIWORD :: win.HIWORD
stringToWstring :: win.utf8_to_wstring
wstringToString :: proc(str: wstring, allocator := context.temp_allocator) -> string {
	res, err := win.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
GetSystemMetrics :: win.GetSystemMetrics
getCursorPos :: proc() -> (pos: POINT) {
	win.GetCursorPos(&pos)
	return
}
