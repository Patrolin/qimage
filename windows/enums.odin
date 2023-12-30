package windows

import "core:c"
import coreWin "core:sys/windows"

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
// alloc
MEM_COMMIT :: coreWin.MEM_COMMIT
MEM_RESERVE :: coreWin.MEM_RESERVE
MEM_DECOMMIT :: coreWin.MEM_DECOMMIT
MEM_RELEASE :: coreWin.MEM_RELEASE
MEM_FREE :: coreWin.MEM_FREE
MEM_PRIVATE :: coreWin.MEM_PRIVATE
MEM_MAPPED :: coreWin.MEM_MAPPED
MEM_RESET :: coreWin.MEM_RESET
MEM_TOP_DOWN :: coreWin.MEM_TOP_DOWN
MEM_LARGE_PAGES :: coreWin.MEM_LARGE_PAGES
MEM_4MB_PAGES :: coreWin.MEM_4MB_PAGES

PAGE_NOACCESS :: coreWin.PAGE_NOACCESS
PAGE_READONLY :: coreWin.PAGE_READONLY
PAGE_READWRITE :: coreWin.PAGE_READWRITE
PAGE_WRITECOPY :: coreWin.PAGE_WRITECOPY
PAGE_EXECUTE :: coreWin.PAGE_EXECUTE
PAGE_EXECUTE_READ :: coreWin.PAGE_EXECUTE_READ
PAGE_EXECUTE_READWRITE :: coreWin.PAGE_EXECUTE_READWRITE
PAGE_EXECUTE_WRITECOPY :: coreWin.PAGE_EXECUTE_WRITECOPY
PAGE_GUARD :: coreWin.PAGE_GUARD
PAGE_NOCACHE :: coreWin.PAGE_NOCACHE
PAGE_WRITECOMBINE :: coreWin.PAGE_WRITECOMBINE

// console
ATTACH_PARENT_PROCESS :: transmute(DWORD)i32(-1)
STD_INPUT_HANDLE :: transmute(DWORD)i32(-10)
STD_OUTPUT_HANDLE :: transmute(DWORD)i32(-11)
STD_ERROR_HANDLE :: transmute(DWORD)i32(-12)

// create window
CW_USEDEFAULT :: coreWin.CW_USEDEFAULT

// paint
DIB_PAL_COLORS :: coreWin.DIB_PAL_COLORS
DIB_RGB_COLORS :: coreWin.DIB_RGB_COLORS
BI_RGB :: coreWin.BI_RGB
BI_BITFIELDS :: coreWin.BI_BITFIELDS

SRCCOPY :: coreWin.SRCCOPY
SRCPAINT :: coreWin.SRCPAINT
SRCAND :: coreWin.SRCAND
SRCINVERT :: coreWin.SRCINVERT
SRCERASE :: coreWin.SRCERASE
NOTSRCCOPY :: coreWin.NOTSRCCOPY
NOTSRCERASE :: coreWin.NOTSRCERASE
MERGECOPY :: coreWin.MERGECOPY
MERGEPAINT :: coreWin.MERGEPAINT
PATCOPY :: coreWin.PATCOPY
PATPAINT :: coreWin.PATPAINT
PATINVERT :: coreWin.PATINVERT
DSTINVERT :: coreWin.DSTINVERT
BLACKNESS :: coreWin.BLACKNESS
WHITENESS :: coreWin.WHITENESS
NOMIRRORBITMAP :: coreWin.NOMIRRORBITMAP
CAPTUREBLT :: coreWin.CAPTUREBLT

// message box
MB_OK :: coreWin.MB_OK
MB_OKCANCEL :: coreWin.MB_OKCANCEL
MB_ABORTRETRYIGNORE :: coreWin.MB_ABORTRETRYIGNORE
MB_YESNOCANCEL :: coreWin.MB_YESNOCANCEL
MB_YESNO :: coreWin.MB_YESNO
MB_RETRYCANCEL :: coreWin.MB_RETRYCANCEL
MB_CANCELTRYCONTINUE :: coreWin.MB_CANCELTRYCONTINUE

MB_ICONHAND :: coreWin.MB_ICONHAND
MB_ICONQUESTION :: coreWin.MB_ICONQUESTION
MB_ICONEXCLAMATION :: coreWin.MB_ICONEXCLAMATION
MB_ICONASTERISK :: coreWin.MB_ICONASTERISK
MB_USERICON :: coreWin.MB_USERICON
MB_ICONWARNING :: coreWin.MB_ICONWARNING
MB_ICONERROR :: coreWin.MB_ICONERROR
MB_ICONINFORMATION :: coreWin.MB_ICONINFORMATION
MB_ICONSTOP :: coreWin.MB_ICONSTOP

MB_DEFBUTTON1 :: coreWin.MB_DEFBUTTON1
MB_DEFBUTTON2 :: coreWin.MB_DEFBUTTON2
MB_DEFBUTTON3 :: coreWin.MB_DEFBUTTON3
MB_DEFBUTTON4 :: coreWin.MB_DEFBUTTON4

MB_APPLMODAL :: coreWin.MB_APPLMODAL
MB_SYSTEMMODAL :: coreWin.MB_SYSTEMMODAL
MB_TASKMODAL :: coreWin.MB_TASKMODAL
MB_HELP :: coreWin.MB_HELP

MB_NOFOCUS :: coreWin.MB_NOFOCUS
MB_SETFOREGROUND :: coreWin.MB_SETFOREGROUND
MB_DEFAULT_DESKTOP_ONLY :: coreWin.MB_DEFAULT_DESKTOP_ONLY
MB_TOPMOST :: coreWin.MB_TOPMOST
MB_RIGHT :: coreWin.MB_RIGHT
MB_RTLREADING :: coreWin.MB_RTLREADING

MB_SERVICE_NOTIFICATION :: coreWin.MB_SERVICE_NOTIFICATION
MB_SERVICE_NOTIFICATION_NT3X :: coreWin.MB_SERVICE_NOTIFICATION_NT3X

MB_TYPEMASK :: coreWin.MB_TYPEMASK
MB_ICONMASK :: coreWin.MB_ICONMASK
MB_DEFMASK :: coreWin.MB_DEFMASK
MB_MODEMASK :: coreWin.MB_MODEMASK
MB_MISCMASK :: coreWin.MB_MISCMASK

// dialog command ids
IDOK :: coreWin.IDOK
IDCANCEL :: coreWin.IDCANCEL
IDABORT :: coreWin.IDABORT
IDRETRY :: coreWin.IDRETRY
IDIGNORE :: coreWin.IDIGNORE
IDYES :: coreWin.IDYES
IDNO :: coreWin.IDNO
IDCLOSE :: coreWin.IDCLOSE
IDHELP :: coreWin.IDHELP
IDTRYAGAIN :: coreWin.IDTRYAGAIN
IDCONTINUE :: coreWin.IDCONTINUE
IDTIMEOUT :: coreWin.IDTIMEOUT

// class style
CS_VREDRAW :: coreWin.CS_VREDRAW
CS_HREDRAW :: coreWin.CS_HREDRAW
CS_DBLCLKS :: coreWin.CS_DBLCLKS
CS_OWNDC :: coreWin.CS_OWNDC
CS_CLASSDC :: coreWin.CS_CLASSDC
CS_PARENTDC :: coreWin.CS_PARENTDC
CS_NOCLOSE :: coreWin.CS_NOCLOSE
CS_SAVEBITS :: coreWin.CS_SAVEBITS
CS_BYTEALIGNCLIENT :: coreWin.CS_BYTEALIGNCLIENT
CS_BYTEALIGNWINDOW :: coreWin.CS_BYTEALIGNWINDOW
CS_GLOBALCLASS :: coreWin.CS_GLOBALCLASS
CS_DROPSHADOW :: coreWin.CS_DROPSHADOW

// window style
WS_BORDER :: coreWin.WS_BORDER
WS_CAPTION :: coreWin.WS_CAPTION
WS_CHILD :: coreWin.WS_CHILD
WS_CHILDWINDOW :: coreWin.WS_CHILDWINDOW
WS_CLIPCHILDREN :: coreWin.WS_CLIPCHILDREN
WS_CLIPSIBLINGS :: coreWin.WS_CLIPSIBLINGS
WS_DISABLED :: coreWin.WS_DISABLED
WS_DLGFRAME :: coreWin.WS_DLGFRAME
WS_GROUP :: coreWin.WS_GROUP
WS_HSCROLL :: coreWin.WS_HSCROLL
WS_ICONIC :: coreWin.WS_ICONIC
WS_MAXIMIZE :: coreWin.WS_MAXIMIZE
WS_MAXIMIZEBOX :: coreWin.WS_MAXIMIZEBOX
WS_MINIMIZE :: coreWin.WS_MINIMIZE
WS_MINIMIZEBOX :: coreWin.WS_MINIMIZEBOX
WS_OVERLAPPED :: coreWin.WS_OVERLAPPED
WS_OVERLAPPEDWINDOW :: coreWin.WS_OVERLAPPEDWINDOW
WS_POPUP :: coreWin.WS_POPUP
WS_POPUPWINDOW :: coreWin.WS_POPUPWINDOW
WS_SIZEBOX :: coreWin.WS_SIZEBOX
WS_SYSMENU :: coreWin.WS_SYSMENU
WS_TABSTOP :: coreWin.WS_TABSTOP
WS_THICKFRAME :: coreWin.WS_THICKFRAME
WS_TILED :: coreWin.WS_TILED
WS_TILEDWINDOW :: coreWin.WS_TILEDWINDOW
WS_VISIBLE :: coreWin.WS_VISIBLE
WS_VSCROLL :: coreWin.WS_VSCROLL

// window style extra
WS_EX_ACCEPTFILES :: coreWin.WS_EX_ACCEPTFILES
WS_EX_APPWINDOW :: coreWin.WS_EX_APPWINDOW
WS_EX_CLIENTEDGE :: coreWin.WS_EX_CLIENTEDGE
WS_EX_COMPOSITED :: coreWin.WS_EX_COMPOSITED
WS_EX_CONTEXTHELP :: coreWin.WS_EX_CONTEXTHELP
WS_EX_CONTROLPARENT :: coreWin.WS_EX_CONTROLPARENT
WS_EX_DLGMODALFRAME :: coreWin.WS_EX_DLGMODALFRAME
WS_EX_DRAGDETECT :: coreWin.WS_EX_DRAGDETECT
WS_EX_LAYERED :: coreWin.WS_EX_LAYERED
WS_EX_LAYOUTRTL :: coreWin.WS_EX_LAYOUTRTL
WS_EX_LEFT :: coreWin.WS_EX_LEFT
WS_EX_LEFTSCROLLBAR :: coreWin.WS_EX_LEFTSCROLLBAR
WS_EX_LTRREADING :: coreWin.WS_EX_LTRREADING
WS_EX_MDICHILD :: coreWin.WS_EX_MDICHILD
WS_EX_NOACTIVATE :: coreWin.WS_EX_NOACTIVATE
WS_EX_NOINHERITLAYOUT :: coreWin.WS_EX_NOINHERITLAYOUT
WS_EX_NOPARENTNOTIFY :: coreWin.WS_EX_NOPARENTNOTIFY
WS_EX_NOREDIRECTIONBITMAP :: coreWin.WS_EX_NOREDIRECTIONBITMAP
WS_EX_OVERLAPPEDWINDOW :: coreWin.WS_EX_OVERLAPPEDWINDOW
WS_EX_PALETTEWINDOW :: coreWin.WS_EX_PALETTEWINDOW
WS_EX_RIGHT :: coreWin.WS_EX_RIGHT
WS_EX_RIGHTSCROLLBAR :: coreWin.WS_EX_RIGHTSCROLLBAR
WS_EX_RTLREADING :: coreWin.WS_EX_RTLREADING
WS_EX_STATICEDGE :: coreWin.WS_EX_STATICEDGE
WS_EX_TOOLWINDOW :: coreWin.WS_EX_TOOLWINDOW
WS_EX_TOPMOST :: coreWin.WS_EX_TOPMOST
WS_EX_TRANSPARENT :: coreWin.WS_EX_TRANSPARENT
WS_EX_WINDOWEDGE :: coreWin.WS_EX_WINDOWEDGE

// peek message
PM_NOREMOVE :: coreWin.PM_NOREMOVE
PM_REMOVE :: coreWin.PM_REMOVE
PM_NOYIELD :: coreWin.PM_NOYIELD

// peek message ?
PM_QS_INPUT :: coreWin.PM_QS_INPUT
PM_QS_PAINT :: coreWin.PM_QS_PAINT
PM_QS_POSTMESSAGE :: coreWin.PM_QS_POSTMESSAGE
PM_QS_SENDMESSAGE :: coreWin.PM_QS_SENDMESSAGE

// pixel types
PFD_TYPE_RGBA :: coreWin.PFD_TYPE_RGBA
PFD_TYPE_COLORINDEX :: coreWin.PFD_TYPE_COLORINDEX

// layer types
PFD_MAIN_PLANE :: coreWin.PFD_MAIN_PLANE
PFD_OVERLAY_PLANE :: coreWin.PFD_OVERLAY_PLANE
PFD_UNDERLAY_PLANE :: coreWin.PFD_UNDERLAY_PLANE

// PIXELFORMATDESCRIPTOR flags
PFD_DOUBLEBUFFER :: coreWin.PFD_DOUBLEBUFFER
PFD_STEREO :: coreWin.PFD_STEREO
PFD_DRAW_TO_WINDOW :: coreWin.PFD_DRAW_TO_WINDOW
PFD_DRAW_TO_BITMAP :: coreWin.PFD_DRAW_TO_BITMAP
PFD_SUPPORT_GDI :: coreWin.PFD_SUPPORT_GDI
PFD_SUPPORT_OPENGL :: coreWin.PFD_SUPPORT_OPENGL
PFD_GENERIC_FORMAT :: coreWin.PFD_GENERIC_FORMAT
PFD_NEED_PALETTE :: coreWin.PFD_NEED_PALETTE
PFD_NEED_SYSTEM_PALETTE :: coreWin.PFD_NEED_SYSTEM_PALETTE
PFD_SWAP_EXCHANGE :: coreWin.PFD_SWAP_EXCHANGE
PFD_SWAP_COPY :: coreWin.PFD_SWAP_COPY
PFD_SWAP_LAYER_BUFFERS :: coreWin.PFD_SWAP_LAYER_BUFFERS
PFD_GENERIC_ACCELERATED :: coreWin.PFD_GENERIC_ACCELERATED
PFD_SUPPORT_DIRECTDRAW :: coreWin.PFD_SUPPORT_DIRECTDRAW
PFD_DIRECT3D_ACCELERATED :: coreWin.PFD_DIRECT3D_ACCELERATED
PFD_SUPPORT_COMPOSITION :: coreWin.PFD_SUPPORT_COMPOSITION

// PIXELFORMATDESCRIPTOR flags for use in ChoosePixelFormat only
PFD_DEPTH_DONTCARE :: coreWin.PFD_DEPTH_DONTCARE
PFD_DOUBLEBUFFER_DONTCARE :: coreWin.PFD_DOUBLEBUFFER_DONTCARE
PFD_STEREO_DONTCARE :: coreWin.PFD_STEREO_DONTCARE
