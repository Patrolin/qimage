// odin run demo/cpu/min_renderer -subsystem:windows
package main

import "../../../lib/alloc"
import "../../../lib/file"
import "../../../lib/paint"
import win "../../../lib/windows"
import "core:fmt"
import "core:runtime"

WINDOW_TITLE :: "cpu_min_renderer"
WINDOW_WIDTH :: 1366
WINDOW_HEIGHT :: 768

isRunning := false
imageBuffer := file.Image {
	channels = 4,
}
window: paint.Window

main :: proc() {
	context = alloc.defaultContext()
	windowClass := win.registerWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.stringToWstring(WINDOW_TITLE, allocator = context.allocator)
	win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)
	window.dc = paint.GetDC(window.handle)
	for isRunning = true; isRunning; {
		for msg: win.MSG; win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE); {
			if msg.message == win.WM_QUIT {
				isRunning = false
			}
			win.TranslateMessage(&msg)
			win.DispatchMessageW(&msg)
		}
		updateAndRender()
		paint.copyImageToWindow(imageBuffer, window, window.dc)
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
	context = alloc.defaultContext()
	result = 0
	switch message {
	case win.WM_SIZE:
		fmt.println("WM_SIZE")
		window.handle = windowHandle
		window.width = win.LOWORD(u32(lParam))
		window.height = win.HIWORD(u32(lParam))
		paint.resizeImage(&imageBuffer, i16(window.width), i16(window.height))
	case win.WM_PAINT:
		fmt.println("WM_PAINT")
		ps: paint.PAINTSTRUCT
		dc: win.HDC = paint.BeginPaint(windowHandle, &ps)
		paint.copyImageToWindow(imageBuffer, window, dc)
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
	stride := int(imageBuffer.width)
	pitch := 1
	for Y := 0; Y < int(imageBuffer.height); Y += 1 {
		for X := 0; X < int(imageBuffer.width); X += 1 {
			red: u32 = 128
			green: u32 = 128
			blue: u32 = 255
			// NOTE: register: xxRRGGBB, memory: BBGGRRxx
			BGRX := blue | (green << 8) | (red << 16)
			imageBuffer.data[Y * stride + X * pitch] = BGRX
		}
	}
}

// NOTE: WS_EX_LAYERED -> alpha channel (but everything is slower, so destroy and recreate the window later)
// NOTE: casey says use D3D11/Metal: https://guide.handmadehero.org/code/day570/#7492
// NOTE: casey not using OpenGL: https://guide.handmadehero.org/code/day655/#10552
// TODO!: fonts (163/164): https://www.youtube.com/playlist?list=PLEMXAbCVnmY43tjaptnJW0rMP-DsXww1Y
// TODO!: vsync counter demo
// NOTE: does windows render in sRGB by default? - yes, SetICMMode() to use non sRGB
// https://learn.microsoft.com/en-us/windows/win32/wcs/srgb--a-standard-color-space
// https://learn.microsoft.com/en-us/windows/win32/wcs/basic-functions-for-use-within-a-device-context
