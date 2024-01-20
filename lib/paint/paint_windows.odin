package lib_paint
import "../alloc"
import "../file"
import "core:fmt"
import coreWin "core:sys/windows"

WORD :: coreWin.WORD
HWND :: coreWin.HWND
HDC :: coreWin.HDC
POINT :: coreWin.POINT
RECT :: coreWin.RECT
BITMAPINFO :: coreWin.BITMAPINFO
BITMAPINFOHEADER :: coreWin.BITMAPINFOHEADER
PAINTSTRUCT :: coreWin.PAINTSTRUCT

BI_RGB :: coreWin.BI_RGB
DIB_RGB_COLORS :: coreWin.DIB_RGB_COLORS
SRCCOPY :: coreWin.SRCCOPY

GetDC :: coreWin.GetDC
ReleaseDC :: coreWin.ReleaseDC
BeginPaint :: coreWin.BeginPaint
PatBlt :: coreWin.PatBlt
EndPaint :: coreWin.EndPaint
CreateCompatibleDC :: coreWin.CreateCompatibleDC
CreateDIBSection :: coreWin.CreateDIBSection
StretchDIBits :: coreWin.StretchDIBits
DeleteObject :: coreWin.DeleteObject
GetClientRect :: coreWin.GetClientRect
GetWindowRect :: coreWin.GetWindowRect

ImageBuffer :: struct {
	info:        BITMAPINFO,
	using image: file.Image,
}
resizeImageBuffer :: proc(imageBuffer: ^ImageBuffer, width, height: u16) {
	prevBuffer := ImageBuffer {
		data   = imageBuffer.data,
		width  = imageBuffer.width,
		height = imageBuffer.height,
	}
	imageBuffer.info.bmiHeader.biSize = size_of(BITMAPINFOHEADER)
	imageBuffer.info.bmiHeader.biPlanes = 1
	imageBuffer.info.bmiHeader.biBitCount = u16(32)
	imageBuffer.info.bmiHeader.biCompression = BI_RGB
	imageBuffer.info.bmiHeader.biWidth = i32(width)
	imageBuffer.info.bmiHeader.biHeight = i32(height) // NOTE: bottom-up DIB
	//imageBuffer.info.bmiHeader.biHeight = -i32(height) // NOTE: top-down DIB
	imageBuffer.channels = 4
	bitmapDataSize := uint(width) * uint(height) * uint(imageBuffer.channels)
	imageBuffer.data = ([^]u32)(&alloc.page_alloc(bitmapDataSize)[0]) // NOTE: width and height should never be zero
	imageBuffer.width = width
	imageBuffer.height = height
	if prevBuffer.data != nil {
		// TODO: stretch previous
		copyImageBufferToImageBuffer(prevBuffer, imageBuffer^)
		alloc.page_free(prevBuffer.data)
	}
}
copyImageBufferToImageBuffer :: proc(from: ImageBuffer, to: ImageBuffer) {
	for y := 0; y < int(to.height) && y < int(from.height); y += 1 {
		for x := 0; x < int(to.width) && x < int(from.width); x += 1 {
			to.data[y * int(to.width) + x] = from.data[y * int(from.width) + x]
		}
	}
}

Window :: struct {
	handle:        HWND,
	dc:            HDC,
	width, height: u16,
}
copyImageBufferToWindow :: proc(imageBuffer: ^ImageBuffer, window: Window, dc: HDC) {
	StretchDIBits(
		dc,
		0,
		0,
		i32(window.width),
		i32(window.height),
		0,
		0,
		i32(imageBuffer.width),
		i32(imageBuffer.height),
		imageBuffer.data,
		&imageBuffer.info,
		DIB_RGB_COLORS,
		SRCCOPY,
	)
}
