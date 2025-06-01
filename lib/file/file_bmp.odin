package file_lib
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
import "core:fmt"
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
		image.data = alloc.page_alloc(math.Size(int(image.width) * int(image.height) * int(image.channels))) // TODO: don't use page_alloc directly
		fmt.assertf(image.height >= 0, "Negative height (%v) is not supported", image.height)
		fmt.assertf(bitmapHeader.compression == 0, "Compression (%v) is not supported", bitmapHeader.compression)
		// NOTE: we ignore bV5XPelsPerMeter, bV5YPelsPerMeter, bV5ClrUsed, bV5ClrImportant
		fmt.assertf(
			(bitmapHeader.bV5RedMask > bitmapHeader.bV5GreenMask) &&
			(bitmapHeader.bV5GreenMask > bitmapHeader.bV5BlueMask) &&
			(bitmapHeader.bV5BlueMask > bitmapHeader.bV5AlphaMask),
			"Unsupported format {%v, %v, %v}",
			bitmapHeader.bV5RedMask,
			bitmapHeader.bV5GreenMask,
			bitmapHeader.bV5BlueMask,
		)
		// NOTE: sRGB has a gamma correction
		assert(bitmapHeader.bV5CSType == LCS_sRGB, "Unsupported colorspace")
	// NOTE: we ignore bV5Intent, bV5ProfileData, bV5ProfileSize
	// con.print(bitmapHeader)
	case:
		fmt.assertf(false, "Unsupported bitmapHeader size: %v", bitmapHeaderSize)
	}
	data_size := int(image.width) * int(image.height) * int(image.channels)
	for i in 0 ..< data_size {
		image.data[i] = buffer[int(bmpFile.bitmapOffset) + i]
	}
	return
}
loadBmp :: proc {
	loadBmp_fromFileName,
	loadBmp_fromBuffer,
}

// ?TODO: bypass default allocators
// ?TODO: LRU file cache (evictAsNecessary() on load) - hmh 132
