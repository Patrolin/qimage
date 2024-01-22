package lib_windows
import coreWin "core:sys/windows"

// TODO?: generate from https://wiki.winehq.org/List_Of_Windows_Messages
// window message
WM_NULL :: coreWin.WM_NULL
WM_CREATE :: coreWin.WM_CREATE
WM_DESTROY :: coreWin.WM_DESTROY
WM_MOVE :: coreWin.WM_MOVE
WM_SIZE :: coreWin.WM_SIZE
WM_ACTIVATE :: coreWin.WM_ACTIVATE
WM_SETFOCUS :: coreWin.WM_SETFOCUS
WM_KILLFOCUS :: coreWin.WM_KILLFOCUS
//RESERVED :: 9
WM_ENABLE :: coreWin.WM_ENABLE
WM_SETREDRAW :: coreWin.WM_SETREDRAW
WM_SETTEXT :: coreWin.WM_SETTEXT
WM_GETTEXT :: coreWin.WM_GETTEXT
WM_GETTEXTLENGTH :: coreWin.WM_GETTEXTLENGTH
WM_PAINT :: coreWin.WM_PAINT
WM_CLOSE :: coreWin.WM_CLOSE
WM_QUERYENDSESSION :: coreWin.WM_QUERYENDSESSION
WM_QUIT :: coreWin.WM_QUIT
WM_QUERYOPEN :: coreWin.WM_QUERYOPEN
WM_ERASEBKGND :: coreWin.WM_ERASEBKGND
WM_SYSCOLORCHANGE :: coreWin.WM_SYSCOLORCHANGE
WM_ENDSESSION :: coreWin.WM_ENDSESSION
WM_SHOWWINDOW :: coreWin.WM_SHOWWINDOW
WM_CTLCOLOR :: coreWin.WM_CTLCOLOR
WM_WININICHANGE :: coreWin.WM_WININICHANGE
WM_DEVMODECHANGE :: coreWin.WM_DEVMODECHANGE
WM_ACTIVATEAPP :: coreWin.WM_ACTIVATEAPP
WM_FONTCHANGE :: coreWin.WM_FONTCHANGE
WM_TIMECHANGE :: coreWin.WM_TIMECHANGE
WM_CANCELMODE :: coreWin.WM_CANCELMODE
WM_SETCURSOR :: coreWin.WM_SETCURSOR
WM_MOUSEACTIVATE :: coreWin.WM_MOUSEACTIVATE
WM_CHILDACTIVATE :: coreWin.WM_CHILDACTIVATE
WM_QUEUESYNC :: coreWin.WM_QUEUESYNC
WM_GETMINMAXINFO :: coreWin.WM_GETMINMAXINFO
WM_PAINTICON :: coreWin.WM_PAINTICON
WM_ICONERASEBKGND :: coreWin.WM_ICONERASEBKGND
WM_NEXTDLGCTL :: coreWin.WM_NEXTDLGCTL
//RESERVED :: 41
WM_SPOOLERSTATUS :: coreWin.WM_SPOOLERSTATUS
WM_DRAWITEM :: coreWin.WM_DRAWITEM
WM_MEASUREITEM :: coreWin.WM_MEASUREITEM
WM_DELETEITEM :: coreWin.WM_DELETEITEM
WM_VKEYTOITEM :: coreWin.WM_VKEYTOITEM
WM_CHARTOITEM :: coreWin.WM_CHARTOITEM
WM_SETFONT :: coreWin.WM_SETFONT
WM_GETFONT :: coreWin.WM_GETFONT
WM_SETHOTKEY :: coreWin.WM_SETHOTKEY
WM_GETHOTKEY :: coreWin.WM_GETHOTKEY
//RESERVED :: 52-54
WM_QUERYDRAGICON :: coreWin.WM_QUERYDRAGICON
//RESERVED :: 56
WM_COMPAREITEM :: coreWin.WM_COMPAREITEM
//RESERVED :: 58-60
WM_GETOBJECT :: coreWin.WM_GETOBJECT
//RESERVED :: 62-64
WM_COMPACTING :: coreWin.WM_COMPACTING
WM_COMMNOTIFY :: coreWin.WM_COMMNOTIFY
WM_WINDOWPOSCHANGING :: coreWin.WM_WINDOWPOSCHANGING
WM_WINDOWPOSCHANGED :: coreWin.WM_WINDOWPOSCHANGED
WM_POWER :: coreWin.WM_POWER
WM_COPYGLOBALDATA :: coreWin.WM_COPYGLOBALDATA
WM_COPYDATA :: coreWin.WM_COPYDATA
WM_CANCELJOURNAL :: coreWin.WM_CANCELJOURNAL
WM_NOTIFY :: coreWin.WM_NOTIFY
WM_INPUTLANGCHANGEREQUEST :: coreWin.WM_INPUTLANGCHANGEREQUEST
WM_INPUTLANGCHANGE :: coreWin.WM_INPUTLANGCHANGE
WM_TCARD :: coreWin.WM_TCARD
WM_HELP :: coreWin.WM_HELP
WM_USERCHANGED :: coreWin.WM_USERCHANGED
WM_NOTIFYFORMAT :: coreWin.WM_NOTIFYFORMAT
WM_CONTEXTMENU :: coreWin.WM_CONTEXTMENU
WM_STYLECHANGING :: coreWin.WM_STYLECHANGING
WM_STYLECHANGED :: coreWin.WM_STYLECHANGED
WM_DISPLAYCHANGE :: coreWin.WM_DISPLAYCHANGE
WM_GETICON :: coreWin.WM_GETICON
WM_SETICON :: coreWin.WM_SETICON
WM_NCCREATE :: coreWin.WM_NCCREATE
WM_NCDESTROY :: coreWin.WM_NCDESTROY
WM_NCCALCSIZE :: coreWin.WM_NCCALCSIZE
WM_NCHITTEST :: coreWin.WM_NCHITTEST
WM_NCPAINT :: coreWin.WM_NCPAINT
WM_NCACTIVATE :: coreWin.WM_NCACTIVATE
WM_GETDLGCODE :: coreWin.WM_GETDLGCODE
WM_SYNCPAINT :: coreWin.WM_SYNCPAINT
//RESERVED :: // 137-159
WM_NCMOUSEMOVE :: coreWin.WM_NCMOUSEMOVE
WM_NCLBUTTONDOWN :: coreWin.WM_NCLBUTTONDOWN
WM_NCLBUTTONUP :: coreWin.WM_NCLBUTTONUP
WM_NCLBUTTONDBLCLK :: coreWin.WM_NCLBUTTONDBLCLK
WM_NCRBUTTONDOWN :: coreWin.WM_NCRBUTTONDOWN
WM_NCRBUTTONUP :: coreWin.WM_NCRBUTTONUP
WM_NCRBUTTONDBLCLK :: coreWin.WM_NCRBUTTONDBLCLK
WM_NCMBUTTONDOWN :: coreWin.WM_NCMBUTTONDOWN
WM_NCMBUTTONUP :: coreWin.WM_NCMBUTTONUP
WM_NCMBUTTONDBLCLK :: coreWin.WM_NCMBUTTONDBLCLK
WM_NCXBUTTONDOWN :: coreWin.WM_NCXBUTTONDOWN
WM_NCXBUTTONUP :: coreWin.WM_NCXBUTTONUP
WM_NCXBUTTONDBLCLK :: coreWin.WM_NCXBUTTONDBLCLK
WM_INPUT :: coreWin.WM_INPUT
WM_KEYDOWN :: coreWin.WM_KEYDOWN
WM_KEYFIRST :: coreWin.WM_KEYFIRST
WM_KEYUP :: coreWin.WM_KEYUP
WM_CHAR :: coreWin.WM_CHAR
WM_DEADCHAR :: coreWin.WM_DEADCHAR
WM_SYSKEYDOWN :: coreWin.WM_SYSKEYDOWN
WM_SYSKEYUP :: coreWin.WM_SYSKEYUP
WM_SYSCHAR :: coreWin.WM_SYSCHAR
WM_SYSDEADCHAR :: coreWin.WM_SYSDEADCHAR
WM_UNICHAR :: coreWin.WM_UNICHAR
// ... :: 266-531
WM_SIZING :: 532
WM_MOUSEMOVE :: coreWin.WM_MOUSEMOVE
WM_LBUTTONDOWN :: coreWin.WM_LBUTTONDOWN
WM_LBUTTONUP :: coreWin.WM_LBUTTONUP
WM_LBUTTONDBLCLK :: coreWin.WM_LBUTTONDBLCLK
WM_RBUTTONDOWN :: coreWin.WM_RBUTTONDOWN
WM_RBUTTONUP :: coreWin.WM_RBUTTONUP
WM_RBUTTONDBLCLK :: coreWin.WM_RBUTTONDBLCLK
