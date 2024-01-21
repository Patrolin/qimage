package lib_windows
import coreWin "core:sys/windows"

GetLastError :: coreWin.GetLastError
ExitProcess :: coreWin.ExitProcess
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(window: HWND, body: coreWin.LPCSTR, title: coreWin.LPCSTR, type: UINT) ---
}

LOWORD :: coreWin.LOWORD
HIWORD :: coreWin.HIWORD
string_to_wstring :: coreWin.utf8_to_wstring
wstring_to_string :: proc(str: wstring, allocator := context.temp_allocator) -> string {
	res, err := coreWin.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
