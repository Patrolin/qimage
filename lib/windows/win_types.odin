package lib_windows
import win "core:sys/windows"

// https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types
WORD :: win.WORD
DWORD :: win.DWORD
QWORD :: win.QWORD
UINT :: win.UINT
LONG :: win.LONG
BOOL :: win.BOOL
wstring :: win.wstring

HANDLE :: win.HANDLE
HWND :: win.HWND
HDC :: win.HDC
WNDPROC :: win.WNDPROC
LPARAM :: win.LPARAM
WPARAM :: win.WPARAM
LRESULT :: win.LRESULT
MSG :: win.MSG
RAWINPUTDEVICE :: win.RAWINPUTDEVICE
RAWINPUTHEADER :: win.RAWINPUTHEADER
RAWINPUT :: win.RAWINPUT
HRAWINPUT :: win.HRAWINPUT
LARGE_INTEGER :: win.LARGE_INTEGER
POINT :: win.POINT
