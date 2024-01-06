// odin run demo/opengl/min_renderer -subsystem:windows
package main

import con "../../../lib/console"
import win "../../../lib/windows"
import gl "../../../lib/windows/gl"
import "core:fmt"
import "core:runtime"

WINDOW_CLASS_NAME :: "min_opengl_renderer_windowClass"
WINDOW_TITLE :: "min_opengl_renderer"
WINDOW_WIDTH :: 1366
WINDOW_HEIGHT :: 768

isRunning := false

main :: proc() {
	windowClass := win.makeWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.utf8_to_wstring(WINDOW_TITLE, allocator = context.allocator)
	window := win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)
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
		con.printf("WM_SIZE\n")
		x, y, width, height := getClientBox(window)
		resizeDIBSection(width, height)
		renderToBuffer()
	case win.WM_PAINT:
		con.printf("WM_PAINT\n")
		paint: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(window, &paint)
		x := paint.rcPaint.left
		width := paint.rcPaint.right - x
		y := paint.rcPaint.top
		height := paint.rcPaint.bottom - y
		swapBuffers(dc, x, y, width, height)
		win.EndPaint(window, &paint)
	case win.WM_DESTROY:
		con.printf("WM_DESTROY\n")
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
	desiredPixelFormat := gl.PIXELFORMATDESCRIPTOR {
		nSize      = size_of(gl.PIXELFORMATDESCRIPTOR),
		nVersion   = 1,
		iPixelType = gl.PFD_TYPE_RGBA,
		dwFlags    = gl.PFD_SUPPORT_OPENGL | gl.PFD_DRAW_TO_WINDOW | gl.PFD_DOUBLEBUFFER,
		cRedBits   = 8,
		cGreenBits = 8,
		cBlueBits  = 8,
		cAlphaBits = 8,
		iLayerType = gl.PFD_MAIN_PLANE,
	}
	pixelFormatIndex := gl.ChoosePixelFormat(dc, &desiredPixelFormat)
	pixelFormat: gl.PIXELFORMATDESCRIPTOR
	gl.DescribePixelFormat(dc, pixelFormatIndex, size_of(gl.PIXELFORMATDESCRIPTOR), &pixelFormat)
	gl.SetPixelFormat(dc, pixelFormatIndex, &pixelFormat)
	glRc := gl.wglCreateContext(dc)
	// NOTE: gl.wglCreateContextAttrib(...) for gl 3.0+
	if !gl.wglMakeCurrent(dc, glRc) {
		assert(false)
	}
}
resizeDIBSection :: proc(width, height: win.LONG) {
	// NOTE: clear to black / stretch previous / copy previous?
	gl.glViewport(0, 0, u32(width), u32(height))
}
renderToBuffer :: proc() {
	gl.glClearColor(.5, 0, .5, 1)
	gl.glClear(gl.COLOR_BUFFER_BIT)
	// TODO: render the image (hmh 237-238)
}
swapBuffers :: proc(dc: win.HDC, x, y, width, height: win.LONG) {
	gl.SwapBuffers(dc)
}

// NOTE: enable vsync via wglSwapIntervalExt(1)
// NOTE: are we able to disable vsync? https://guide.handmadehero.org/code/day549/#1043
