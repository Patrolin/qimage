// odin run min_cpu_renderer -subsystem:windows
package main

import win "../windows"
import "core:fmt"
import "core:runtime"

WINDOW_CLASS_NAME :: "min_cpu_renderer_windowClass"
TITLE :: "min_cpu_renderer"
WIDTH :: 1366
HEIGHT :: 768

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
	//instance := win.HANDLE(win.GetModuleHandleW(nil))
	windowClass := win.WNDCLASSEXW {
		cbSize        = size_of(win.WNDCLASSEXW),
		style         = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC,
		lpfnWndProc   = messageHandler,
		lpszClassName = win.utf8_to_wstring(WINDOW_CLASS_NAME),
	}

	initialRect := win.RECT{0, 0, WIDTH, HEIGHT}
	win.AdjustWindowRectEx(&initialRect, win.WS_OVERLAPPEDWINDOW, win.FALSE, 0)
	initialWidth := initialRect.right - initialRect.left
	initialHeight := initialRect.bottom - initialRect.top

	if win.RegisterClassExW(&windowClass) != 0 {
		title_w := win.utf8_to_wstring(TITLE)
		window := win.CreateWindowExW(
			0,
			windowClass.lpszClassName,
			title_w,
			win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
			win.CW_USEDEFAULT,
			win.CW_USEDEFAULT,
			initialWidth,
			initialHeight,
			nil,
			nil,
			nil,
			nil,
		)
		if window != nil {
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
		win.print(fmt.ctprintf("WM_SIZE\n"))
		x, y, width, height := getClientBox(window)
		resizeDIBSection(width, height)
		renderToBuffer()
	case win.WM_PAINT:
		win.print(fmt.ctprintf("WM_PAINT\n"))
		paint: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(window, &paint)
		x := paint.rcPaint.left
		width := paint.rcPaint.right - x
		y := paint.rcPaint.top
		height := paint.rcPaint.bottom - y
		copyBufferToWindow(dc, x, y, width, height)
		win.EndPaint(window, &paint)
	case win.WM_DESTROY:
		win.print(fmt.ctprintf("WM_DESTROY\n"))
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
		win.free(renderBuffer.data)
	}
	renderBuffer.bytesPerPixel = 4
	renderBuffer.info.bmiHeader.biSize = size_of(win.BITMAPINFOHEADER)
	renderBuffer.info.bmiHeader.biPlanes = 1
	renderBuffer.info.bmiHeader.biBitCount = renderBuffer.bytesPerPixel * 8
	renderBuffer.info.bmiHeader.biCompression = win.BI_RGB
	renderBuffer.info.bmiHeader.biWidth = width
	renderBuffer.info.bmiHeader.biHeight = -height // top-down DIB
	bitmapDataSize := uint(width) * uint(height) * uint(renderBuffer.bytesPerPixel)
	renderBuffer.data = ([^]u32)(win.alloc(bitmapDataSize))
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
			// register: xxRRGGBB, memory: BBGGRRxx
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

// NOTE: layered window -> alpha channel?
// NOTE: vsync via directXOutput.WaitForVBlank()? / win.DwmFlush()?
// NOTE: casey says use D3D11/Metal: https://guide.handmadehero.org/code/day570/#7492
// NOTE: casey not using OpenGL: https://guide.handmadehero.org/code/day655/#10552
