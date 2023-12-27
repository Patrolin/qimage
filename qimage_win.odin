// odin run qimage_win.odin -file -subsystem:windows
package main

import "core:fmt"
import "core:runtime"
import coreWin "core:sys/windows"
import win "windows"

main :: proc() {
	className := win.utf8_to_wstring("qimage")
	windowTitle := win.utf8_to_wstring("Title")
	//hInstance := win.HINSTANCE(win.GetModuleHandleW(nil))
	windowClass := win.WNDCLASSW {
		style         = win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc   = messageHandlerWrapper,
		lpszClassName = className,
		//hInstance     = hInstance,
	}
	cls := win.RegisterClassW(&windowClass)
	assert(win.GetLastError() == 0)
	hWindow := win.CreateWindowExW(
		0,
		windowClass.lpszClassName,
		windowTitle,
		coreWin.WS_OVERLAPPEDWINDOW | coreWin.WS_VISIBLE,
		0,
		100,
		300,
		300,
		nil,
		nil,
		//hInstance,
		nil,
		nil,
	)
	assert(win.GetLastError() == 0)
	assert(hWindow != nil)
	for {
		message: win.MSG
		messageResult := win.GetMessageA(&message, nil, 0, 0)
		if messageResult > 0 {
			win.TranslateMessage(&message)
			win.DispatchMessageA(&message)
		} else {
			break
		}
	}
}

messageHandlerWrapper :: proc "stdcall" (
	windowHandle: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	context = runtime.default_context()
	errorCode := messageHandler(windowHandle, message, wParam, lParam)
	return errorCode
}

messageHandler :: proc(
	windowHandle: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	errorCode: win.LRESULT = 0
	switch (message) {
	case win.WM_ACTIVATEAPP:
		win.print(fmt.ctprintf("WM_ACTIVATEAPP\n"))
	case win.WM_SIZE:
		win.print(fmt.ctprintf("WM_SIZE\n"))
	case win.WM_DESTROY:
		win.print(fmt.ctprintf("WM_DESTROY\n"))
	case win.WM_CLOSE:
		win.print(fmt.ctprintf("WM_CLOSE\n"))
	case win.WM_CREATE:
		win.print(fmt.ctprintf("WM_CREATE\n"))
		errorCode = 1
	case:
		errorCode = 1
	}
	//win.MessageBoxA(nil, "Message body", "Message title", win.MB_OK)
	//win.ExitProcess(0)
	return errorCode
}
