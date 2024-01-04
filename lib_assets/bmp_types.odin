package assets

BMP_File :: struct #packed {
	using fileHeader: BMP_FileHeader,
	bitmapHeader:     BMP_BitmapHeader,
}
BMP_FileHeader :: struct #packed {
	fileType:     [2]u8,
	fileSize:     u32,
	reserved1:    u16,
	reserved2:    u16,
	bitmapOffset: u32,
}
// bitmap header
BMP_BitmapHeader :: union {
	BMP_WIN2_BITMAPCOREHEADER,
	BMP_WIN3_BITMAPINFOHEADER,
}
BMP_WIN2_BITMAPCOREHEADER :: struct #packed {
	size:         u32,
	width:        u16,
	height:       u16,
	planes:       u16,
	bitsPerPixel: u16,
}
BMP_WIN3_BITMAPINFOHEADER :: struct #packed {
	size:         u32,
	width:        u32,
	height:       u32,
	planes:       u16,
	bitsPerPixel: u16,
}
