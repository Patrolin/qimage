// odin run qimage_win -subsystem:windows
package main
import "../common/assets"
import "../common/constants"
import "../lib/alloc"
import "../lib/file"
import "../lib/gl"
import "../lib/paint"
import win "../lib/windows"
import "core:fmt"
import "core:runtime"

WINDOW_TITLE :: constants.WINDOW_TITLE
WINDOW_WIDTH :: constants.WINDOW_WIDTH
WINDOW_HEIGHT :: constants.WINDOW_HEIGHT

isRunning := false
imageBuffer: paint.ImageBuffer
window: paint.Window
image: file.Image

main :: proc() {
	context = alloc.default_context()
	fmt.printf("hello world\n")
	a := make([]u8, 4, allocator = context.temp_allocator)
	fmt.println(a)
	windowClass := win.registerWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.string_to_wstring(WINDOW_TITLE, allocator = context.allocator)
	win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)
	window.dc = paint.GetDC(window.handle)
	image = assets.loadImage("test_image.bmp")
	fmt.println(image)
	fmt.print(file.tprintImage(image, 0, 0, 3, 3))
	for isRunning = true; isRunning; {
		for msg: win.MSG; win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE); {
			if msg.message == win.WM_QUIT {
				isRunning = false
			}
			win.TranslateMessage(&msg)
			win.DispatchMessageW(&msg)
		}
		updateAndRender()
		paint.copyImageBufferToWindow(&imageBuffer, window, window.dc)
		free_all(context.temp_allocator)
	}
}

// NOTE: this blocks main thread
messageHandler :: proc "stdcall" (
	windowHandle: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> (
	result: win.LRESULT,
) {
	context = alloc.default_context()
	result = 0
	switch message {
	case win.WM_SIZE:
		fmt.println("WM_SIZE")
		window.handle = windowHandle
		window.width = win.LOWORD(u32(lParam))
		window.height = win.HIWORD(u32(lParam))
		paint.resizeImageBuffer(&imageBuffer, window.width, window.height)
	case win.WM_PAINT:
		fmt.println("WM_PAINT")
		ps: paint.PAINTSTRUCT
		dc: win.HDC = paint.BeginPaint(windowHandle, &ps)
		paint.copyImageBufferToWindow(&imageBuffer, window, dc)
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

// NOTE: WS_EX_LAYERED -> alpha channel?
// TODO: tell OpenGL we want sRGB - handmade hero 236-241
// TODO: allow cropping svgs
// TODO: 1D LUTs + 16x16x16 3D LUTs?
// TODO: handle WM_SYSKEYUP/DOWN, WM_KEYUP/DOWN
// TODO: how do IMGUI?
// TODO: load windows screenshots
// NOTE: windows systrace = perfmon
// TODO: wtf is going on with cursor sprite?
// TODO: LoC counter
