package lib_paint
import "../alloc"
import "../file"
import "../math"
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

FrameBuffer :: struct {
	data:   []u32 `fmt:"p"`, // MEM: BGRA?
	width:  i16,
	height: i16,
}
// NOTE: you would want to simd and multithread these
resizeFrameBuffer :: proc(frameBuffer: ^FrameBuffer, width, height: i16) {
	prev_buffer := frameBuffer^
	new_data_size := int(width) * int(height) * 4
	new_data_buffer := alloc.pageAlloc(new_data_size) // NOTE: width and height should never be zero
	frameBuffer.data = ([^]u32)(&new_data_buffer[0])[:int(width) * int(height)]
	frameBuffer.width = width
	frameBuffer.height = height
	if prev_buffer.data != nil {
		copyFrameBuffer(prev_buffer, frameBuffer^)
		alloc.pageFree(&prev_buffer.data[0])
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
