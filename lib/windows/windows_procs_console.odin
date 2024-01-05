package windows
import "core:fmt"
import coreWin "core:sys/windows"

utf8_to_wstring :: coreWin.utf8_to_wstring
utf8_to_utf16 :: coreWin.utf8_to_utf16
wstring_to_utf8 :: proc(str: wstring, allocator := context.temp_allocator) -> string {
	res, err := coreWin.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
utf16_to_utf8 :: coreWin.utf16_to_utf8

@(private)
didAttachConsole := false
getStdout :: proc() -> HANDLE {
	if !didAttachConsole {
		didAttachConsole = bool(AttachConsole(ATTACH_PARENT_PROCESS))
	}
	return GetStdHandle(STD_OUTPUT_HANDLE)
}
print_cstring :: proc(message: cstring) {
	WriteConsoleA(getStdout(), message, u32(len(message)), nil, nil)
}
print_string :: proc(message: string) {
	print_wstring(utf8_to_wstring(message))
}
wlen :: proc(str: wstring) -> int {
	i := 0
	for ; str[i] != 0; i += 1 {}
	return i
}
print_wstring :: proc(message: wstring) {
	WriteConsoleW(getStdout(), message, u32(wlen(message)), nil, nil)
}
print_any :: proc(args: ..any) {
	str := fmt.aprintln(..args, allocator = context.temp_allocator)
	print(str)
}
print :: proc {
	print_string,
	print_cstring,
	print_wstring,
	print_any,
}
printf :: proc(format: string, args: ..any) {
	str := fmt.tprintf(format, ..args)
	print(str)
}
