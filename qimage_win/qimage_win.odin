// odin run qimage_win -subsystem:windows
package main
import "../common/assets"
import "../common/constants"
import con "../lib/console"
import file "../lib/file"
import win "../lib/windows"
import gl "../lib/windows/gl"
import "core:fmt"
import "core:runtime"

WINDOW_CLASS_NAME :: constants.WINDOW_CLASS_NAME
WINDOW_TITLE :: constants.WINDOW_TITLE
WINDOW_WIDTH :: constants.WINDOW_WIDTH
WINDOW_HEIGHT :: constants.WINDOW_HEIGHT

isRunning := false
image: file.Image

main :: proc() {
	windowClass := win.makeWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.utf8_to_wstring(WINDOW_TITLE, allocator = context.allocator)
	window := win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)
	dc := win.GetDC(window)
	initOpenGL(dc)
	image = assets.loadImage("test_image.bmp")
	con.print(image)
	con.print(file.tprintImage(image, 0, 0, 3, 3))
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
		con.print(fmt.ctprintf("WM_SIZE\n"))
		x, y, width, height := getClientBox(window)
		resizeDIBSection(width, height)
		renderToBuffer()
	case win.WM_PAINT:
		con.print(fmt.ctprintf("WM_PAINT\n"))
		paint: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(window, &paint)
		x := paint.rcPaint.left
		width := paint.rcPaint.right - x
		y := paint.rcPaint.top
		height := paint.rcPaint.bottom - y
		swapBuffers(dc, x, y, width, height)
		win.EndPaint(window, &paint)
	case win.WM_DESTROY:
		con.print(fmt.ctprintf("WM_DESTROY\n"))
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

// NOTE: WS_EX_LAYERED -> alpha channel?
// TODO: tell OpenGL we want sRGB - handmade hero 236-241
// TODO: allow cropping svgs
// TODO: 1D LUTs + 16x16x16 3D LUTs?
// TODO: handle WM_SYSKEYUP/DOWN, WM_KEYUP/DOWN
// TODO: how do IMGUI?
// TODO: load windows screenshots
