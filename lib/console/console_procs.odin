package console
import "core:fmt"

when ODIN_OS != .Windows {
	print_cstring :: proc(str: cstring) {
		fmt.print(str)
	}
	print_string :: proc(str: string) {
		fmt.print(str)
	}
	print_any :: proc(args: ..any) {
		str := fmt.aprintln(..args, allocator = context.temp_allocator)
		print(str)
	}
	print :: proc {
		print_cstring,
		print_string,
		print_any,
	}
	printf :: proc(format: string, args: ..any) {
		str := fmt.tprintf(format, args)
		print(str)
	}
}
