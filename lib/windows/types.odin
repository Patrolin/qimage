package windows
// https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types

import "core:c"
import coreWin "core:sys/windows"

// paint
PAINTSTRUCT :: coreWin.PAINTSTRUCT
RECT :: coreWin.RECT
HGLRC :: coreWin.HGLRC
CIEXYZ :: struct {
	ciexyzX, ciexyzY, ciexyzZ: FXPT2DOT30,
}
CIEXYZTRIPLE :: struct {
	ciexyzRed, ciexyzGreen, ciexyzBlue: CIEXYZ,
}

// message
POINT :: coreWin.POINT
MSG :: coreWin.MSG
LPMSG :: ^MSG

// proc
CALLBACK :: "stdcall"
WINAPI :: "stdcall"
WNDPROC :: coreWin.WNDPROC

// class
WNDCLASSEXW :: coreWin.WNDCLASSEXW
BITMAPINFO :: coreWin.BITMAPINFO
BITMAPINFOHEADER :: coreWin.BITMAPINFOHEADER
PIXELFORMATDESCRIPTOR :: coreWin.PIXELFORMATDESCRIPTOR
WINDOWINFO :: coreWin.WINDOWINFO

// gl
GLboolean :: bool
GLbyte :: i8
GLubyte :: u8
GLshort :: i16
GLushort :: u16
GLint :: i32
GLuint :: u32
GLfixed :: distinct i32
GLint64 :: i64
GLuint64 :: u64
GLsizei :: u32
GLenum :: u32
GLintptr :: int
GLsizeiptr :: uint
GLsync :: int
GLbitfield :: i32
GLhalf :: f16
GLfloat :: f32
GLclampf :: f32
GLdouble :: f64
GLclampd :: f64

/*
a = ``
b = a.split("\n").map(v => {
    let split = v.split(":");
    if (split.length >= 2) {
        return `${split[0]}:: coreWin.${split[0].trim()}`
    } else {
        return v;
    }
}).join('\n')
console.log(b);
*/
DWORD :: coreWin.DWORD
DWORDLONG :: coreWin.DWORDLONG
QWORD :: coreWin.QWORD
HANDLE :: coreWin.HANDLE
PHANDLE :: coreWin.PHANDLE
HINSTANCE :: coreWin.HINSTANCE
HMODULE :: coreWin.HMODULE
HRESULT :: coreWin.HRESULT
HWND :: coreWin.HWND
HDC :: coreWin.HDC
HMONITOR :: coreWin.HMONITOR
HICON :: coreWin.HICON
HCURSOR :: coreWin.HCURSOR
HMENU :: coreWin.HMENU
HBRUSH :: coreWin.HBRUSH
HGDIOBJ :: coreWin.HGDIOBJ
HBITMAP :: coreWin.HBITMAP
HGLOBAL :: coreWin.HGLOBAL
HHOOK :: coreWin.HHOOK
HKEY :: coreWin.HKEY
HDESK :: coreWin.HDESK
HFONT :: coreWin.HFONT
HRGN :: coreWin.HRGN
BOOL :: coreWin.BOOL
BYTE :: coreWin.BYTE
BOOLEAN :: coreWin.BOOLEAN
GROUP :: coreWin.GROUP
LARGE_INTEGER :: coreWin.LARGE_INTEGER
ULARGE_INTEGER :: coreWin.ULARGE_INTEGER
PULARGE_INTEGER :: coreWin.PULARGE_INTEGER
LONG :: coreWin.LONG
UINT :: coreWin.UINT
INT :: coreWin.INT
SHORT :: coreWin.SHORT
USHORT :: coreWin.USHORT
WCHAR :: coreWin.WCHAR
SIZE_T :: coreWin.SIZE_T
PSIZE_T :: coreWin.PSIZE_T
WORD :: coreWin.WORD
CHAR :: coreWin.CHAR
ULONG_PTR :: coreWin.ULONG_PTR
PULONG_PTR :: coreWin.PULONG_PTR
LPULONG_PTR :: coreWin.LPULONG_PTR
DWORD_PTR :: coreWin.DWORD_PTR
LONG_PTR :: coreWin.LONG_PTR
UINT_PTR :: coreWin.UINT_PTR
ULONG :: coreWin.ULONG
ULONGLONG :: coreWin.ULONGLONG
UCHAR :: coreWin.UCHAR
NTSTATUS :: coreWin.NTSTATUS
COLORREF :: coreWin.COLORREF
LPCOLORREF :: coreWin.LPCOLORREF
LPARAM :: coreWin.LPARAM
WPARAM :: coreWin.WPARAM
LRESULT :: coreWin.LRESULT
LPRECT :: coreWin.LPRECT
LPPOINT :: coreWin.LPPOINT
LSTATUS :: coreWin.LSTATUS
PHKEY :: coreWin.PHKEY

UINT8 :: coreWin.UINT8
UINT16 :: coreWin.UINT16
UINT32 :: coreWin.UINT32
UINT64 :: coreWin.UINT64

INT8 :: coreWin.INT8
INT16 :: coreWin.INT16
INT32 :: coreWin.INT32
INT64 :: coreWin.INT64

ULONG32 :: coreWin.ULONG32
LONG32 :: coreWin.LONG32

ULONG64 :: coreWin.ULONG64
LONG64 :: coreWin.LONG64

PDWORD_PTR :: coreWin.PDWORD_PTR
ATOM :: coreWin.ATOM
FXPT2DOT30 :: coreWin.LONG

wstring :: coreWin.wstring

PBYTE :: coreWin.PBYTE
LPBYTE :: coreWin.LPBYTE
PBOOL :: coreWin.PBOOL
LPBOOL :: coreWin.LPBOOL
LPCSTR :: coreWin.LPCSTR
LPCWSTR :: coreWin.LPCWSTR
LPCTSTR :: coreWin.LPCTSTR
LPDWORD :: coreWin.LPDWORD
PCSTR :: coreWin.PCSTR
PCWSTR :: coreWin.PCWSTR
PDWORD :: coreWin.PDWORD
LPHANDLE :: coreWin.LPHANDLE
LPOVERLAPPED :: coreWin.LPOVERLAPPED
LPPROCESS_INFORMATION :: coreWin.LPPROCESS_INFORMATION
PSECURITY_ATTRIBUTES :: coreWin.PSECURITY_ATTRIBUTES
LPSECURITY_ATTRIBUTES :: coreWin.LPSECURITY_ATTRIBUTES
LPSTARTUPINFOW :: coreWin.LPSTARTUPINFOW
LPTRACKMOUSEEVENT :: coreWin.LPTRACKMOUSEEVENT
VOID :: coreWin.VOID
PVOID :: coreWin.PVOID
LPVOID :: coreWin.LPVOID
PINT :: coreWin.PINT
LPINT :: coreWin.LPINT
PUINT :: coreWin.PUINT
LPUINT :: coreWin.LPUINT
LPWCH :: coreWin.LPWCH
LPWORD :: coreWin.LPWORD
PULONG :: coreWin.PULONG
LPWIN32_FIND_DATAW :: coreWin.LPWIN32_FIND_DATAW
LPWSADATA :: coreWin.LPWSADATA
LPWSAPROTOCOL_INFO :: coreWin.LPWSAPROTOCOL_INFO
LPSTR :: coreWin.LPSTR
LPWSTR :: coreWin.LPWSTR
OLECHAR :: coreWin.OLECHAR
LPOLESTR :: coreWin.LPOLESTR
LPFILETIME :: coreWin.LPFILETIME
LPWSABUF :: coreWin.LPWSABUF
LPWSAOVERLAPPED :: coreWin.LPWSAOVERLAPPED
LPWSAOVERLAPPED_COMPLETION_ROUTINE :: coreWin.LPWSAOVERLAPPED_COMPLETION_ROUTINE
LPCVOID :: coreWin.LPCVOID

PACCESS_TOKEN :: coreWin.PACCESS_TOKEN
PSECURITY_DESCRIPTOR :: coreWin.PSECURITY_DESCRIPTOR
PSID :: coreWin.PSID
PCLAIMS_BLOB :: coreWin.PCLAIMS_BLOB

PCONDITION_VARIABLE :: coreWin.PCONDITION_VARIABLE
PLARGE_INTEGER :: coreWin.PLARGE_INTEGER
PSRWLOCK :: coreWin.PSRWLOCK

CREATE_WAITABLE_TIMER_MANUAL_RESET :: coreWin.CREATE_WAITABLE_TIMER_MANUAL_RESET
CREATE_WAITABLE_TIMER_HIGH_RESOLUTION :: coreWin.CREATE_WAITABLE_TIMER_HIGH_RESOLUTION

TIMER_QUERY_STATE :: coreWin.TIMER_QUERY_STATE
TIMER_MODIFY_STATE :: coreWin.TIMER_MODIFY_STATE
TIMER_ALL_ACCESS :: coreWin.TIMER_ALL_ACCESS

TRUE :: coreWin.TRUE
FALSE :: coreWin.FALSE