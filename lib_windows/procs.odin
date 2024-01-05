package windows

import "core:c"
import "core:fmt"
import "core:strings"
import coreWin "core:sys/windows"

GetModuleHandleW :: coreWin.GetModuleHandleW
GetLastError :: coreWin.GetLastError
ExitProcess :: coreWin.ExitProcess
VirtualAlloc :: coreWin.VirtualAlloc
VirtualFree :: coreWin.VirtualFree
foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	AllocConsole :: proc() -> BOOL ---
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
	GetStdHandle :: proc(nStdHandle: DWORD) -> HANDLE ---
	WriteConsoleA :: proc(hConsoleOutput: HANDLE, lpBuffer: cstring, nNumberOfCharsToWrite: DWORD, lpNumberOfCharsWritten: LPDWORD, lpReserved: LPVOID) -> BOOL ---
	WriteConsoleW :: proc(hConsoleOutput: HANDLE, lpBuffer: wstring, nNumberOfCharsToWrite: DWORD, lpNumberOfCharsWritten: LPDWORD, lpReserved: LPVOID) -> BOOL ---
}

// window
AdjustWindowRectEx :: coreWin.AdjustWindowRectEx
RegisterClassExW :: coreWin.RegisterClassExW
CreateWindowExW :: coreWin.CreateWindowExW
GetMessageW :: coreWin.GetMessageW
PeekMessageW :: coreWin.PeekMessageW
TranslateMessage :: coreWin.TranslateMessage
DispatchMessageW :: coreWin.DispatchMessageW
DefWindowProcW :: coreWin.DefWindowProcW
PostQuitMessage :: coreWin.PostQuitMessage
// paint
GetDC :: coreWin.GetDC
ReleaseDC :: coreWin.ReleaseDC
GetClientRect :: coreWin.GetClientRect
GetWindowRect :: coreWin.GetWindowRect
GetWindowInfo :: coreWin.GetWindowInfo
GetSystemMetrics :: coreWin.GetSystemMetrics
MoveWindow :: coreWin.MoveWindow
BeginPaint :: coreWin.BeginPaint
PatBlt :: coreWin.PatBlt
EndPaint :: coreWin.EndPaint
foreign import user32 "system:user32.lib"
@(default_calling_convention = "std")
foreign user32 {
	MessageBoxA :: proc(window: HWND, body: LPCSTR, title: LPCSTR, type: UINT) ---
	//MessageBoxW :: proc(window: HWND, body: LPCWSTR, title: LPCWSTR, type: UINT) ---
}

// paint
CreateCompatibleDC :: coreWin.CreateCompatibleDC
CreateDIBSection :: coreWin.CreateDIBSection
StretchDIBits :: coreWin.StretchDIBits
DeleteObject :: coreWin.DeleteObject
foreign import gdi32 "system:Gdi32.lib"
@(default_calling_convention = "std")
foreign gdi32 {}

// gl
ChoosePixelFormat :: coreWin.ChoosePixelFormat
DescribePixelFormat :: coreWin.DescribePixelFormat
SetPixelFormat :: coreWin.SetPixelFormat
wglCreateContext :: coreWin.wglCreateContext
wglMakeCurrent :: coreWin.wglMakeCurrent
SwapBuffers :: coreWin.SwapBuffers
foreign import Opengl32 "system:Opengl32.lib"
@(default_calling_convention = "std")
foreign Opengl32 {
	glViewport :: proc(x, y: GLint, width, height: GLsizei) ---
	glClearColor :: proc(red, green, blue, alpha: GLclampf) ---
	glClear :: proc(mask: GLbitfield) ---
	glGetFloatv :: proc(name: GLenum, values: ^GLfloat) ---
}

// dwm
DwmGetWindowAttribute :: coreWin.DwmGetWindowAttribute
foreign import Dwmapi "system:Dwmapi.lib"
@(default_calling_convention = "std")
foreign Dwmapi {
}

// alloc
alloc :: proc(size: uint) -> LPVOID {
	return VirtualAlloc(nil, size, MEM_COMMIT, PAGE_READWRITE)
}
free :: proc(ptr: LPVOID) -> BOOL {
	return VirtualFree(ptr, 0, MEM_RELEASE)
}

@(private)
makeWindowClassCounter := 0
makeWindowClass :: proc(class: WNDCLASSEXW) -> wstring {
	class := class
	if class.cbSize == 0 {
		class.cbSize = size_of(WNDCLASSEXW)
	}
	if class.lpszClassName == nil {
		className := fmt.aprintf("libWin_class_%v", makeWindowClassCounter)
		class.lpszClassName = utf8_to_wstring(className, context.allocator)
		makeWindowClassCounter += 1
	}
	if (RegisterClassExW(&class) == 0) {
		lastError := GetLastError()
		printf("error: %v\n", lastError)
		assert(false)
	}
	return class.lpszClassName
}
createWindow :: proc(
	windowClass: wstring,
	title: wstring,
	width, height: LONG,
	useOuterSize := false,
) -> HWND {
	width, height := width, height
	if useOuterSize {
		// NOTE: SM_CYSIZEFRAME, SM_CXPADDEDBORDER, SM_CYMENU are added conditionally
		minCaptionHeight := GetSystemMetrics(SM_CYCAPTION)
		// maxCaptionHeight := GetSystemMetrics(SM_CYCAPTION) + GetSystemMetrics(SM_CYSIZEFRAME) + GetSystemMetrics(SM_CXPADDEDBORDER)
		height -= minCaptionHeight
	}
	adjustRect := RECT{0, 0, width, height}
	AdjustWindowRectEx(&adjustRect, WS_OVERLAPPEDWINDOW, FALSE, 0)
	width = adjustRect.right - adjustRect.left
	height = adjustRect.bottom - adjustRect.top

	window := CreateWindowExW(
		0,
		windowClass,
		title,
		WS_OVERLAPPEDWINDOW | WS_VISIBLE,
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
		print(fmt.aprintf("error: %v\n", lastError))
		assert(false)
	}
	return window
}
