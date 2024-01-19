package lib_windows
import coreWin "core:sys/windows"

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
