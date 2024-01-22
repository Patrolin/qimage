package lib_windows
import coreWin "core:sys/windows"

// https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/hid-architecture#hid-clients-supported-in-windows
// raw input usage page + usage
RIUP_MOUSE_CONTROLLER_KEYBOARD :: 0x1
RIU_MOUSE_MAPPER_DRIVER :: 0x1
RIU_MOUSE :: 0x2
RIU_CONTROLLER :: 0x4
RIU_KEYBOARD :: 0x6

// raw input device
RIDEV_REMOVE :: coreWin.RIDEV_REMOVE
RIDEV_EXCLUDE :: coreWin.RIDEV_EXCLUDE
RIDEV_PAGEONLY :: coreWin.RIDEV_PAGEONLY
RIDEV_NOLEGACY :: coreWin.RIDEV_NOLEGACY
RIDEV_INPUTSINK :: coreWin.RIDEV_INPUTSINK
RIDEV_CAPTUREMOUSE :: coreWin.RIDEV_CAPTUREMOUSE
RIDEV_NOHOTKEYS :: coreWin.RIDEV_NOHOTKEYS
RIDEV_APPKEYS :: coreWin.RIDEV_APPKEYS
RIDEV_EXINPUTSINK :: coreWin.RIDEV_EXINPUTSINK
RIDEV_DEVNOTIFY :: coreWin.RIDEV_DEVNOTIFY

// raw input command
RID_INPUT :: coreWin.RID_INPUT
RID_HEADER :: coreWin.RID_HEADER

// raw input message
RIM_INPUT :: 0 // foreground
RIM_INPUTSINK :: 1 // background
RIM_TYPEMOUSE :: coreWin.RIM_TYPEMOUSE
RIM_TYPEKEYBOARD :: coreWin.RIM_TYPEKEYBOARD
RIM_TYPEHID :: coreWin.RIM_TYPEHID

// raw input mouse
MOUSE_MOVE_ABSOLUTE :: coreWin.MOUSE_MOVE_ABSOLUTE
MOUSE_MOVE_RELATIVE :: coreWin.MOUSE_MOVE_RELATIVE
MOUSE_VIRTUAL_DESKTOP :: coreWin.MOUSE_VIRTUAL_DESKTOP
RI_MOUSE_LEFT_BUTTON_UP :: coreWin.RI_MOUSE_LEFT_BUTTON_UP
RI_MOUSE_RIGHT_BUTTON_UP :: coreWin.RI_MOUSE_RIGHT_BUTTON_UP
RI_MOUSE_MIDDLE_BUTTON_UP :: coreWin.RI_MOUSE_MIDDLE_BUTTON_UP
