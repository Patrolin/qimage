package lib_windows
import coreWin "core:sys/windows"
import winInfo "info"
import winWindow "window"
import winWstring "wstring"

// https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types
WORD :: coreWin.WORD
DWORD :: coreWin.DWORD
QWORD :: coreWin.QWORD
UINT :: coreWin.UINT
LONG :: coreWin.LONG
TRUE :: coreWin.TRUE
FALSE :: coreWin.FALSE
wstring :: coreWin.wstring

HANDLE :: coreWin.HANDLE
HWND :: coreWin.HWND
HDC :: coreWin.HDC
WNDPROC :: coreWin.WNDPROC
LPARAM :: coreWin.LPARAM
WPARAM :: coreWin.WPARAM
LRESULT :: coreWin.LRESULT
MSG :: coreWin.MSG
RAWINPUTDEVICE :: coreWin.RAWINPUTDEVICE
RAWINPUTHEADER :: coreWin.RAWINPUTHEADER
RAWINPUT :: coreWin.RAWINPUT
HRAWINPUT :: coreWin.HRAWINPUT
LARGE_INTEGER :: coreWin.LARGE_INTEGER

CALLBACK :: "stdcall"
WINAPI :: "stdcall"

// basics
//GetModuleHandleW :: coreWin.GetModuleHandleW
GetLastError :: coreWin.GetLastError
ExitProcess :: coreWin.ExitProcess
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(window: HWND, body: coreWin.LPCSTR, title: coreWin.LPCSTR, type: UINT) ---
}
LOWORD :: coreWin.LOWORD
HIWORD :: coreWin.HIWORD

// info
windows_info: winInfo.WindowsInfo
initWindowsInfo :: proc() {
	winInfo.initWindowsInfo(&windows_info)
}
QueryPerformanceCounter :: coreWin.QueryPerformanceCounter

// wstring
string_to_wstring :: winWstring.string_to_wstring
wstring_to_string :: winWstring.wstring_to_string

// window
registerWindowClass :: winWindow.registerWindowClass
createWindow :: winWindow.createWindow
toggleFullscreen :: winWindow.toggleFullscreen
doVsyncBadly :: winWindow.doVsyncBadly
GetMessageW :: coreWin.GetMessageW
PeekMessageW :: coreWin.PeekMessageW
TranslateMessage :: coreWin.TranslateMessage
DispatchMessageW :: coreWin.DispatchMessageW
DefWindowProcW :: coreWin.DefWindowProcW
PostQuitMessage :: coreWin.PostQuitMessage
// rawinput
RegisterRawInputDevices :: coreWin.RegisterRawInputDevices
GetRawInputData :: coreWin.GetRawInputData
