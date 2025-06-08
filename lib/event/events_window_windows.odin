package event_lib
import "../../utils/math"
import "../../utils/os"
import "../../utils/time"
import "core:fmt"
import win "core:sys/windows"

// init window
@(private)
default_window_class_name: win.wstring
@(private)
initWindow :: proc() {
	default_window_class_name = os.win_string_to_wstring("lib_window_default", allocator = context.allocator)
	registerWindowClass(
		{style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC, lpfnWndProc = messageHandler, lpszClassName = default_window_class_name},
	)
}
@(private)
registerWindowClass :: proc(class: win.WNDCLASSEXW) {
	class := class
	if class.cbSize == 0 {
		class.cbSize = size_of(win.WNDCLASSEXW)
	}
	assert(class.lpszClassName != nil && class.lpszClassName[0] != 0, "lpszClassName cannot be empty")
	if class.hCursor == nil {
		class.hCursor = win.LoadCursorA(nil, win.IDC_ARROW)
	}
	if (win.RegisterClassExW(&class) == 0) {
		lastError := win.GetLastError()
		fmt.assertf(false, "class: %v, error: %v\n", class, lastError)
	}
}

// open window
Window :: struct {
	monitor_rect:         math.RelativeRect,
	client_rect:          math.RelativeRect,
	window_rect:          math.RelativeRect,
	initial_client_ratio: math.i32x2,
	handle:               win.HWND,
	dc:                   win.HDC,
}
openWindow :: proc(title: string, client_size: math.i32x2, window_pos: math.i32x2 = {-1, -1}) -> ^Window {
	assert(os_events_info.current_window == nil, "We don't support multiple windows")
	window := new(Window)
	window.initial_client_ratio = {client_size.x, client_size.y}
	os_events_info.current_window = window
	title: win.wstring = len(title) > 0 ? os.win_string_to_wstring(title) : nil
	window_border := os.info.window_border
	window_size := math.i32x2 {
		client_size.x + window_border.left + window_border.right,
		client_size.y + window_border.top + window_border.bottom,
	}
	window.handle = win.CreateWindowExW(
		0,
		default_window_class_name,
		title,
		win.WS_OVERLAPPEDWINDOW,
		window_pos.x != -1 ? window_pos.x : win.CW_USEDEFAULT,
		window_pos.y != -1 ? window_pos.y : win.CW_USEDEFAULT,
		window_size.x,
		window_size.y,
		nil,
		nil,
		nil,
		nil,
	)
	if window.handle == nil {
		lastError := win.GetLastError()
		fmt.assertf(false, "error: %v\n", lastError)
	}
	// NOTE: windows animations are bad and may cause flicker, so we hide them behind unminimize animation
	win.ShowWindow(window.handle, win.SW_MINIMIZE)
	win.ShowWindow(window.handle, win.SW_RESTORE)
	win.ShowWindow(window.handle, win.SW_SHOWNORMAL)
	window.dc = win.GetDC(window.handle)
	updateOsEventsInfo() // NOTE: get window_rect, client_rect
	fmt.printfln("window: %v", window)
	// mouse input // https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/hid-architecture#hid-clients-supported-in-windows
	RIUP_MOUSE_CONTROLLER_KEYBOARD :: 0x1
	RIU_MOUSE :: 0x2
	raw_devices: []win.RAWINPUTDEVICE = {
		win.RAWINPUTDEVICE {
			usUsagePage = RIUP_MOUSE_CONTROLLER_KEYBOARD,
			usUsage     = RIU_MOUSE,
			dwFlags     = 0, // NOTE: RIDEV_NOLEGACY disables WM_MOUSEMOVE, WM_SIZE and WM_SETCURSOR, making it useless outside fullscreen
			hwndTarget  = window.handle,
		},
	}
	assert(bool(win.RegisterRawInputDevices(&raw_devices[0], u32(len(raw_devices)), size_of(win.RAWINPUTDEVICE))))
	return window
}

// utils
// TODO: setCursor(...)
// NOTE: toggleFullscreen() from Raymond Chen
getWindowAndMonitorInfo :: proc(window: win.HWND) -> (monitorInfo: win.MONITORINFO, windowPlacement: win.WINDOWPLACEMENT) {
	monitor := win.MonitorFromWindow(window, win.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST)
	monitorInfo.cbSize = size_of(win.MONITORINFO)
	assert(bool(win.GetWindowPlacement(window, &windowPlacement)))
	assert(bool(win.GetMonitorInfoW(monitor, &monitorInfo)))
	return
}
toggleFullscreen :: proc(window: win.HWND) {
	@(static) prevWindowPlacement: win.WINDOWPLACEMENT
	windowStyle := u32(win.GetWindowLongW(window, win.GWL_STYLE))
	if (windowStyle & win.WS_OVERLAPPEDWINDOW) > 0 {
		monitorInfo, windowPlacement := getWindowAndMonitorInfo(window)
		win.SetWindowLongW(window, win.GWL_STYLE, i32(windowStyle & ~win.WS_OVERLAPPEDWINDOW))
		using monitorInfo.rcMonitor
		win.SetWindowPos(window, nil, left, top, right - left, bottom - top, win.SWP_NOOWNERZORDER | win.SWP_FRAMECHANGED)
		prevWindowPlacement = windowPlacement
	} else {
		win.SetWindowLongW(window, win.GWL_STYLE, i32(windowStyle | win.WS_OVERLAPPEDWINDOW))
		win.SetWindowPlacement(window, &prevWindowPlacement)
		win.SetWindowPos(window, nil, 0, 0, 0, 0, win.SWP_NOOWNERZORDER | win.SWP_FRAMECHANGED)
	}
}
/*
	vsync us to the monitor refresh rate
	NOTE: this only works when using OpenGL, otherwise we get only get 60Hz and sometimes it returns 0-125 ms later than it should..
*/
doVsyncBadly :: proc() -> time.Duration {
	win.DwmFlush()
	return time.time()
}
/* NOTE: doVsyncWell():
	thread0:
		disableVsync()
		for {
			flushPreviousFrame()
			processInputs()
			wakeRenderThread()
			sleep(time_until_next_frame) // can we get the monitor refresh rate somehow?
		}
	thread1:
		updateGameState()
		renderToOffscreenRenderTarget()
*/
