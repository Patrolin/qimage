package lib_paint
import "../alloc"
import "../file"
import "core:fmt"
import coreWin "core:sys/windows"

HWND :: coreWin.HWND
HDC :: coreWin.HDC
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

resizeImage :: proc(image: ^file.Image, width, height: u16) {
	prev_image := image^
	new_data_size := uint(width) * uint(height) * uint(image.channels)
	image.data = ([^]u32)(&alloc.pageAlloc(new_data_size)[0]) // NOTE: width and height should never be zero
	image.width = width
	image.height = height
	if prev_image.data != nil {
		copyImage(prev_image, image^)
		alloc.pageFree(prev_image.data)
	}
}
copyImage :: proc(from: file.Image, to: file.Image) {
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
copyImageToWindow :: proc(image: file.Image, window: Window, dc: HDC) {
	imageInfo := BITMAPINFO{}
	imageInfo.bmiHeader = {
		biSize        = size_of(BITMAPINFOHEADER),
		biPlanes      = 1,
		biBitCount    = u16(32),
		biCompression = BI_RGB,
		biWidth       = i32(image.width),
		biHeight      = -i32(image.height), // NOTE: top-down DIB
		//biHeight = i32(image.height), // NOTE: bottom-up DIB
	}
	StretchDIBits(
		dc,
		0,
		0,
		i32(window.width),
		i32(window.height),
		0,
		0,
		i32(image.width),
		i32(image.height),
		image.data,
		&imageInfo,
		DIB_RGB_COLORS,
		SRCCOPY,
	)
}
