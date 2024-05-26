// TODO: throw this in lib_init?
package lib_windows
import "../math"
import win "core:sys/windows"

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
stringToWstring :: win.utf8_to_wstring
wstringToString :: proc(str: win.wstring, allocator := context.temp_allocator) -> string {
	res, err := win.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
