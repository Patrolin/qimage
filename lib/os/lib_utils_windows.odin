package lib_os
import "../math"
import "core:fmt"
import win "core:sys/windows"

// bytes
LOWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v & 0xffff)}
HIWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v >> 16)}
LOIWORD :: #force_inline proc "contextless" (v: $T) -> i16 {return i16(v & 0xffff)}
HIIWORD :: #force_inline proc "contextless" (v: $T) -> i16 {return i16(v >> 16)}
MAKEWORD :: #force_inline proc "contextless" (hi, lo: u32) -> u32 {return (hi << 16) | lo}
LOBYTE :: #force_inline proc "contextless" (v: $T) -> u8 {return u8(v & 0xff)}
HIBYTE :: #force_inline proc "contextless" (v: $T) -> u8 {return u8(v >> 8)}
// wstring
stringToWstring :: win.utf8_to_wstring
@(private)
wstringToString_nullTerminated :: proc(
	str: [^]win.WCHAR,
	allocator := context.temp_allocator,
) -> string {
	res, err := win.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
@(private)
wstringToString_slice :: proc(str: []win.WCHAR, allocator := context.temp_allocator) -> string {
	res, err := win.wstring_to_utf8(raw_data(str), len(str), allocator = allocator)
	return res
}
wstringToString :: proc {
	wstringToString_nullTerminated,
	wstringToString_slice,
}
// other
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(window: win.HWND, body: win.LPCSTR, title: win.LPCSTR, type: win.UINT) ---
}
// rects
getMonitorRect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	monitor := win.MonitorFromWindow(
		window_handle,
		win.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST,
	)
	info := win.MONITORINFO {
		cbSize = size_of(win.MONITORINFO),
	}
	assert(bool(win.GetMonitorInfoW(monitor, &info)))
	monitor_rect := info.rcMonitor
	return math.relativeRect(
		{monitor_rect.left, monitor_rect.top, monitor_rect.right, monitor_rect.bottom},
	)
}
getWindowRect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	window_rect: win.RECT
	win.GetWindowRect(window_handle, &window_rect)
	return math.relativeRect(
		{window_rect.left, window_rect.top, window_rect.right, window_rect.bottom},
	)
}
getClientRect :: proc(
	window_handle: win.HWND,
	window_rect: math.RelativeRect,
) -> math.RelativeRect {
	win_client_rect: win.RECT
	win.GetClientRect(window_handle, &win_client_rect)
	window_border := os_info.window_border
	return {
		window_rect.left + window_border.left,
		window_rect.top + window_border.top,
		win_client_rect.right - win_client_rect.left,
		win_client_rect.bottom - win_client_rect.top,
	}
}
// cursor
getCursorPos :: proc() -> math.i32x2 {
	pos: win.POINT
	win.GetCursorPos(&pos)
	return {pos.x, pos.y}
}
