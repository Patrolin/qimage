// odin run qimage_win.odin -file -subsystem:windows
package main

import "core:fmt"
import "core:runtime"
import win "windows"

WINDOW_CLASS_NAME :: "qimage_window_class"
TITLE :: "QImage"
isRunning := true

main :: proc() {
	//hInstance := win.HANDLE(win.GetModuleHandleW(nil))
	window_class := win.WNDCLASSEXW {
		cbSize        = size_of(win.WNDCLASSEXW),
		style         = win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc   = messageHandler,
		lpszClassName = win.utf8_to_wstring(WINDOW_CLASS_NAME),
	}

	initialRect := win.RECT{0, 0, 1366, 768}
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
			for isRunning {
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
	case win.WM_ACTIVATEAPP:
		win.print(fmt.ctprintf("WM_ACTIVATEAPP\n"))
	case win.WM_SIZE:
		win.print(fmt.ctprintf("WM_SIZE\n"))
	case win.WM_DESTROY:
		win.print(fmt.ctprintf("WM_DESTROY\n"))
		win.PostQuitMessage(0)
	case win.WM_PAINT:
		win.print(fmt.ctprintf("WM_PAINT\n"))
		paint: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(window, &paint)
		x := paint.rcPaint.left
		width := paint.rcPaint.right - paint.rcPaint.left
		y := paint.rcPaint.top
		height := paint.rcPaint.bottom - paint.rcPaint.top
		win.PatBlt(dc, x, y, width, height, win.BLACKNESS)
		win.EndPaint(window, &paint)
	case:
		result = win.DefWindowProcW(window, message, wParam, lParam)
	}
	return
}
