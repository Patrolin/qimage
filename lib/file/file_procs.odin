package file
import "../math"
import "core:fmt"
import "core:os"
import "core:strings"

readFile :: proc(fileName: string) -> (data: []u8, success: bool) {
	// TODO: write this is win api, and use page_alloc (for big files)
	return os.read_entire_file(fileName, allocator = context.temp_allocator)
}

// TODO: load into existing buffer
Image :: struct {
	data:                    [^]u32,
	width, height, channels: u16,
}
@(private)
copyRGBAImage :: proc(data: [^]u8, image: ^Image) {
	for y := 0; y < int(image.width); y += 1 {
		for x := 0; x < int(image.height); x += 1 {
			i := (x + y * int(image.width)) * int(image.channels)
			rgba := math.v4i{u16(data[i]), u16(data[i + 1]), u16(data[i + 2]), 0xff}
			if image.channels == 4 {
				rgba.a = u16(data[i + 3])
			}
			image.data[x + y * int(image.width)] = math.pack_rgba(rgba)
		}
	}
}

loadBmp_fromFileName :: proc(fileName: string) -> Image {
	file, ok := readFile(fileName)
	assert(ok)
	return loadBmp_fromBuffer(file)
}
loadBmp_fromBuffer :: proc(buffer: []u8) -> (image: Image) {
	bmpFile := (^BMP_File)(&buffer[0])
	bitmapHeaderSize := bmpFile.bitmapHeader.BITMAPCOREHEADER.size
	switch (bitmapHeaderSize) {
	case size_of(BMP_BITMAPV5HEADER):
		bitmapHeader := &bmpFile.bitmapHeader.BITMAPV5HEADER
		image.width = u16(bitmapHeader.width)
		image.height = u16(bitmapHeader.height)
		image.channels = u16(bitmapHeader.bitsPerPixel / 8)
		image.data = make([^]u32, image.width * image.height)
		assert(image.height >= 0, "Negative height is not supported")
		assert(bitmapHeader.compression == 0, "Compression is not supported")
		// NOTE: we ignore bV5XPelsPerMeter, bV5YPelsPerMeter, bV5ClrUsed, bV5ClrImportant
		assert(
			(bitmapHeader.bV5RedMask > bitmapHeader.bV5GreenMask) &&
			(bitmapHeader.bV5GreenMask > bitmapHeader.bV5BlueMask) &&
			(bitmapHeader.bV5BlueMask > bitmapHeader.bV5AlphaMask),
			"Unsupported format",
		)
		// NOTE: sRGB has a gamma correction
		assert(bitmapHeader.bV5CSType == LCS_sRGB, "Unsupported colorspace")
	// NOTE: we ignore bV5Intent, bV5ProfileData, bV5ProfileSize
	// con.print(bitmapHeader)
	case:
		assert(false, fmt.tprintf("Unsupported bitmapHeader size: %v", bitmapHeaderSize))
	}
	copyRGBAImage(&buffer[bmpFile.bitmapOffset], &image)
	return
}
loadBmp :: proc {
	loadBmp_fromFileName,
	loadBmp_fromBuffer,
}

// TODO: just printImage()
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

// TODO: alloc once at startup?: https://www.youtube.com/playlist?list=PLEMXAbCVnmY7m1ynIpTaEWQ6j7NGS2cCA
// TODO: bypass default allocators?
// TODO: LRU file cache (evictAsNecessary() on load) - hmh 132?
