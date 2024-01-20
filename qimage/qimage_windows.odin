// odin run qimage -subsystem:windows
package main
import "../common/assets"
import "../common/constants"
import commonInput "../common/input"
import "../lib/alloc"
import "../lib/file"
import "../lib/gl"
import "../lib/math"
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
input := commonInput.Input{} // NOTE: are global variables always cache aligned?

main :: proc() {
	context = alloc.default_context()
	input.mouse.path = input.mouse.path_buffer[:1]
	fmt.printf("hello world\n")
	a := make([]u8, 4, allocator = context.temp_allocator)
	fmt.println(a)
	fmt.printf("input: %v\n", uintptr(&input) & 63)
	windowClass := win.registerWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.string_to_wstring(WINDOW_TITLE, allocator = context.allocator)
	win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)

	raw_devices := win.RAWINPUTDEVICE {
		usUsagePage = win.RIUP_MOUSE_CONTROLLER_KEYBOARD,
		usUsage     = win.RIU_MOUSE,
		dwFlags     = 0,
		hwndTarget  = window.handle,
	}
	assert(bool(win.RegisterRawInputDevices(&raw_devices, 1, size_of(win.RAWINPUTDEVICE))))

	window.dc = paint.GetDC(window.handle)
	image = assets.loadImage("test_image.bmp")
	fmt.println(image)
	fmt.print(file.tprintImage(image, 0, 0, 3, 3))
	t := math.time()
	prev_t := t
	i := 0
	max_dt := 0.0
	for isRunning = true; isRunning; {
		dt := t - prev_t
		i += 1
		if (i > 20) {
			max_dt = math.max(max_dt, math.abs(dt * 1000 - 16.6666666666666666666))
		}
		fmt.printf("max_dt: %v ms, dt_diff: %v ms\n", max_dt, dt * 1000 - 16.6666666666666666666)
		win.processMessages()
		updateAndRender()

		prev_t = t
		t = win.doVsyncBadly() // NOTE: sync with DWM, so we don't mistime a frame
		paint.copyImageBufferToWindow(&imageBuffer, window, window.dc)
		free_all(context.temp_allocator)
		input.mouse.path_buffer = input.mouse.path[len(input.mouse.path) - 1]
		input.mouse.path = input.mouse.path_buffer[:1]
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
	case win.WM_DESTROY:
		fmt.println("WM_DESTROY")
		isRunning = false
	case win.WM_MOUSEMOVE:
		x := u16(win.LOWORD(u32(lParam)))
		y := u16(win.HIWORD(u32(lParam)))
		i := len(input.mouse.path)
		input.mouse.path_buffer[i] = math.v2i {
			E = {x, y},
		}
		input.mouse.path = input.mouse.path_buffer[:i + 1]
	//fmt.println("input.mouse.path", input.mouse.path)
	case win.WM_LBUTTONDOWN:
		input.mouse.clickPos.x = u16(win.LOWORD(u32(lParam)))
		input.mouse.clickPos.y = u16(win.HIWORD(u32(lParam)))
		input.mouse.LMB = true
		fmt.println(input)
	case win.WM_INPUT:
		// NOTE: win.WM_LBUTTONUP does not trigger if you move the mouse outside the window
		raw_input: win.RAWINPUT
		raw_input_size := u32(size_of(raw_input))
		win.GetRawInputData(
			win.HRAWINPUT(lParam),
			win.RID_INPUT,
			&raw_input,
			&raw_input_size,
			size_of(win.RAWINPUTHEADER),
		)
		if (raw_input.header.dwType == win.RIM_TYPEMOUSE) {
			if bool(
				   raw_input.data.mouse.DUMMYUNIONNAME.DUMMYSTRUCTNAME.usButtonFlags &
				   win.RI_MOUSE_LEFT_BUTTON_UP,
			   ) {
				input.mouse.LMB = false
				fmt.println(input)
			}
		}
	case win.WM_KEYDOWN, win.WM_SYSKEYDOWN, win.WM_KEYUP, win.WM_SYSKEYUP:
		wasDown := b8(math.get_bit(u32(lParam), 30))
		isDown := b8(math.get_bit(u32(lParam), 31) ~ 1)
		count := u8(isDown && !wasDown)
		switch (wParam) {
		case win.VK_CONTROL:
			input.keyboard.Ctrl = isDown
		case win.VK_MENU:
			input.keyboard.Alt = isDown
		case win.VK_SHIFT:
			input.keyboard.Shift = isDown
		case win.VK_KEYW:
			input.keyboard.W = isDown
			input.keyboard.W_count = count
		case win.VK_KEYA:
			input.keyboard.A = isDown
			input.keyboard.A_count = count
		case win.VK_KEYS:
			input.keyboard.S = isDown
			input.keyboard.S_count = count
		case win.VK_KEYD:
			input.keyboard.D = isDown
			input.keyboard.D_count = count
		}
		fmt.println(input)
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
