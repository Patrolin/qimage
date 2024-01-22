package lib_windows
import "core:fmt"
import coreWin "core:sys/windows"

WNDCLASSEXW :: coreWin.WNDCLASSEXW
RECT :: coreWin.RECT

WS_OVERLAPPEDWINDOW :: coreWin.WS_OVERLAPPEDWINDOW
WS_VISIBLE :: coreWin.WS_VISIBLE
CW_USEDEFAULT :: coreWin.CW_USEDEFAULT
GWL_STYLE :: -16
MONITOR_DEFAULTTONEAREST :: coreWin.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST
SWP_FRAMECHANGED :: 0x0020
SWP_NOOWNERZORDER :: 0x0200

//GetModuleHandleW :: coreWin.GetModuleHandleW
RegisterClassExW :: coreWin.RegisterClassExW
AdjustWindowRectEx :: coreWin.AdjustWindowRectEx
CreateWindowExW :: coreWin.CreateWindowExW
// messages
GetMessageW :: coreWin.GetMessageW
PeekMessageW :: coreWin.PeekMessageW
TranslateMessage :: coreWin.TranslateMessage
DispatchMessageW :: coreWin.DispatchMessageW
DefWindowProcW :: coreWin.DefWindowProcW
PostQuitMessage :: coreWin.PostQuitMessage
// rawinput
RegisterRawInputDevices :: coreWin.RegisterRawInputDevices
GetRawInputData :: coreWin.GetRawInputData

registerWindowClass :: proc(class: WNDCLASSEXW) -> wstring {
	@(static)
	registerWindowClassCounter := 0
	class := class
	if class.cbSize == 0 {
		class.cbSize = size_of(WNDCLASSEXW)
	}
	if class.lpszClassName == nil {
		className := fmt.aprintf("libWin_%v", registerWindowClassCounter)
		class.lpszClassName = string_to_wstring(className, context.allocator)
		registerWindowClassCounter += 1
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
		windowStyle | WS_VISIBLE,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		width,
		height,
		nil,
		nil,
		nil,
		nil,
	)
	if window == nil {
		lastError := GetLastError()
		assert(false, fmt.tprintf("error: %v\n", lastError))
	}
	return window
}

getWindowAndMonitorInfo :: proc(
	window: HWND,
) -> (
	monitorInfo: coreWin.MONITORINFO,
	windowPlacement: coreWin.WINDOWPLACEMENT,
) {
	monitor := coreWin.MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST)
	monitorInfo.cbSize = size_of(coreWin.MONITORINFO)
	assert(bool(coreWin.GetWindowPlacement(window, &windowPlacement)))
	assert(bool(coreWin.GetMonitorInfoW(monitor, &monitorInfo)))
	return
}
// NOTE: toggleFullscreen() from Raymond Chen
toggleFullscreen :: proc(window: HWND) {
	@(static)
	prevWindowPlacement: coreWin.WINDOWPLACEMENT
	windowStyle := u32(coreWin.GetWindowLongW(window, GWL_STYLE))
	if (windowStyle & WS_OVERLAPPEDWINDOW) > 0 {
		monitorInfo, windowPlacement := getWindowAndMonitorInfo(window)
		coreWin.SetWindowLongW(window, GWL_STYLE, i32(windowStyle & ~WS_OVERLAPPEDWINDOW))
		using monitorInfo.rcMonitor
		coreWin.SetWindowPos(
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
		coreWin.SetWindowLongW(window, GWL_STYLE, i32(windowStyle | WS_OVERLAPPEDWINDOW))
		coreWin.SetWindowPlacement(window, &prevWindowPlacement)
		coreWin.SetWindowPos(window, nil, 0, 0, 0, 0, SWP_NOOWNERZORDER | SWP_FRAMECHANGED)
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
	coreWin.DwmFlush()
	return time()
}
/* NOTE: doVsyncWell():
	for isRunning {
		processInputs()
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
			processInputs()
			updateAndRender()
		}
*/
