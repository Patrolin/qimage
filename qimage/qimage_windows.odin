// odin run qimage -subsystem:windows
package main
import "../common/assets"
import "../common/constants"
import "../common/input"
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
	fmt.printf("input: %v\n", uintptr(&input.g) & 63)
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
			win.TranslateMessage(&msg)
			win.DispatchMessageW(&msg)
		}
		updateAndRender()
		paint.copyImageBufferToWindow(&imageBuffer, window, window.dc)
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
	context = alloc.default_context()
	result = 0
	// TODO: handle keyboard/mouse events
	switch message {
	case win.WM_SIZE:
		fmt.println("WM_SIZE")
		window.handle = windowHandle
		window.width = win.LOWORD(u32(lParam))
		window.height = win.HIWORD(u32(lParam))
		paint.resizeImageBuffer(&imageBuffer, window.width, window.height)
		updateAndRender() // HACK: main loop is frozen while sizing
	case win.WM_PAINT:
		fmt.println("WM_PAINT")
		ps: paint.PAINTSTRUCT
		dc: win.HDC = paint.BeginPaint(windowHandle, &ps)
		paint.copyImageBufferToWindow(&imageBuffer, window, dc)
		paint.EndPaint(windowHandle, &ps)
	case win.WM_KEYDOWN, win.WM_SYSKEYDOWN:
		switch(wParam) {
		case win.VK_CONTROL:
			input.g.keyboard.Ctrl = true;
		case win.VK_MENU:
			input.g.keyboard.Alt = true;
		case win.VK_SHIFT:
			input.g.keyboard.Shift = true;
		case win.VK_KEYW:
			input.g.keyboard.W = true;
		case win.VK_KEYA:
			input.g.keyboard.A = true;
		case win.VK_KEYS:
			input.g.keyboard.S = true;
		case win.VK_KEYD:
			input.g.keyboard.D = true;
		}
		fmt.println(input.g)
	case win.WM_KEYUP, win.WM_SYSKEYUP:
		switch(wParam) {
		case win.VK_CONTROL:
			input.g.keyboard.Ctrl = false;
		case win.VK_MENU:
			input.g.keyboard.Alt = false;
		case win.VK_SHIFT:
			input.g.keyboard.Shift = false;
		case win.VK_KEYW:
			input.g.keyboard.W = false;
		case win.VK_KEYA:
			input.g.keyboard.A = false;
		case win.VK_KEYS:
			input.g.keyboard.S = false;
		case win.VK_KEYD:
			input.g.keyboard.D = false;
		}
		fmt.println(input.g)
	case win.WM_DESTROY:
		fmt.println("WM_DESTROY")
		isRunning = false
	case:
		result = win.DefWindowProcW(windowHandle, message, wParam, lParam)
	}
	free_all(context.temp_allocator)
	return
}

// NOTE: WS_EX_LAYERED -> alpha channel?
// TODO: allow cropping svgs
// TODO: 1D LUTs + 16x16x16 3D LUTs?
// TODO: how do IMGUI? - functional + ?
// TODO: load windows screenshots
// NOTE: perfmon = systrace for windows
// TODO: wtf is going on with cursor sprite?
// TODO: LoC counter
