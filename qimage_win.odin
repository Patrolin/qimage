// odin run qimage_win.odin -file -subsystem:windows
package main

import "core:fmt"
import "core:runtime"
import win "windows"

WINDOW_CLASS_NAME :: "qimage_window_class"
TITLE :: "QImage"
WIDTH :: 1366
HEIGHT :: 768
BYTES_PER_PIXEL :: 4

isRunning := false
bitmapInfo := win.BITMAPINFO {
	bmiHeader = win.BITMAPINFOHEADER {
		biSize = size_of(win.BITMAPINFOHEADER),
		biPlanes = 1,
		biBitCount = BYTES_PER_PIXEL * 8,
		biCompression = win.BI_RGB,
	},
}
bitmapData: [^]u8
bitmapSize: win.POINT

main :: proc() {
	//instance := win.HANDLE(win.GetModuleHandleW(nil))
	window_class := win.WNDCLASSEXW {
		cbSize        = size_of(win.WNDCLASSEXW),
		style         = win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc   = messageHandler,
		lpszClassName = win.utf8_to_wstring(WINDOW_CLASS_NAME),
	}

	initialRect := win.RECT{0, 0, WIDTH, HEIGHT}
	win.AdjustWindowRectEx(&initialRect, win.WS_OVERLAPPEDWINDOW, win.FALSE, 0)
	initialWidth := initialRect.right - initialRect.left
	initialHeight := initialRect.bottom - initialRect.top

	if win.RegisterClassExW(&window_class) != 0 {
		title_w := win.utf8_to_wstring(TITLE)
		window := win.CreateWindowExW(
			0,
			window_class.lpszClassName,
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
			for isRunning = true; isRunning; {
				for msg: win.MSG; win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE); {
					if msg.message == win.WM_QUIT {
						isRunning = false
					}
					win.TranslateMessage(&msg)
					win.DispatchMessageW(&msg)
				}
				renderToBitmap()
				dc := win.GetDC(window)
				clientRect: win.RECT
				win.GetClientRect(window, &clientRect)
				blitBitmapToWindow(dc, clientRect)
				win.ReleaseDC(window, dc)
			}
		}
	}
}

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
		clientRect: win.RECT
		win.GetClientRect(window, &clientRect)
		clientWidth := clientRect.right - clientRect.left
		clientHeight := clientRect.bottom - clientRect.top
		resizeDIBSection(clientWidth, clientHeight)
		renderToBitmap()
	case win.WM_PAINT:
		win.print(fmt.ctprintf("WM_PAINT\n"))
		paint: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(window, &paint)
		blitBitmapToWindow(dc, paint.rcPaint)
		win.EndPaint(window, &paint)
	case win.WM_DESTROY:
		win.print(fmt.ctprintf("WM_DESTROY\n"))
		//win.PostQuitMessage(0)
		isRunning = false
	case:
		result = win.DefWindowProcW(window, message, wParam, lParam)
	}
	return
}

resizeDIBSection :: proc(width, height: i32) {
	if bitmapData != nil {
		bitmapSize = {
			x = 0,
			y = 0,
		}
		win.free(bitmapData)
		bitmapData = nil
	}
	bitmapInfo.bmiHeader.biWidth = width
	bitmapInfo.bmiHeader.biHeight = -height // top-down DIB
	bitmapDataSize := uint(width) * uint(height) * BYTES_PER_PIXEL
	bitmapData = ([^]u8)(win.alloc(bitmapDataSize))
	bitmapSize = {
		x = width,
		y = height,
	}
	// TODO: clear to black
}
renderToBitmap :: proc() {
	stride := BYTES_PER_PIXEL
	pitch := int(bitmapSize.x) * BYTES_PER_PIXEL
	for Y := 0; Y < int(bitmapSize.y); Y += 1 {
		for X := 0; X < int(bitmapSize.x); X += 1 {
			// register: xxRRGGBB, memory: BBGGRRxx
			bitmapData[Y * pitch + X * stride] = 255
			bitmapData[Y * pitch + X * stride + 1] = 0
			bitmapData[Y * pitch + X * stride + 2] = 0
		}
	}
}
blitBitmapToWindow :: proc(dc: win.HDC, clientRect: win.RECT) {
	x := clientRect.left
	clientWidth := clientRect.right - x
	y := clientRect.top
	clientHeight := clientRect.bottom - y
	win.StretchDIBits(
		dc,
		x,
		y,
		clientWidth,
		clientHeight,
		x,
		y,
		bitmapSize.x,
		bitmapSize.y,
		bitmapData,
		&bitmapInfo,
		win.DIB_RGB_COLORS,
		win.SRCCOPY,
	)
}

// layered window -> alpha channel?
