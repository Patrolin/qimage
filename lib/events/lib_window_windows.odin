package lib_events
import "../math"
import "../os"
import "core:fmt"
import win "core:sys/windows"

// init window
@(private)
default_window_class_name: win.wstring
@(private)
initWindow :: proc() {
	default_window_class_name = os.stringToWstring(
		"lib_window_default",
		allocator = context.allocator,
	)
	registerWindowClass(
		{
			style = win.CS_HREDRAW | win.CS_VREDRAW | win.CS_OWNDC,
			lpfnWndProc = messageHandler,
			lpszClassName = default_window_class_name,
		},
	)
}
@(private)
registerWindowClass :: proc(class: win.WNDCLASSEXW) {
	class := class
	if class.cbSize == 0 {
		class.cbSize = size_of(win.WNDCLASSEXW)
	}
	assert(
		class.lpszClassName != nil && class.lpszClassName[0] != 0,
		"lpszClassName cannot be empty",
	)
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
	rect:   math.RelativeRect,
	handle: win.HWND,
	dc:     win.HDC,
}
openWindow :: proc(title: string, rect: math.RelativeRect) -> ^Window {
	assert(os_events_info.current_window == nil, "We don't support multiple windows")
	title: win.wstring = len(title) > 0 ? os.stringToWstring(title) : nil
	windowStyle := win.WS_OVERLAPPEDWINDOW
	adjustRect := win.RECT{0, 0, rect.width, rect.height}
	win.AdjustWindowRectEx(&adjustRect, windowStyle, win.FALSE, 0)
	rect := rect
	rect.width = adjustRect.right - adjustRect.left
	rect.height = adjustRect.bottom - adjustRect.top
	window := new(Window)
	window.rect = {rect.left, rect.top, rect.width, rect.height}
	os_events_info.current_window = window
	window.handle = win.CreateWindowExW(
		0,
		default_window_class_name,
		title,
		windowStyle,
		rect.left != -1 ? rect.left : win.CW_USEDEFAULT,
		rect.top != -1 ? rect.top : win.CW_USEDEFAULT,
		rect.width,
		rect.height,
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
	// mouse input
	raw_devices: []win.RAWINPUTDEVICE = {
		win.RAWINPUTDEVICE {
			usUsagePage = RIUP_MOUSE_CONTROLLER_KEYBOARD,
			usUsage     = RIU_MOUSE,
			dwFlags     = 0, // NOTE: RIDEV_NOLEGACY disables WM_MOUSEMOVE, WM_SIZE and WM_SETCURSOR, making it useless outside fullscreen
			hwndTarget  = window.handle,
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
	return window
}

// utils
// TODO: setCursor(...)
// NOTE: toggleFullscreen() from Raymond Chen
getWindowAndMonitorInfo :: proc(
	window: win.HWND,
) -> (
	monitorInfo: win.MONITORINFO,
	windowPlacement: win.WINDOWPLACEMENT,
) {
	monitor := win.MonitorFromWindow(window, win.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST)
	monitorInfo.cbSize = size_of(win.MONITORINFO)
	assert(bool(win.GetWindowPlacement(window, &windowPlacement)))
	assert(bool(win.GetMonitorInfoW(monitor, &monitorInfo)))
	return
}
toggleFullscreen :: proc(window: win.HWND) {
	@(static)
	prevWindowPlacement: win.WINDOWPLACEMENT
	windowStyle := u32(win.GetWindowLongW(window, win.GWL_STYLE))
	if (windowStyle & win.WS_OVERLAPPEDWINDOW) > 0 {
		monitorInfo, windowPlacement := getWindowAndMonitorInfo(window)
		win.SetWindowLongW(window, win.GWL_STYLE, i32(windowStyle & ~win.WS_OVERLAPPEDWINDOW))
		using monitorInfo.rcMonitor
		win.SetWindowPos(
			window,
			nil,
			left,
			top,
			right - left,
			bottom - top,
			win.SWP_NOOWNERZORDER | win.SWP_FRAMECHANGED,
		)
		prevWindowPlacement = windowPlacement
	} else {
		win.SetWindowLongW(window, win.GWL_STYLE, i32(windowStyle | win.WS_OVERLAPPEDWINDOW))
		win.SetWindowPlacement(window, &prevWindowPlacement)
		win.SetWindowPos(window, nil, 0, 0, 0, 0, win.SWP_NOOWNERZORDER | win.SWP_FRAMECHANGED)
	}
}
// vsync us to 60fps (or whatever the monitor refresh rate is?)
// NOTE: sometimes this returns up to 5.832 ms later than it should
doVsyncBadly :: proc() -> f64 {
	win.DwmFlush()
	return os.time()
}
/* NOTE: doVsyncWell():
	for isRunning {
		processInputs() // NOTE: this blocks while sizing
		updateAndRender()
		doVsyncBadly() // NOTE: we don't care about dropped frames
		flipLastFrame()
	}
*/
/* NOTE: doVsyncWell2():
	thread0:
		for isRunning {
			wakeRenderThread()
			doVsyncBadly() // NOTE: sync with DWM, so we don't mistime a frame
			flipLastFrame()
		}
	thread1
		while hasWork {
			processInputs() // NOTE: this blocks while sizing, but eh
			updateAndRender()
		}
*/
