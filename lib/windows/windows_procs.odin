package windows
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

CALLBACK :: "stdcall"
WINAPI :: "stdcall"

// TODO: move all this to separate subsystems

// basics
//GetModuleHandleW :: coreWin.GetModuleHandleW
GetLastError :: coreWin.GetLastError
ExitProcess :: coreWin.ExitProcess
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(window: HWND, body: coreWin.LPCSTR, title: coreWin.LPCSTR, type: UINT) ---
}

// console
string_to_wstring :: winCon.string_to_wstring
wstring_to_string :: winCon.wstring_to_string

// window
makeWindowClass :: window.makeWindowClass
createWindow :: window.createWindow
toggleFullscreen :: window.toggleFullscreen
GetMessageW :: coreWin.GetMessageW
PeekMessageW :: coreWin.PeekMessageW
TranslateMessage :: coreWin.TranslateMessage
DispatchMessageW :: coreWin.DispatchMessageW
DefWindowProcW :: coreWin.DefWindowProcW
PostQuitMessage :: coreWin.PostQuitMessage

// paint
POINT :: coreWin.POINT
RECT :: coreWin.RECT
BITMAPINFO :: coreWin.BITMAPINFO
BITMAPINFOHEADER :: coreWin.BITMAPINFOHEADER
PAINTSTRUCT :: coreWin.PAINTSTRUCT

GetDC :: coreWin.GetDC
ReleaseDC :: coreWin.ReleaseDC
BeginPaint :: coreWin.BeginPaint
PatBlt :: coreWin.PatBlt
EndPaint :: coreWin.EndPaint
CreateCompatibleDC :: coreWin.CreateCompatibleDC
CreateDIBSection :: coreWin.CreateDIBSection
StretchDIBits :: coreWin.StretchDIBits
DeleteObject :: coreWin.DeleteObject
GetClientRect :: coreWin.GetClientRect
GetWindowRect :: coreWin.GetWindowRect
