package lib_file
import win "core:sys/windows"

LONG :: win.LONG
FXPT2DOT30 :: win.LONG
CIEXYZ :: struct {
	ciexyzX, ciexyzY, ciexyzZ: FXPT2DOT30,
}
CIEXYZTRIPLE :: struct {
	ciexyzRed, ciexyzGreen, ciexyzBlue: CIEXYZ,
}

LCS_CALIBRATED_RGB :: 0x00000000
LCS_sRGB :: 0x73524742
LCS_WINDOWS_COLOR_SPACE :: 0x57696E20

LCS_GM_BUSINESS :: 0x00000001 //         "saturation" - preserve saturation
LCS_GM_GRAPHICS :: 0x00000002 //         "relative colorimetric" - reduce saturation
LCS_GM_IMAGES :: 0x00000004 //           "perceptual" - preserve contrast
LCS_GM_ABS_COLORIMETRIC :: 0x00000008 // "absolute colorimetric" - clip to boundary

// types
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
BMP_BitmapHeader :: struct #raw_union {
	BITMAPCOREHEADER: BMP_BITMAPCOREHEADER,
	BITMAPV5HEADER:   BMP_BITMAPV5HEADER,
}
BMP_BITMAPCOREHEADER :: struct #packed {
	size:         u32,
	width:        u16,
	height:       u16,
	planes:       u16,
	bitsPerPixel: u16,
}
BMP_BITMAPV5HEADER :: struct #packed {
	size:             u32,
	width:            u32,
	height:           u32,
	planes:           u16,
	bitsPerPixel:     u16,
	compression:      u32,
	imageSize:        u32,
	bV5XPelsPerMeter: LONG,
	bV5YPelsPerMeter: LONG,
	bV5ClrUsed:       u32,
	bV5ClrImportant:  u32,
	bV5RedMask:       u32,
	bV5GreenMask:     u32,
	bV5BlueMask:      u32,
	bV5AlphaMask:     u32,
	bV5CSType:        u32,
	bV5Endpoints:     CIEXYZTRIPLE,
	bV5GammaRed:      u32,
	bV5GammaGreen:    u32,
	bV5GammaBlue:     u32,
	bV5Intent:        u32,
	bV5ProfileData:   u32,
	bV5ProfileSize:   u32,
	bV5Reserved:      u32,
}
