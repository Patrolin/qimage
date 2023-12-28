package windows

import "core:c"
import coreWin "core:sys/windows"

GetModuleHandleW :: coreWin.GetModuleHandleW
GetLastError :: coreWin.GetLastError
ExitProcess :: coreWin.ExitProcess
foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	AllocConsole :: proc() -> BOOL ---
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
	GetStdHandle :: proc(nStdHandle: DWORD) -> HANDLE ---
	WriteConsoleA :: proc(hConsoleOutput: HANDLE, lpBuffer: cstring, nNumberOfCharsToWrite: DWORD, lpNumberOfCharsWritten: LPDWORD, lpReserved: LPVOID) -> BOOL ---
}

AdjustWindowRectEx :: coreWin.AdjustWindowRectEx
RegisterClassExW :: coreWin.RegisterClassExW
CreateWindowExW :: coreWin.CreateWindowExW
GetMessageW :: coreWin.GetMessageW
PeekMessageW :: coreWin.PeekMessageW
TranslateMessage :: coreWin.TranslateMessage
DispatchMessageW :: coreWin.DispatchMessageW
DefWindowProcW :: coreWin.DefWindowProcW
PostQuitMessage :: coreWin.PostQuitMessage
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(window: HWND, body: LPCSTR, title: LPCSTR, type: UINT) ---
	SetDIBits :: proc(dc: HDC, bitmap: HBITMAP, start: UINT, cLines: UINT, lpBits: LPVOID, lpBmi: BITMAPINFO, colorUse: UINT) ---
}
GetClientRect :: coreWin.GetClientRect
BeginPaint :: coreWin.BeginPaint
PatBlt :: coreWin.PatBlt
EndPaint :: coreWin.EndPaint

CreateCompatibleDC :: coreWin.CreateCompatibleDC
CreateDIBSection :: coreWin.CreateDIBSection
StretchDIBits :: coreWin.StretchDIBits
DeleteObject :: coreWin.DeleteObject
foreign import gdi32 "system:Gdi32.lib"
@(default_calling_convention = "std")
foreign gdi32 {}

utf8_to_wstring :: coreWin.utf8_to_wstring
utf8_to_utf16 :: coreWin.utf8_to_utf16
wstring_to_utf8 :: coreWin.wstring_to_utf8
utf16_to_utf8 :: coreWin.utf16_to_utf8

didAttachConsole := false
print :: proc(message: cstring) {
	if !didAttachConsole {
		didAttachConsole = bool(AttachConsole(ATTACH_PARENT_PROCESS))
	}
	stdout := GetStdHandle(STD_OUTPUT_HANDLE)
	WriteConsoleA(stdout, message, u32(len(message)), nil, nil)
}
