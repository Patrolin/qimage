package lib_events
import "../math"
import "../os"
import "core:fmt"
import "core:intrinsics"
import win "core:sys/windows"

@(private)
_keyboard_state: [1]win.BYTE // NOTE: we tell windows not to write here

getAllEvents :: proc() {
	clear(&os_events)
	shrink(&os_events, 20)
	resetOsEventsInfo()
	msg: win.MSG
	for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
		win.DispatchMessageW(&msg)
	}
	updateOsEventsInfo() // NOTE: window may have resized/moved/moved to another monitor
}
@(private)
updateOsEventsInfo :: proc() {
	current_window := os_events_info.current_window
	current_window.monitor_rect = os.getMonitorRect(current_window.handle)
	current_window.window_rect = os.getWindowRect(current_window.handle)
	current_window.client_rect = os.getClientRect(
		current_window.handle,
		current_window.window_rect,
	)
	if os_events_info.resized_window {
		append(&os_events, WindowResizeEvent{})
	}
}

RIM_FOREGROUND :: 0
RIM_BACKGROUND :: 1
onPaint: proc(window: Window) = proc(window: Window) {assert(false)}

// NOTE: this steals the main thread (and blocks while sizing)
messageHandler :: proc "stdcall" (
	window_handle: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> (
	result: win.LRESULT,
) {
	context = os.defaultContext()
	result = 0
	switch message {
	// minimum needed messages
	case win.WM_SIZE:
		//fmt.printfln("WM_SIZE: %v", lParam)
		os_events_info.resized_window = true
	case win.WM_PAINT:
		//fmt.printfln("WM_PAINT")
		paintStruct: win.PAINTSTRUCT
		paintDc: win.HDC = win.BeginPaint(window_handle, &paintStruct)
		mock_window: Window = os_events_info.current_window^
		mock_window.dc = paintDc
		onPaint(mock_window)
		win.EndPaint(window_handle, &paintStruct)
	case win.WM_CLOSE:
		//fmt.printfln("WM_CLOSE")
		append(&os_events, WindowCloseEvent{})
	// inputs
	case win.WM_SIZING:
		fmt.printfln("WM_SIZING")
		rect: ^win.RECT = (^win.RECT)(rawptr(uintptr(lParam))) // TODO: WM_SIZNG: hold shift to resize at fixed ratio
		result = 1
	case win.WM_MOVE:
		os_events_info.moved_window = true
	case win.WM_MOUSEMOVE:
		append(
			&os_events,
			MouseMoveEvent{client_pos = {i32(os.LOIWORD(lParam)), i32(os.HIIWORD(lParam))}},
		)
	case win.WM_INPUT:
		//fmt.printfln("WM_INPUT")
		if os_events_info.moved_window || os_events_info.resized_window {return}
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
			event := RawMouseEvent{}
			switch (raw_input.data.mouse.usFlags) {
			case win.MOUSE_MOVE_RELATIVE:
				// TODO: https://stackoverflow.com/questions/36862013/raw-input-and-cursor-acceleration#43538322 + https://stackoverflow.com/questions/53020514/windows-mouse-speed-is-non-linear-how-do-i-convert-to-a-linear-scale?rq=1
				event.dpos = {raw_input.data.mouse.lLastX, raw_input.data.mouse.lLastY}
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
			if (usButtonFlags & win.RI_MOUSE_BUTTON_2_DOWN) != 0 {
				event.RMB = .Down
			}
			if (usButtonFlags & win.RI_MOUSE_BUTTON_2_UP) != 0 {
				event.RMB = .Up
			}
			append(&os_events, event)
		}
	// TODO: handle WM_POINTER events https://learn.microsoft.com/en-us/windows/win32/tablet/architecture-of-the-stylusinput-apis
	case win.WM_KEYDOWN, win.WM_SYSKEYDOWN, win.WM_KEYUP, win.WM_SYSKEYUP:
		fmt.printfln("WM_KEYxx")
		// NOTE: https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input
		key_code: u32 = u32(os.LOWORD(wParam))
		repeat_count: u32 = u32(os.LOWORD(lParam))
		flags := os.HIWORD(lParam)
		scan_code: u32 = u32(os.LOBYTE(flags))
		if (flags & win.KF_EXTENDED) == win.KF_EXTENDED {
			scan_code = os.MAKEWORD(scan_code, 0xE0) // e.g. Windows key
		}
		text_buffer: [10]win.WCHAR // NOTE: windows can theoretically return ligatures with up to 255 WCHARs
		text_len := win.ToUnicode(
			key_code,
			scan_code,
			&_keyboard_state[0],
			&text_buffer[0],
			len(text_buffer),
			0x4,
		)
		text := os.wstringToString(text_buffer[:max(text_len, 0)])
		append(
			&os_events,
			KeyboardEvent {
				key_code     = key_code,
				scan_code    = scan_code,
				text         = text,
				repeat_count = repeat_count,
				is_dead_char = text_len < 0, // TODO: store dead char here?
			},
		)
	case win.WM_SETCURSOR:
		//fmt.printfln("WM_SETCURSOR: %v", os.LOWORD(lParam))
		switch os.LOWORD(lParam) {
		case win.HTCLIENT:
			win.SetCursor(win.LoadCursorA(nil, win.IDC_ARROW))
			result = 1
		case:
			result = win.DefWindowProcW(window_handle, message, wParam, lParam)
		}
	case:
		result = win.DefWindowProcW(window_handle, message, wParam, lParam)
	}
	free_all(context.temp_allocator)
	return
}
