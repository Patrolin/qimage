// odin run demo/cpu/min_renderer -subsystem:windows
package main

import "../../../lib/alloc"
import win "../../../lib/windows"
import "core:fmt"
import "core:runtime"

WINDOW_CLASS_NAME :: "min_cpu_renderer_windowClass"
WINDOW_TITLE :: "min_cpu_renderer"
WINDOW_WIDTH :: 1366
WINDOW_HEIGHT :: 768

isRunning := false
RenderBuffer :: struct {
	info:          win.BITMAPINFO,
	data:          [^]u32,
	width:         i32,
	height:        i32,
	bytesPerPixel: win.WORD,
}
renderBuffer := RenderBuffer{}

main :: proc() {
	windowClass := win.makeWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.string_to_wstring(WINDOW_TITLE, allocator = context.allocator)
	window := win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)
	dc := win.GetDC(window)
	for isRunning = true; isRunning; {
		for msg: win.MSG; win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE); {
			if msg.message == win.WM_QUIT {
				isRunning = false
			}
			win.TranslateMessage(&msg)
			win.DispatchMessageW(&msg)
		}
		renderToBuffer()
		x, y, width, height := getClientBox(window)
		copyBufferToWindow(dc, x, y, width, height)
		free_all(context.temp_allocator)
	}
}

// NOTE: does this block the main thread?
messageHandler :: proc "stdcall" (
	window: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> (
	result: win.LRESULT,
) {
	context = runtime.default_context()
	result = 0
	switch message {
	case win.WM_SIZE:
		fmt.println("WM_SIZE")
		x, y, width, height := getClientBox(window)
		resizeDIBSection(width, height)
		renderToBuffer()
	case win.WM_PAINT:
		fmt.println("WM_PAINT")
		paint: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(window, &paint)
		x := paint.rcPaint.left
		width := paint.rcPaint.right - x
		y := paint.rcPaint.top
		height := paint.rcPaint.bottom - y
		copyBufferToWindow(dc, x, y, width, height)
		win.EndPaint(window, &paint)
	case win.WM_DESTROY:
		fmt.println("WM_DESTROY")
		//win.PostQuitMessage(0)
		isRunning = false
	case:
		result = win.DefWindowProcW(window, message, wParam, lParam)
	}
	free_all(context.temp_allocator)
	return
}

getClientBox :: proc(window: win.HWND) -> (x, y, width, height: win.LONG) {
	clientRect: win.RECT
	win.GetClientRect(window, &clientRect)
	x = clientRect.left
	width = clientRect.right - x
	y = clientRect.top
	height = clientRect.bottom - y
	return
}

resizeDIBSection :: proc(width, height: win.LONG) {
	if renderBuffer.data != nil {
		alloc.page_free(renderBuffer.data)
	}
	renderBuffer.bytesPerPixel = 4
	renderBuffer.info.bmiHeader.biSize = size_of(win.BITMAPINFOHEADER)
	renderBuffer.info.bmiHeader.biPlanes = 1
	renderBuffer.info.bmiHeader.biBitCount = renderBuffer.bytesPerPixel * 8
	renderBuffer.info.bmiHeader.biCompression = win.BI_RGB
	renderBuffer.info.bmiHeader.biWidth = width
	renderBuffer.info.bmiHeader.biHeight = -height // NOTE: top-down DIB
	bitmapDataSize := uint(width) * uint(height) * uint(renderBuffer.bytesPerPixel)
	renderBuffer.data = ([^]u32)(&alloc.page_alloc(bitmapDataSize)[0])
	renderBuffer.width = width
	renderBuffer.height = height
	// NOTE: clear to black / stretch previous / copy previous?
}
renderToBuffer :: proc() {
	stride := 1
	pitch := int(renderBuffer.width)
	for Y := 0; Y < int(renderBuffer.height); Y += 1 {
		for X := 0; X < int(renderBuffer.width); X += 1 {
			red: u32 = 0
			green: u32 = 0
			blue: u32 = 255
			// NOTE: register: xxRRGGBB, memory: BBGGRRxx
			BGRX := blue | (green << 8) | (red << 16)
			renderBuffer.data[Y * pitch + X * stride] = BGRX
		}
	}
}
copyBufferToWindow :: proc(dc: win.HDC, x, y, width, height: win.LONG) {
	win.StretchDIBits(
		dc,
		x,
		y,
		width,
		height,
		x,
		y,
		renderBuffer.width,
		renderBuffer.height,
		renderBuffer.data,
		&renderBuffer.info,
		win.DIB_RGB_COLORS,
		win.SRCCOPY,
	)
}

// NOTE: WS_EX_LAYERED -> alpha channel?
// NOTE: vsync via directXOutput.WaitForVBlank()? / win.DwmFlush()?
// NOTE: casey says use D3D11/Metal: https://guide.handmadehero.org/code/day570/#7492
// NOTE: casey not using OpenGL: https://guide.handmadehero.org/code/day655/#10552
// TODO: fonts (163/164): https://www.youtube.com/playlist?list=PLEMXAbCVnmY43tjaptnJW0rMP-DsXww1Y
// TODO: vsync counter demo
// NOTE: does windows render in sRGB by default? - yes, SetICMMode() to use non sRGB
// https://learn.microsoft.com/en-us/windows/win32/wcs/srgb--a-standard-color-space
// https://learn.microsoft.com/en-us/windows/win32/wcs/basic-functions-for-use-within-a-device-context
