// odin run qimage_win.odin -file -subsystem:windows
package main

import "core:fmt"
import "core:runtime"
import win "windows"

WINDOW_CLASS_NAME :: "qimage_window_class"
TITLE :: "QImage"
WIDTH :: 1366
HEIGHT :: 768

isRunning := false
bitmapInfo := win.BITMAPINFO{
	bmiHeader = win.BITMAPINFOHEADER{
		biSize = size_of(win.BITMAPINFOHEADER),
		biPlanes = 1,
		biBitCount = 32,
		biCompression = win.BI_RGB,
	},
}
bitmapData: win.LPVOID
bitmap: win.HBITMAP
bitmapDc: win.HDC

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
				msg: win.MSG
				for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
					win.TranslateMessage(&msg)
					win.DispatchMessageW(&msg)
					if msg.message == win.WM_QUIT {
						isRunning = false
					}
				}
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
		ResizeDIBSection(clientWidth, clientHeight)
	case win.WM_PAINT:
		win.print(fmt.ctprintf("WM_PAINT\n"))
		paint: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(window, &paint)
		x := paint.rcPaint.left
		width := paint.rcPaint.right - x
		y := paint.rcPaint.top
		height := paint.rcPaint.bottom - y
		PaintWindow(dc, x, y, width, height)
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

ResizeDIBSection :: proc(width, height: i32) {
	if bitmap != nil {
		win.DeleteObject(win.HGDIOBJ(bitmap))
	}
	if bitmapDc == nil {
		bitmapDc = win.CreateCompatibleDC(nil)
	}
	bitmapInfo.bmiHeader.biWidth = width
	bitmapInfo.bmiHeader.biHeight = height
	bitmap = win.CreateDIBSection(
		bitmapDc,
		&bitmapInfo,
		win.DIB_RGB_COLORS,
		&bitmapData,
		nil,
		0
	)
}
PaintWindow :: proc(dc: win.HDC, x, y, width, height: i32) {
	win.StretchDIBits(dc, x, y, width, height, x, y, width, height, bitmapData, &bitmapInfo, win.DIB_RGB_COLORS, win.SRCCOPY)
}
