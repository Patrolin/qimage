// odin run demo/cpu/min_renderer -subsystem:windows
// odin run demo/cpu/min_renderer -subsystem:windows -o:speed
package main

import "../../../lib/file"
import "../../../lib/init"
import "../../../lib/math"
import "../../../lib/paint"
import win "../../../lib/windows"
import "core:fmt"
import "core:runtime"
import "core:sys/windows"

WINDOW_TITLE :: "cpu_min_renderer"
WINDOW_WIDTH :: 1366
WINDOW_HEIGHT :: 768

isRunning := false
frame_buffer := paint.FrameBuffer{} // NOTE: copying the frameBuffer is very slow, so we instead we store it in an OS specific format
window: paint.Window

foobar := false
main :: proc() {
	context = init.init()
	windowClass := win.registerWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.stringToWstring(WINDOW_TITLE, allocator = context.allocator)
	win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)
	window.dc = paint.GetDC(window.handle)
	t := init.time()
	prev_t := t
	i := 0
	max_ddt := 0.0
	frame_time_prev_t := t
	for isRunning = true; isRunning; {
		dt := t - prev_t
		i += 1
		if (i > 20) {
			max_ddt = max(max_ddt, abs(dt * 1000 - 16.6666666666666666666))
		}
		win.processMessages() // NOTE: this blocks while sizing
		frame_time_msg_t := init.time()
		updateAndRender()
		frame_time_t := init.time()
		if false {
			fmt.printf(
				"dt: %v ms, max_ddt: %v ms, frame_msg_time: %v ms, frame_render_time: %v ms\n",
				math.millis(dt),
				max_ddt,
				math.millis(frame_time_msg_t - frame_time_prev_t),
				math.millis(frame_time_t - frame_time_msg_t),
			)
		}

		prev_t = t
		t = win.doVsyncBadly()
		frame_time_prev_t = init.time()
		paint.copyFrameBufferToWindow(frame_buffer, window, window.dc)
		if foobar { 	// TODO: remove this
			windows.SetWindowPos(window.handle, win.HWND(nil), 0, 0, 600, 400, 0)
		} else {
			windows.SetWindowPos(window.handle, win.HWND(nil), 20, 20, 580, 380, 0)
		}
		foobar = !foobar
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
		paint.resizeFrameBuffer(&frame_buffer, i16(window.width), i16(window.height))
	case win.WM_PAINT:
		fmt.println("WM_PAINT")
		ps: paint.PAINTSTRUCT
		dc: win.HDC = paint.BeginPaint(windowHandle, &ps)
		paint.copyFrameBufferToWindow(frame_buffer, window, dc)
		paint.EndPaint(windowHandle, &ps)
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
	// NOTE: this takes 7 ms (.7 ms with -o:speed)
	for y in 0 ..< int(frame_buffer.height) {
		for x in 0 ..< int(frame_buffer.width) {
			rgba := math.v4{128, 128, 255, 0}
			paint.packRGBA(frame_buffer, x, y, rgba)
		}
	}
}

// NOTE: WS_EX_LAYERED -> alpha channel (but everything is slower, so destroy and recreate the window later)
// NOTE: casey says use D3D11/Metal: https://guide.handmadehero.org/code/day570/#7492
// NOTE: casey not using OpenGL: https://guide.handmadehero.org/code/day655/#10552
// TODO!: fonts (163/164): https://www.youtube.com/playlist?list=PLEMXAbCVnmY43tjaptnJW0rMP-DsXww1Y
// NOTE: does windows render in sRGB by default? - yes, SetICMMode() to use non sRGB
// https://learn.microsoft.com/en-us/windows/win32/wcs/srgb--a-standard-color-space
// https://learn.microsoft.com/en-us/windows/win32/wcs/basic-functions-for-use-within-a-device-context
