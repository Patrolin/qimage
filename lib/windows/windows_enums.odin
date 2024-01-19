package lib_windows
import coreWin "core:sys/windows"

// bool
TRUE :: coreWin.TRUE
FALSE :: coreWin.FALSE

// calling convention
CALLBACK :: "stdcall"
WINAPI :: "stdcall"

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

// peek message
PM_NOREMOVE :: coreWin.PM_NOREMOVE
PM_REMOVE :: coreWin.PM_REMOVE
PM_NOYIELD :: coreWin.PM_NOYIELD
