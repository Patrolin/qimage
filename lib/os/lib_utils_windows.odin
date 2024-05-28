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
getCursorPos :: proc() -> math.i32x2 {
	pos: win.POINT
	win.GetCursorPos(&pos)
	return {pos.x, pos.y}
}
getCursorMove :: proc(rawMove: math.i32x2) -> math.i32x2 {
	speed: int // NOTE: 1-20
	acceleration: [3]win.c_int
	win.SystemParametersInfoW(win.SPI_GETMOUSESPEED, 0, &speed, 0)
	win.SystemParametersInfoW(win.SPI_GETMOUSE, 0, &acceleration, 0)
	x := rawMove.x
	if acceleration[2] > 0 && acceleration[0] < abs(x) {
		x *= 2
	}
	if acceleration[2] == 2 && acceleration[1] < abs(x) {
		x *= 2
	}
	y := rawMove.y
	if acceleration[2] > 0 && acceleration[0] < abs(y) {
		y *= 2
	}
	if acceleration[2] == 2 && acceleration[1] < abs(y) {
		y *= 2
	}
	move := math.i32x2{x, y}
	fmt.printfln(
		"rawMove: %v, speed: %v, acceleration: %v, move: %v",
		rawMove,
		speed,
		acceleration,
		move,
	)
	return move
}
