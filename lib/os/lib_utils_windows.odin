package lib_os
import "../math"
import "core:fmt"
import win "core:sys/windows"

// bytes
LOWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v & 0xffff)}
HIWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v >> 16)}
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
getWindowRect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	window_rect: win.RECT
	win.GetWindowRect(window_handle, &window_rect)
	return math.relativeRect(
		{window_rect.left, window_rect.top, window_rect.right, window_rect.bottom},
	)
}
getClientRect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	client_rect: win.RECT
	win.GetClientRect(window_handle, &client_rect)
	return math.relativeRect(
		{client_rect.left, client_rect.top, client_rect.right, client_rect.bottom},
	)
}
getCursorPos :: proc() -> math.i32x2 {
	pos: win.POINT
	win.GetCursorPos(&pos)
	return {pos.x, pos.y}
}
getCursorMove :: proc(rawMove: math.i32x2) -> math.i32x2 {
	speed: i32 // NOTE: 1-20
	acceleration: [3]i32 // NOTE: [0, 0, 0] or [6, 10, 1]
	win.SystemParametersInfoW(win.SPI_GETMOUSESPEED, 0, &speed, 0)
	win.SystemParametersInfoW(win.SPI_GETMOUSE, 0, &acceleration, 0)
	x := doMouseAcceleration(rawMove.x, speed, acceleration)
	y := doMouseAcceleration(rawMove.y, speed, acceleration)
	return {x, y}
}
@(private)
doMouseAcceleration :: #force_inline proc "contextless" (
	raw_value: i32,
	speed: i32,
	acceleration: [3]win.c_int,
) -> i32 {
	value := raw_value * speed
	if acceleration[2] > 0 && abs(raw_value) >= acceleration[0] {
		value *= 2
		if acceleration[2] == 2 && abs(raw_value) >= acceleration[0] {
			value *= 2
		}
	}
	return value
}
