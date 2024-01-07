package windowsWindow
import winCon "../console"
import "core:fmt"
import coreWin "core:sys/windows"

MONITOR_DEFAULTTONEAREST :: coreWin.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST
WNDCLASSEXW :: coreWin.WNDCLASSEXW
wstring :: coreWin.wstring
LONG :: coreWin.LONG
HWND :: coreWin.HWND
RECT :: coreWin.RECT

GWL_STYLE :: -16
MONITOR_DEFAULTTOPRIMARY :: 0x00000002
SWP_FRAMECHANGED :: 0x0020
SWP_NOOWNERZORDER :: 0x0200
WS_OVERLAPPEDWINDOW :: coreWin.WS_OVERLAPPEDWINDOW
WS_VISIBLE :: coreWin.WS_VISIBLE
CW_USEDEFAULT :: coreWin.CW_USEDEFAULT
FALSE :: coreWin.FALSE

RegisterClassExW :: coreWin.RegisterClassExW
GetLastError :: coreWin.GetLastError
AdjustWindowRectEx :: coreWin.AdjustWindowRectEx
CreateWindowExW :: coreWin.CreateWindowExW
// NOTE: fullscreen nonsense
GetWindowLong :: coreWin.GetWindowLongW
GetWindowPlacement :: coreWin.GetWindowPlacement
GetMonitorInfoW :: coreWin.GetMonitorInfoW
SetWindowLong :: coreWin.SetWindowLongW
SetWindowPlacement :: coreWin.SetWindowPlacement
SetWindowPos :: coreWin.SetWindowPos

@(private)
makeWindowClassCounter := 0
makeWindowClass :: proc(class: WNDCLASSEXW) -> wstring {
	class := class
	if class.cbSize == 0 {
		class.cbSize = size_of(WNDCLASSEXW)
	}
	if class.lpszClassName == nil {
		className := fmt.aprintf("libWin_class_%v", makeWindowClassCounter)
		class.lpszClassName = winCon.utf8_to_wstring(className, context.allocator)
		makeWindowClassCounter += 1
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

@(private)
prevWindowPlacement: coreWin.WINDOWPLACEMENT
// NOTE: toggleFullscreen() from Raymond Chen
toggleFullscreen :: proc(window: HWND) {
	windowStyle := u32(GetWindowLong(window, GWL_STYLE))
	if (windowStyle & WS_OVERLAPPEDWINDOW) > 0 {
		monitor := coreWin.MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST)
		monitorInfo: coreWin.MONITORINFO = {
			cbSize = size_of(coreWin.MONITORINFO),
		}

		if GetWindowPlacement(window, &prevWindowPlacement) &&
		   GetMonitorInfoW(monitor, &monitorInfo) {
			SetWindowLong(window, GWL_STYLE, i32(windowStyle & ~WS_OVERLAPPEDWINDOW))
			using monitorInfo.rcMonitor
			width := right - left
			height := bottom - top
			SetWindowPos(
				window,
				nil,
				left,
				top,
				width,
				height,
				SWP_NOOWNERZORDER | SWP_FRAMECHANGED,
			)
		}
	} else {
		SetWindowLong(window, GWL_STYLE, i32(windowStyle | WS_OVERLAPPEDWINDOW))
		SetWindowPlacement(window, &prevWindowPlacement)
		SetWindowPos(window, nil, 0, 0, 0, 0, SWP_NOOWNERZORDER | SWP_FRAMECHANGED)
	}
}
