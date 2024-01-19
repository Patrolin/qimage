package lib_windows
import coreWin "core:sys/windows"

string_to_wstring :: coreWin.utf8_to_wstring
wstring_to_string :: proc(str: wstring, allocator := context.temp_allocator) -> string {
	res, err := coreWin.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}