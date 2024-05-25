package lib_events
import "../init"
import "core:fmt"
import win "core:sys/windows"

getCursorPos :: proc() -> [2]int {
	pos: win.POINT
	win.GetCursorPos(&pos)
	return {int(pos.x), int(pos.y)}
}

RIM_FOREGROUND :: 0
RIM_BACKGROUND :: 1

// TODO: how to specify this?
onPaint :: proc(dc: win.HDC) {}

// NOTE: this steals the main thread (and blocks while sizing)
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
	case win.WM_PAINT:
		ps: win.PAINTSTRUCT
		dc: win.HDC = win.BeginPaint(windowHandle, &ps)
		onPaint(dc)
		win.EndPaint(windowHandle, &ps)
	case win.WM_INPUT:
		// NOTE: WM_LBUTTONUP/WM_MOUSEMOVE does not trigger if you move the mouse outside the window, so we use rawinput
		if wParam == RIM_BACKGROUND {
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
		// TODO: send mouse pos relative to window, or send window rect?
		//monitorInfo, windowPlacement := win.getWindowAndMonitorInfo(window.handle)
		//monitorRect := monitorInfo.rcMonitor
		//windowRect := windowPlacement.rcNormalPosition
		if (raw_input.header.dwType == win.RIM_TYPEMOUSE) {
			switch (raw_input.data.mouse.usFlags) {
			case win.MOUSE_MOVE_RELATIVE:
				// TODO: https://stackoverflow.com/questions/36862013/raw-input-and-cursor-acceleration#43538322 + https://stackoverflow.com/questions/53020514/windows-mouse-speed-is-non-linear-how-do-i-convert-to-a-linear-scale?rq=1
				append(&os_events, MouseMoveEvent{pos = getCursorPos()})
			case win.MOUSE_MOVE_ABSOLUTE:
				fmt.assertf(false, "win.MOUSE_MOVE_ABSOLUTE: %v", raw_input)
			}
			switch raw_input.data.mouse.DUMMYUNIONNAME.DUMMYSTRUCTNAME.usButtonFlags {
			case win.RI_MOUSE_LEFT_BUTTON_DOWNS:
				append(&os_events, MouseDownEvent{})
			case win.RI_MOUSE_LEFT_BUTTON_UP:
				append(&os_events, MouseUpEvent{})
			}
		}
	// TODO!: handle WM_POINTER events https://learn.microsoft.com/en-us/windows/win32/tablet/architecture-of-the-stylusinput-apis
	case win.WM_KEYDOWN, win.WM_SYSKEYDOWN:
		char_code := u32(wParam)
		scan_code := u32((lParam >> 16) & 0xff)
		char := rune('a') // TODO!: get char - call ToUnicode()
		repeat_count := lParam & 0xffff
		append(
			&os_events,
			KeyboardDownEvent {
				char_code = char_code,
				scan_code = scan_code,
				char = char,
				repeat_count = repeat_count,
			},
		)
	case win.WM_KEYUP, win.WM_SYSKEYUP:
		char_code := u32(wParam)
		scan_code := u32((lParam >> 16) & 0xff)
		char := rune('a') // TODO!: get char - call ToUnicode()
		append(
			&os_events,
			KeyboardUpEvent{char_code = char_code, scan_code = scan_code, char = char},
		)
	case win.WM_SIZE:
		width := int(win.LOWORD(win.DWORD(lParam)))
		height := int(win.HIWORD(win.DWORD(lParam)))
		append(&os_events, WindowResizeEvent{rect = {0, 0, width, height}})
	case win.WM_DESTROY:
		append(&os_events, WindowCloseEvent{})
	case win.WM_SETCURSOR:
		// NOTE: on move inside window
		// TODO!: how do set cursor?
		win.SetCursor(win.LoadCursorA(nil, win.IDC_ARROW))
		result = 1
	case:
		result = win.DefWindowProcW(windowHandle, message, wParam, lParam)
	}
	free_all(context.temp_allocator)
	return
}
