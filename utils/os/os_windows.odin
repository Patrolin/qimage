package os_utils
import "../math"
import "core:fmt"
import "core:strings"
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
win_stringToWstring :: win.utf8_to_wstring
@(private)
win_wstringToString_nullTerminated :: proc(str: [^]win.WCHAR, allocator := context.temp_allocator) -> string {
	res, err := win.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
@(private)
win_wstringToString_slice :: proc(str: []win.WCHAR, allocator := context.temp_allocator) -> string {
	res, err := win.wstring_to_utf8(raw_data(str), len(str), allocator = allocator)
	return res
}
win_wstringToString :: proc {
	win_wstringToString_nullTerminated,
	win_wstringToString_slice,
}
win_getLastErrorMessage :: proc() -> (error: u32, error_message: string) {
	error = win.GetLastError()
	error_message = ""
	buffer: [64]win.WCHAR
	format_result := win.FormatMessageW(
		win.FORMAT_MESSAGE_FROM_SYSTEM | win.FORMAT_MESSAGE_IGNORE_INSERTS,
		nil,
		error,
		0,
		&buffer[0],
		len(buffer),
		nil,
	)
	if format_result != 0 {
		error_message = win_wstringToString(&buffer[0])
		if strings.ends_with(error_message, "\r\n") {
			error_message = error_message[:len(error_message) - 2]
		}
	} else {
		error_message = "BUFFER_TOO_SMALL_FOR_ERROR_MESSAGE"
	}
	return
}
// other
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	@(link_name = "MessageBoxA")
	win_MessageBoxA :: proc(window: win.HWND, body: win.LPCSTR, title: win.LPCSTR, type: win.UINT) ---
}
// rects
win_getMonitorRect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	monitor := win.MonitorFromWindow(window_handle, win.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST)
	info := win.MONITORINFO {
		cbSize = size_of(win.MONITORINFO),
	}
	assert(bool(win.GetMonitorInfoW(monitor, &info)))
	monitor_rect := info.rcMonitor
	return math.relativeRect({monitor_rect.left, monitor_rect.top, monitor_rect.right, monitor_rect.bottom})
}
win_getWindowRect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	window_rect: win.RECT
	win.GetWindowRect(window_handle, &window_rect)
	return math.relativeRect({window_rect.left, window_rect.top, window_rect.right, window_rect.bottom})
}
win_getClientRect :: proc(window_handle: win.HWND, window_rect: math.RelativeRect) -> math.RelativeRect {
	win_client_rect: win.RECT
	win.GetClientRect(window_handle, &win_client_rect)
	window_border := info.window_border
	return {
		window_rect.left + window_border.left,
		window_rect.top + window_border.top,
		win_client_rect.right - win_client_rect.left,
		win_client_rect.bottom - win_client_rect.top,
	}
}
// cursor
win_getCursorPos :: proc() -> math.i32x2 {
	pos: win.POINT
	win.GetCursorPos(&pos)
	return {pos.x, pos.y}
}
