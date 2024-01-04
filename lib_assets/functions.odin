package assets

import "core:c"

// TODO: hmh day 37 fix bmp loading
readBmp :: proc(imageData: [^]u8, len: int) -> (width, height, channels: int, data: [^]u8) {
	bmpFile := (^BMP_File)(imageData)
	if (bmpFile.fileType == "BM") {
		coreHeader := bmpFile.bitmapHeader.(BMP_WIN3_BITMAPINFOHEADER)
		width = int(coreHeader.width)
		height = int(coreHeader.height)
		channels = int(coreHeader.planes)
	} else {
		coreHeader := bmpFile.bitmapHeader.(BMP_WIN2_BITMAPCOREHEADER)
		width = int(coreHeader.width)
		height = int(coreHeader.height)
		channels = int(coreHeader.planes)
	}
	data = &imageData[bmpFile.bitmapOffset]
	return
}
