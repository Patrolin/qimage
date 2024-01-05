package assets

import con "../lib_console"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

readFile :: proc(
	fileName: string,
	allocator := context.temp_allocator,
) -> (
	data: []u8,
	success: bool,
) {
	return os.read_entire_file(fileName, allocator = allocator)
}

Image :: struct {
	data:                    [^]u8,
	width, height, channels: int,
}
// TODO: hmh day 37 fix bmp loading
loadBmp_fromFileName :: proc(fileName: string) -> Image {
	file, ok := readFile(fileName)
	assert(ok)
	return loadBmp_fromBuffer(file)
}
loadBmp_fromBuffer :: proc(image: []u8) -> (result: Image) {
	bmpFile := (^BMP_File)(&image[0])
	result.data = &image[bmpFile.bitmapOffset]
	if (bmpFile.fileType == "BM") {
		coreHeader := bmpFile.bitmapHeader.WIN3
		result.width = int(coreHeader.width)
		result.height = int(coreHeader.height)
		result.channels = int(coreHeader.bitsPerPixel / 8)
	} else {
		coreHeader := bmpFile.bitmapHeader.WIN2
		result.width = int(coreHeader.width)
		result.height = int(coreHeader.height)
		result.channels = int(coreHeader.planes)
	}
	return
}
loadBmp :: proc {
	loadBmp_fromFileName,
	loadBmp_fromBuffer,
}

tprintImage :: proc(image: Image, x, y, width, height: int) -> string {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	for Y := y; (Y < y + height) && (Y < image.height); Y += 1 {
		for X := x; (X < x + width) && X < image.width; X += 1 {
			if X > x {
				fmt.sbprintf(&str, ", ")
			}
			pixel: [^]u8 = &image.data[X * image.channels + Y * image.width * image.channels]
			fmt.sbprintf(&str, "%v", pixel[0])
			for c := 1; c < image.channels; c += 1 {
				fmt.sbprintf(&str, " %v", pixel[c])
			}
		}
		fmt.sbprintf(&str, "\n")
	}
	return strings.to_string(str)
}
