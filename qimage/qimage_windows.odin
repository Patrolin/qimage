// odin run qimage -subsystem:windows
package main
import "../common/assets"
import "../common/constants"
import "../lib/alloc"
import "../lib/file"
import "../lib/gl"
import "../lib/input"
import "../lib/math"
import "../lib/paint"
import win "../lib/windows"
import "core:fmt"
import "core:runtime"

WINDOW_TITLE :: constants.WINDOW_TITLE
WINDOW_WIDTH :: constants.WINDOW_WIDTH
WINDOW_HEIGHT :: constants.WINDOW_HEIGHT

isRunning := false
imageBuffer := file.Image {
	channels = 4, // TODO!: make this be 3?
}
window: paint.Window
image: file.Image
inputs := input.Inputs{} // NOTE: are global variables always cache aligned?

main :: proc() {
	context = alloc.default_context()
	input.reset_inputs(&inputs)
	inputs.mouse.pos = {min(i16), min(i16)}
	fmt.printf("hello world\n")
	a := make([]u8, 4, allocator = context.temp_allocator)
	fmt.println(a)
	fmt.printf("inputs: %v\n", uintptr(&inputs) & 63)
	windowClass := win.registerWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler},
	)
	title_w := win.string_to_wstring(WINDOW_TITLE, allocator = context.allocator)
	win.createWindow(windowClass, title_w, WINDOW_WIDTH, WINDOW_HEIGHT)

	raw_devices: []win.RAWINPUTDEVICE =  {
		win.RAWINPUTDEVICE {
			usUsagePage = win.RIUP_MOUSE_CONTROLLER_KEYBOARD,
			usUsage = win.RIU_MOUSE,
			dwFlags = 0,
			hwndTarget = window.handle,
		},
	}
	assert(
		bool(
			win.RegisterRawInputDevices(
				&raw_devices[0],
				u32(len(raw_devices)),
				size_of(win.RAWINPUTDEVICE),
			),
		),
	)

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
		//fmt.printf("max_dt: %v ms, dt_diff: %v ms\n", max_dt, dt * 1000 - 16.6666666666666666666)
		win.processMessages()
		updateAndRender()
		input.reset_inputs(&inputs)

		prev_t = t
		t = win.doVsyncBadly() // NOTE: we don't care about dropped frames
		paint.copyImageToWindow(imageBuffer, window, window.dc) // NOTE: draw previous frame
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
	switch message {
	case win.WM_SIZE:
		fmt.println("WM_SIZE")
		window.handle = windowHandle
		window.width = win.LOWORD(u32(lParam))
		window.height = win.HIWORD(u32(lParam))
		paint.resizeImage(&imageBuffer, window.width, window.height)
		updateAndRender() // HACK: main loop is frozen while sizing
	case win.WM_PAINT:
		fmt.println("WM_PAINT")
		ps: paint.PAINTSTRUCT
		dc: win.HDC = paint.BeginPaint(windowHandle, &ps)
		paint.copyImageToWindow(imageBuffer, window, dc)
		paint.EndPaint(windowHandle, &ps)
	case win.WM_DESTROY:
		fmt.println("WM_DESTROY")
		isRunning = false
	case win.WM_LBUTTONDOWN:
		inputs.mouse.clickPos.x = i16(win.LOWORD(u32(lParam)))
		inputs.mouse.clickPos.y = i16(win.HIWORD(u32(lParam)))
		input.add_transitions(&inputs.mouse.LMB, 1)
		fmt.println(inputs)
	case win.WM_INPUT:
		// NOTE: WM_LBUTTONUP/WM_MOUSEMOVE does not trigger if you move the mouse outside the window, so we use rawinput
		if wParam == win.RIM_INPUTSINK {
			return
		}
		raw_input: win.RAWINPUT
		raw_input_size := u32(size_of(raw_input))
		win.GetRawInputData(
			win.HRAWINPUT(lParam),
			win.RID_INPUT,
			&raw_input,
			&raw_input_size,
			size_of(win.RAWINPUTHEADER),
		)
		monitorInfo, windowPlacement := win.getWindowAndMonitorInfo(window.handle)
		monitorRect := monitorInfo.rcMonitor
		windowRect := windowPlacement.rcNormalPosition
		if (raw_input.header.dwType == win.RIM_TYPEMOUSE) {
			switch (raw_input.data.mouse.usFlags) {
			case win.MOUSE_MOVE_RELATIVE:
				if inputs.mouse.pos == {min(i16), min(i16)} {
					pos: win.POINT
					win.GetCursorPos(&pos)
					inputs.mouse.pos = {i16(pos.x), i16(pos.y)}
				}
				dpos := math.v2i {
					i16(raw_input.data.mouse.lLastX),
					i16(raw_input.data.mouse.lLastY),
				}
				if dpos == {0, 0} {
					return
				}
				pos := math.clamp(
					inputs.mouse.pos + dpos,
					math.Rect {
						i16(monitorRect.left),
						i16(monitorRect.top),
						i16(monitorRect.right),
						i16(monitorRect.bottom),
					},
				)
				input.add_mouse_path(&inputs, pos)
			//fmt.println("REL dpos:", dpos, "path:", inputs.mouse.path)
			case win.MOUSE_MOVE_ABSOLUTE:
				assert(false) // NOTE: does this ever trigger?
			}
			switch raw_input.data.mouse.DUMMYUNIONNAME.DUMMYSTRUCTNAME.usButtonFlags {
			case win.RI_MOUSE_LEFT_BUTTON_UP:
				input.add_transitions(&inputs.mouse.LMB, 1)
				fmt.println(inputs)
			}
		}
	// TODO!: handle WM_POINTER events
	case win.WM_KEYDOWN, win.WM_SYSKEYDOWN, win.WM_KEYUP, win.WM_SYSKEYUP:
		wasDown := u8(math.get_bit(u32(lParam), 30))
		isDown := u8(math.get_bit(u32(lParam), 31) ~ 1)
		transitions := isDown ~ wasDown
		switch (wParam) {
		case win.VK_CONTROL:
			input.add_transitions(&inputs.keyboard.Ctrl, transitions)
		case win.VK_MENU:
			input.add_transitions(&inputs.keyboard.Alt, transitions)
		case win.VK_SHIFT:
			input.add_transitions(&inputs.keyboard.Shift, transitions)
		case win.VK_KEYW:
			input.add_transitions(&inputs.keyboard.W, transitions)
		case win.VK_KEYA:
			input.add_transitions(&inputs.keyboard.A, transitions)
		case win.VK_KEYS:
			input.add_transitions(&inputs.keyboard.S, transitions)
		case win.VK_KEYD:
			input.add_transitions(&inputs.keyboard.D, transitions)
		}
		fmt.println(inputs)
	case:
		result = win.DefWindowProcW(windowHandle, message, wParam, lParam)
	}
	free_all(context.temp_allocator)
	return
}

// NOTE: WS_EX_LAYERED -> alpha channel
// NOTE: perfmon = systrace for windows
// TODO!: load windows screenshots
// TODO!: allow cropping svgs
// TODO!: wtf is going on with cursor sprite?
// TODO?: 1D LUTs + 16x16x16 3D LUTs
// TODO?: multithreading around windows events to get above 10000fps
