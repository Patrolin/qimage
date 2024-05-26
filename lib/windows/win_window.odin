package lib_windows
import "../init"
import "../math"
import "core:fmt"
import win "core:sys/windows"

WNDCLASSEXW :: win.WNDCLASSEXW
RECT :: win.RECT

WS_OVERLAPPEDWINDOW :: win.WS_OVERLAPPEDWINDOW
WS_VISIBLE :: win.WS_VISIBLE
CW_USEDEFAULT :: win.CW_USEDEFAULT
GWL_STYLE :: -16
MONITOR_DEFAULTTONEAREST :: win.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST
SWP_FRAMECHANGED :: 0x0020
SWP_NOOWNERZORDER :: 0x0200
IDC_APPSTARTING := cstring(win._IDC_APPSTARTING)
IDC_ARROW := cstring(win._IDC_ARROW)
IDC_CROSS := cstring(win._IDC_CROSS)
IDC_HAND := cstring(win._IDC_HAND)
IDC_HELP := cstring(win._IDC_HELP)
IDC_IBEAM := cstring(win._IDC_IBEAM)
IDC_ICON := cstring(win._IDC_ICON)
IDC_NO := cstring(win._IDC_NO)
IDC_SIZE := cstring(win._IDC_SIZE)
IDC_SIZEALL := cstring(win._IDC_SIZEALL)
IDC_SIZENESW := cstring(win._IDC_SIZENESW)
IDC_SIZENS := cstring(win._IDC_SIZENS)
IDC_SIZENWSE := cstring(win._IDC_SIZENWSE)
IDC_SIZEWE := cstring(win._IDC_SIZEWE)
IDC_UPARROW := cstring(win._IDC_UPARROW)
IDC_WAIT := cstring(win._IDC_WAIT)

//GetModuleHandleW :: win.GetModuleHandleW
RegisterClassExW :: win.RegisterClassExW
AdjustWindowRectEx :: win.AdjustWindowRectEx
CreateWindowExW :: win.CreateWindowExW
// messages
GetMessageW :: win.GetMessageW
PeekMessageW :: win.PeekMessageW
TranslateMessage :: win.TranslateMessage
DispatchMessageW :: win.DispatchMessageW
DefWindowProcW :: win.DefWindowProcW
PostQuitMessage :: win.PostQuitMessage
LoadCursorA :: win.LoadCursorA
SetCursor :: win.SetCursor
// rawinput
RegisterRawInputDevices :: win.RegisterRawInputDevices
GetRawInputData :: win.GetRawInputData

registerWindowClass :: proc(class: WNDCLASSEXW) -> wstring {
	@(static)
	registerWindowClassCounter := 0
	class := class
	if class.cbSize == 0 {
		class.cbSize = size_of(WNDCLASSEXW)
	}
	if class.lpszClassName == nil {
		className := fmt.aprintf("libWin_%v", registerWindowClassCounter)
		class.lpszClassName = stringToWstring(className, context.allocator)
		registerWindowClassCounter += 1
	}
	if class.hCursor == nil {
		class.hCursor = LoadCursorA(nil, IDC_ARROW)
	}
	if (RegisterClassExW(&class) == 0) {
		lastError := GetLastError()
		assert(false, fmt.tprintf("error: %v\n", lastError))
	}
	return class.lpszClassName
}

createWindow :: proc(
	windowClass: wstring,
	title: wstring,
	width, height: LONG,
	startMaximized := false,
) -> HWND {
	width, height := width, height
	adjustRect := RECT{0, 0, width, height}
	windowStyle := WS_OVERLAPPEDWINDOW
	AdjustWindowRectEx(&adjustRect, windowStyle, FALSE, 0)
	width = adjustRect.right - adjustRect.left
	height = adjustRect.bottom - adjustRect.top

	// NOTE: this blocks until events are handled
	window := CreateWindowExW(
		0,
		windowClass,
		title,
		windowStyle,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		width,
		height,
		nil,
		nil,
		nil,
		nil,
	)
	// NOTE: windows animations are bad and may cause flicker, so we hide them behind unminimize animation
	win.ShowWindow(window, win.SW_MINIMIZE)
	win.ShowWindow(window, win.SW_RESTORE)
	win.ShowWindow(window, win.SW_SHOWNORMAL)
	if window == nil {
		lastError := GetLastError()
		assert(false, fmt.tprintf("error: %v\n", lastError))
	}
	return window
}

getWindowAndMonitorInfo :: proc(
	window: HWND,
) -> (
	monitorInfo: win.MONITORINFO,
	windowPlacement: win.WINDOWPLACEMENT,
) {
	monitor := win.MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST)
	monitorInfo.cbSize = size_of(win.MONITORINFO)
	assert(bool(win.GetWindowPlacement(window, &windowPlacement)))
	assert(bool(win.GetMonitorInfoW(monitor, &monitorInfo)))
	return
}
// NOTE: toggleFullscreen() from Raymond Chen
toggleFullscreen :: proc(window: HWND) {
	@(static)
	prevWindowPlacement: win.WINDOWPLACEMENT
	windowStyle := u32(win.GetWindowLongW(window, GWL_STYLE))
	if (windowStyle & WS_OVERLAPPEDWINDOW) > 0 {
		monitorInfo, windowPlacement := getWindowAndMonitorInfo(window)
		win.SetWindowLongW(window, GWL_STYLE, i32(windowStyle & ~WS_OVERLAPPEDWINDOW))
		using monitorInfo.rcMonitor
		win.SetWindowPos(
			window,
			nil,
			left,
			top,
			right - left,
			bottom - top,
			SWP_NOOWNERZORDER | SWP_FRAMECHANGED,
		)
		prevWindowPlacement = windowPlacement
	} else {
		win.SetWindowLongW(window, GWL_STYLE, i32(windowStyle | WS_OVERLAPPEDWINDOW))
		win.SetWindowPlacement(window, &prevWindowPlacement)
		win.SetWindowPos(window, nil, 0, 0, 0, 0, SWP_NOOWNERZORDER | SWP_FRAMECHANGED)
	}
}

processMessages :: proc() {
	for msg: MSG; PeekMessageW(&msg, nil, 0, 0, PM_REMOVE); {
		TranslateMessage(&msg)
		DispatchMessageW(&msg)
	}
}

// vsync us to 60fps (or whatever the monitor refresh rate is?)
// NOTE: sometimes this returns up to 5.832 ms later than it should
doVsyncBadly :: proc() -> f64 {
	win.DwmFlush()
	return init.time()
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
