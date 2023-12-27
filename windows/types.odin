package windows
// https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types

import "core:c"

// int
BOOL :: c.int
INT8 :: i8
INT16 :: i16
INT :: i32
INT32 :: i32
INT64 :: i64

UINT8 :: u8
UINT16 :: u16
UINT :: u32
UINT32 :: u32
UINT64 :: u64

WORD :: u16
DWORD :: u32
LPDWORD :: ^DWORD
QWORD :: u64

LONG :: c.long
LONGLONG :: c.longlong

CHAR :: u8
WCHAR :: u16
ATOM :: WORD
LRESULT :: i64
LPARAM :: i64
WPARAM :: ^UINT

// string
LPCSTR :: cstring // null-terminated ANSI
LPCWSTR :: [^]WCHAR // null-terminated UTF-16LE
PWSTR :: [^]WCHAR // null-terminated UTF-16LE

// handle
LPVOID :: rawptr
HANDLE :: distinct rawptr // object handle
HBRUSH :: distinct HANDLE
HCURSOR :: distinct HANDLE
HICON :: distinct HANDLE
HINSTANCE :: distinct HANDLE
HMENU :: distinct HANDLE
HMODULE :: distinct HANDLE
HWND :: distinct HANDLE // window handle

// message
POINT :: struct {
	x, y: LONG,
}
MSG :: struct {
	hwnd:     HWND,
	message:  UINT,
	wParam:   WPARAM,
	lParam:   LPARAM,
	time:     DWORD,
	pt:       POINT,
	lPrivate: DWORD,
}
LPMSG :: ^MSG

// proc
CALLBACK :: "stdcall"
WINAPI :: "stdcall"
WNDPROC :: #type proc "stdcall" (_: HWND, _: UINT, _: WPARAM, _: LPARAM) -> LRESULT

// class
WNDCLASSW :: struct {
	style:         UINT,
	lpfnWndProc:   WNDPROC,
	cbClsExtra:    c.int,
	cbWndExtra:    c.int,
	hInstance:     HINSTANCE,
	hIcon:         HICON,
	hCursor:       HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName:  LPCWSTR,
	lpszClassName: LPCWSTR,
}
