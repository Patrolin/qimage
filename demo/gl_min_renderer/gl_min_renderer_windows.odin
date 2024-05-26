// odin run demo/gl_min_renderer -subsystem:windows
package main

import "../../lib/gl"
import "../../lib/init"
import "../../lib/math"
import win "../../lib/windows"
import "core:fmt"
import "core:runtime"

WINDOW_TITLE :: "gl_min_renderer"
WINDOW_WIDTH :: 1366
WINDOW_HEIGHT :: 768

isRunning := false
window: gl.Window

main :: proc() {
	context = init.init()
	windowClass := win.registerWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.stringToWstring(WINDOW_TITLE, allocator = context.allocator)
	window = gl.Window {
		handle = win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT),
		width  = WINDOW_WIDTH,
		height = WINDOW_HEIGHT,
		dc     = gl.GetDC(window.handle),
	}
	gl.initOpenGL(window.dc)
	t := init.time()
	prev_t := t
	i := 0
	max_ddt := 0.0
	frame_time_prev_t := t
	for isRunning = true; isRunning; {
		dt := t - prev_t
		i += 1
		if (i > 20) {
			max_ddt = max(max_ddt, abs(math.millis(dt) - 16.6666666666666666666))
		}
		win.processMessages() // NOTE: this blocks while sizing
		frame_time_msg_t := init.time()
		updateAndRender()
		frame_time_t := init.time()
		fmt.printf(
			"dt: %v ms, max_ddt: %v ms, frame_msg_time: %v ms, frame_render_time: %v ms\n",
			math.millis(dt),
			max_ddt,
			math.millis(frame_time_msg_t - frame_time_prev_t),
			math.millis(frame_time_t - frame_time_msg_t),
		)

		prev_t = t
		t = win.doVsyncBadly() // TODO: vsync via opengl?
		frame_time_prev_t = init.time()
		gl.renderImageBufferToWindow(window.dc)
		free_all(context.temp_allocator)
	}
}

// NOTE: this blocks the main thread
messageHandler :: proc "stdcall" (
	windowHandle: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> (
	result: win.LRESULT,
) {
	context = init.defaultContext()
	result = 0
	switch message {
	case win.WM_SIZE:
		fmt.println("WM_SIZE")
		window.handle = windowHandle
		window.width = win.LOWORD(u32(lParam))
		window.height = win.HIWORD(u32(lParam))
		gl.resizeImageBuffer(window.width, window.height)
	case win.WM_PAINT:
		fmt.println("WM_PAINT")
		ps: gl.PAINTSTRUCT
		dc: win.HDC = gl.BeginPaint(windowHandle, &ps)
		gl.renderImageBufferToWindow(dc)
		gl.EndPaint(windowHandle, &ps)
	case win.WM_DESTROY:
		fmt.println("WM_DESTROY")
		//win.PostQuitMessage(0)
		isRunning = false
	case:
		result = win.DefWindowProcW(windowHandle, message, wParam, lParam)
	}
	free_all(context.temp_allocator)
	return
}

updateAndRender :: proc() {
	// NOTE: this takes 0.005 ms
	gl.glClearColor(.5, .5, 1, 1)
	gl.glClear(gl.COLOR_BUFFER_BIT)
	// NOTE: render image here (hmh 237-238)
}

// TODO!: tell OpenGL we want sRGB - handmade hero 236-241
// NOTE: hmh 240: DisplayBitmapViaOpenGL() https://guide.handmadehero.org/code/day240/#1497
// NOTE: enable vsync via wglSwapIntervalExt(1)
// NOTE: are we able to disable vsync? https://guide.handmadehero.org/code/day549/#1043
