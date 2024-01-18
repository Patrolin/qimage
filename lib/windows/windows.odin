package lib_windows
import winCon "console"
import coreWin "core:sys/windows"
import "window"

// https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types
WORD :: coreWin.WORD
DWORD :: coreWin.DWORD
QWORD :: coreWin.QWORD
UINT :: coreWin.UINT
LONG :: coreWin.LONG
TRUE :: coreWin.TRUE
FALSE :: coreWin.FALSE

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

// console
string_to_wstring :: winCon.string_to_wstring
wstring_to_string :: winCon.wstring_to_string

// window
registerWindowClass :: window.registerWindowClass
createWindow :: window.createWindow
toggleFullscreen :: window.toggleFullscreen
GetMessageW :: coreWin.GetMessageW
PeekMessageW :: coreWin.PeekMessageW
TranslateMessage :: coreWin.TranslateMessage
DispatchMessageW :: coreWin.DispatchMessageW
DefWindowProcW :: coreWin.DefWindowProcW
PostQuitMessage :: coreWin.PostQuitMessage
// NOTE: rawinput
RegisterRawInputDevices :: coreWin.RegisterRawInputDevices
GetRawInputData :: coreWin.GetRawInputData
