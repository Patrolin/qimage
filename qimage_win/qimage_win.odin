// odin run qimage_win -subsystem:windows
package main

import win "../lib_windows"
import "core:fmt"
import "core:runtime"
import gl "vendor:OpenGL"

WINDOW_CLASS_NAME :: "qimage_windowClass"
TITLE :: "QImage"
WIDTH :: 1366
HEIGHT :: 768

isRunning := false

main :: proc() {
	windowClass := win.WNDCLASSEXW {
		cbSize        = size_of(win.WNDCLASSEXW),
		style         = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC,
		lpfnWndProc   = messageHandler,
		lpszClassName = win.utf8_to_wstring(WINDOW_CLASS_NAME), // TODO: allocate this permanently
	}
	title_w := win.utf8_to_wstring(TITLE, allocator = context.allocator)

	// TODO: https://stackoverflow.com/questions/27928254/adjustwindowrectex-and-getwindowrect-give-wrong-size-with-ws-overlapped
	initialRect := win.RECT{0, 0, WIDTH, HEIGHT}
	win.AdjustWindowRectEx(&initialRect, win.WS_OVERLAPPEDWINDOW, win.FALSE, 0)
	initialWidth := initialRect.right - initialRect.left
	initialHeight := initialRect.bottom - initialRect.top

	if win.RegisterClassExW(&windowClass) != 0 {
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
			initOpenGL(dc)
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
				swapBuffers(dc, x, y, width, height)
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
		swapBuffers(dc, x, y, width, height)
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

initOpenGL :: proc(dc: win.HDC) {
	desiredPixelFormat := win.PIXELFORMATDESCRIPTOR {
		nSize      = size_of(win.PIXELFORMATDESCRIPTOR),
		nVersion   = 1,
		iPixelType = win.PFD_TYPE_RGBA,
		dwFlags    = win.PFD_SUPPORT_OPENGL | win.PFD_DRAW_TO_WINDOW | win.PFD_DOUBLEBUFFER,
		cRedBits   = 8,
		cGreenBits = 8,
		cBlueBits  = 8,
		cAlphaBits = 8,
		iLayerType = win.PFD_MAIN_PLANE,
	}
	pixelFormatIndex := win.ChoosePixelFormat(dc, &desiredPixelFormat)
	pixelFormat: win.PIXELFORMATDESCRIPTOR
	win.DescribePixelFormat(dc, pixelFormatIndex, size_of(win.PIXELFORMATDESCRIPTOR), &pixelFormat)
	win.SetPixelFormat(dc, pixelFormatIndex, &pixelFormat)
	glRc := win.wglCreateContext(dc)
	// NOTE: win.wglCreateContextAttrib(...) for gl 3.0+
	if win.wglMakeCurrent(dc, glRc) {
		win.print(fmt.ctprintf("%v\n", pixelFormat))
	} else {
		assert(false)
	}
}
resizeDIBSection :: proc(width, height: win.LONG) {
	// NOTE: clear to black / stretch previous / copy previous?
	win.glViewport(0, 0, u32(width), u32(height))
}
renderToBuffer :: proc() {
	win.glClearColor(.5, 0, .5, 1)
	win.glClear(gl.COLOR_BUFFER_BIT)
}
swapBuffers :: proc(dc: win.HDC, x, y, width, height: win.LONG) {
	win.SwapBuffers(dc)
}

// NOTE: layered window -> alpha channel?
// TODO: tell OpenGL we want sRGB - handmade hero 236-241
// TODO: allow cropping svgs
