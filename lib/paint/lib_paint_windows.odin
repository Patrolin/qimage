package lib_paint
import "../file"
import "../init"
import "../math"
import "core:fmt"
import win "core:sys/windows"

HWND :: win.HWND
HDC :: win.HDC
BITMAPINFO :: win.BITMAPINFO
BITMAPINFOHEADER :: win.BITMAPINFOHEADER
PAINTSTRUCT :: win.PAINTSTRUCT

BI_RGB :: win.BI_RGB
DIB_RGB_COLORS :: win.DIB_RGB_COLORS
SRCCOPY :: win.SRCCOPY

GetDC :: win.GetDC
ReleaseDC :: win.ReleaseDC
BeginPaint :: win.BeginPaint
PatBlt :: win.PatBlt
EndPaint :: win.EndPaint
CreateCompatibleDC :: win.CreateCompatibleDC
CreateDIBSection :: win.CreateDIBSection
StretchDIBits :: win.StretchDIBits
DeleteObject :: win.DeleteObject
GetClientRect :: win.GetClientRect
GetWindowRect :: win.GetWindowRect

FrameBuffer :: struct {
	data:   []u32 `fmt:"p"`, // MEM: BGRA?
	width:  i16,
	height: i16,
}
// NOTE: you would want to simd and multithread these
resizeFrameBuffer :: proc(frameBuffer: ^FrameBuffer, width, height: i16) {
	prev_buffer := frameBuffer^
	new_data_size := int(width) * int(height) * 4
	new_data_buffer := init.pageAlloc(math.bytes(new_data_size))
	frameBuffer.data = ([^]u32)(&new_data_buffer[0])[:int(width) * int(height)] // NOTE: width and height should never be zero
	frameBuffer.width = width
	frameBuffer.height = height
	if prev_buffer.data != nil {
		copyFrameBuffer(prev_buffer, frameBuffer^)
		init.pageFree(&prev_buffer.data[0])
	}
}
copyFrameBuffer :: proc(from: FrameBuffer, to: FrameBuffer) {
	for y := 0; y < int(to.height) && y < int(from.height); y += 1 {
		for x := 0; x < int(to.width) && x < int(from.width); x += 1 {
			to.data[y * int(to.width) + x] = from.data[y * int(from.width) + x]
		}
	}
}
packRGBA_v4 :: proc(frameBuffer: FrameBuffer, x, y: int, rgba: math.v4) {
	bgra :=
		((u32(rgba.b) & 0xff << 0) |
			(u32(rgba.g) & 0xff << 8) |
			(u32(rgba.r) & 0xff << 16) |
			(u32(rgba.a) & 0xff << 24))
	stride := int(frameBuffer.width)
	frameBuffer.data[y * stride + x] = bgra
}
packRGBA_v4i :: proc(frameBuffer: FrameBuffer, x, y: int, rgba: math.v4i) {
	bgra :=
		((u32(rgba.b) & 0xff << 0) |
			(u32(rgba.g) & 0xff << 8) |
			(u32(rgba.r) & 0xff << 16) |
			(u32(rgba.a) & 0xff << 24))
	stride := int(frameBuffer.width)
	frameBuffer.data[y * stride + x] = bgra
}
packRGBA :: proc {
	packRGBA_v4,
	packRGBA_v4i,
}
unpackRGBA :: proc(frameBuffer: FrameBuffer, x, y: int) -> math.v4 {
	stride := int(frameBuffer.width)
	bgra := frameBuffer.data[y * stride + x]
	return(
		math.v4 {
			f32((bgra >> 16) & 0xff),
			f32((bgra >> 8) & 0xff),
			f32((bgra >> 0) & 0xff),
			f32((bgra >> 24) & 0xff),
		} \
	)
}

Window :: struct {
	handle:        HWND,
	dc:            HDC,
	width, height: u16,
}
copyFrameBufferToWindow :: proc(frameBuffer: FrameBuffer, window: Window, dc: HDC) {
	imageInfo := BITMAPINFO{}
	imageInfo.bmiHeader = {
		biSize        = size_of(BITMAPINFOHEADER),
		biPlanes      = 1,
		biBitCount    = u16(32),
		biCompression = BI_RGB,
		biWidth       = i32(frameBuffer.width),
		biHeight      = -i32(frameBuffer.height), // NOTE: top-down DIB
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
		i32(frameBuffer.width),
		i32(frameBuffer.height),
		&frameBuffer.data[0],
		&imageInfo,
		DIB_RGB_COLORS,
		SRCCOPY,
	)
}
