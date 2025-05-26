package file_lib
import "../../utils/math"
import "core:fmt"
import "core:os" // TODO: remove this
import "core:strings"

readFile :: proc(fileName: string) -> (data: []u8, success: bool) {
	// TODO?: write this is win api
	return os.read_entire_file(fileName, allocator = context.temp_allocator)
}

Image :: struct {
	data:                    []u8 `fmt:"p"`, // stored as V, RGB or RGBA
	width, height, channels: i16,
}
printImage :: proc(image: Image, x_start, y_start, width, height: int) {
	sb := strings.builder_make(allocator = context.temp_allocator)
	fmt.sbprintfln(&sb, "%v at (%v, %v, %v, %v)", image, x_start, y_start, width, height)
	x_end := x_start + int(width)
	y_end := y_start + int(height)
	for y in y_start ..< y_end {
		for x in x_start ..< x_end {
			if x > x_start {
				fmt.sbprintf(&sb, "; ")
			}
			pixel := image.data[x + y * int(image.width)]
			fmt.sbprintf(&sb, "% 3i", (pixel >> 24) & 0xff)
			for c := 2; c >= 0; c -= 1 {
				fmt.sbprintf(&sb, " % 3i", (pixel >> uint(c * 8)) & 0xff)
			}
		}
		fmt.sbprintf(&sb, "\n")
	}
	fmt.print(strings.to_string(sb))
}
