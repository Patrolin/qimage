package file
import "../math"
import "core:fmt"
import "core:os"
import "core:strings"

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
		image.width = i16(bitmapHeader.width)
		image.height = i16(bitmapHeader.height)
		image.channels = i16(bitmapHeader.bitsPerPixel / 8)
		// TODO!: reuse the space used for the file as image space
		image.data = make([]u8, image.width * image.height * image.channels)
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
	data_size := int(image.width) * int(image.height) * int(image.channels)
	for i := 0; i < data_size; i += 1 {
		image.data[i] = buffer[int(bmpFile.bitmapOffset) + i]
	}
	return
}
loadBmp :: proc {
	loadBmp_fromFileName,
	loadBmp_fromBuffer,
}

// TODO?: bypass default allocators
// TODO?: LRU file cache (evictAsNecessary() on load) - hmh 132
