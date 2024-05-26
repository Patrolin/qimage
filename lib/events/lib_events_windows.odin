package lib_events
import "../init"
import "../os_utils"
import "core:fmt"
import "core:intrinsics"
import win "core:sys/windows"

getAllEvents :: proc() {
	clear(&os_events)
	reserve(&os_events, 20)
	os_events_info.got_resize_event = false
	msg: win.MSG
	for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
		win.DispatchMessageW(&msg)
	}
}

RIM_FOREGROUND :: 0
RIM_BACKGROUND :: 1

onPaint: proc(window: Window) = proc(window: Window) {assert(false)}
setOnPaint :: proc(callback: proc(window: Window)) {
	onPaint = callback
}

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
		fmt.printfln("WM_PAINT")
		paintStruct: win.PAINTSTRUCT
		paintDc: win.HDC = win.BeginPaint(windowHandle, &paintStruct)
		onPaint(
			{
				width = os_events_info.current_window.width,
				height = os_events_info.current_window.height,
				handle = windowHandle,
				dc = paintDc,
			},
		)
		win.EndPaint(windowHandle, &paintStruct)
	case win.WM_INPUT:
		fmt.printfln("WM_INPUT")
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
			event := MouseEvent{}
			switch (raw_input.data.mouse.usFlags) {
			case win.MOUSE_MOVE_RELATIVE:
				// TODO: https://stackoverflow.com/questions/36862013/raw-input-and-cursor-acceleration#43538322 + https://stackoverflow.com/questions/53020514/windows-mouse-speed-is-non-linear-how-do-i-convert-to-a-linear-scale?rq=1
				event.pos = os_utils.getCursorPos()
			case win.MOUSE_MOVE_ABSOLUTE:
				fmt.assertf(false, "win.MOUSE_MOVE_ABSOLUTE: %v", raw_input)
			}
			usButtonFlags := raw_input.data.mouse.DUMMYUNIONNAME.DUMMYSTRUCTNAME.usButtonFlags
			assert((usButtonFlags & 3) != 3)
			if (usButtonFlags & win.RI_MOUSE_BUTTON_1_DOWN) != 0 {
				event.LMB = .Down
			}
			if (usButtonFlags & win.RI_MOUSE_BUTTON_1_UP) != 0 {
				event.LMB = .Up
			}
			append(&os_events, event)
		}
	// TODO!: handle WM_POINTER events https://learn.microsoft.com/en-us/windows/win32/tablet/architecture-of-the-stylusinput-apis
	case win.WM_KEYDOWN, win.WM_SYSKEYDOWN, win.WM_KEYUP, win.WM_SYSKEYUP:
		fmt.printfln("WM_KEYxx")
		char_code := u32(wParam)
		scan_code := u32((lParam >> 16) & 0xff)
		char := rune('a') // TODO!: get char - call ToUnicode()
		repeat_count := lParam < 0x8000_0000 ? lParam & 0xffff : 0
		append(
			&os_events,
			KeyboardEvent {
				char_code = char_code,
				scan_code = scan_code,
				char = char,
				repeat_count = repeat_count,
			},
		)
	case win.WM_SIZE:
		fmt.printfln("WM_SIZE", lParam)
		os_events_info.current_window.width = i32(win.LOWORD(win.DWORD(lParam)))
		os_events_info.current_window.height = i32(win.HIWORD(win.DWORD(lParam)))
		if !os_events_info.got_resize_event {
			append(&os_events, WindowResizeEvent{})
			fmt.printfln("os_events: %v", os_events)
			os_events_info.got_resize_event = true
		}
	case win.WM_DESTROY:
		fmt.printfln("WM_DESTROY")
		append(&os_events, WindowCloseEvent{})
	case win.WM_SETCURSOR:
		fmt.printfln("WM_SETCURSOR")
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
