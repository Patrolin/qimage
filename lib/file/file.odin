package file
import "../math"
import "core:fmt"
import "core:os"
import "core:strings"

readFile :: proc(fileName: string) -> (data: []u8, success: bool) {
	// TODO?: write this is win api, and use page_alloc (for big files)
	return os.read_entire_file(fileName, allocator = context.temp_allocator)
}

Image :: struct {
	data:                    []u8 `fmt:"p"`, // stored as V, RGB or RGBA
	width, height, channels: i16,
}
tprintImage :: proc(image: Image, x, y, width, height: int) -> string {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	for Y := y; (Y < y + height) && (Y < int(image.height)); Y += 1 {
		for X := x; (X < x + width) && X < int(image.width); X += 1 {
			if X > x {
				fmt.sbprintf(&str, ", ")
			}
			pixel := image.data[X + Y * int(image.width)]
			fmt.sbprintf(&str, "% 3i", (pixel >> 24) & 0xff)
			for c := 2; c >= 0; c -= 1 {
				fmt.sbprintf(&str, " % 3i", (pixel >> uint(c * 8)) & 0xff)
			}
		}
		fmt.sbprintf(&str, "\n")
	}
	return strings.to_string(str)
}
