package lib_windows
import win "core:sys/windows"

// TODO: move this stuff into lib_input
// https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/hid-architecture#hid-clients-supported-in-windows
// raw input usage page + usage
RIUP_MOUSE_CONTROLLER_KEYBOARD :: 0x1
RIU_MOUSE_MAPPER_DRIVER :: 0x1
RIU_MOUSE :: 0x2
RIU_CONTROLLER :: 0x4
RIU_KEYBOARD :: 0x6

// raw input device
RIDEV_REMOVE :: win.RIDEV_REMOVE
RIDEV_EXCLUDE :: win.RIDEV_EXCLUDE
RIDEV_PAGEONLY :: win.RIDEV_PAGEONLY
RIDEV_NOLEGACY :: win.RIDEV_NOLEGACY
RIDEV_INPUTSINK :: win.RIDEV_INPUTSINK
RIDEV_CAPTUREMOUSE :: win.RIDEV_CAPTUREMOUSE
RIDEV_NOHOTKEYS :: win.RIDEV_NOHOTKEYS
RIDEV_APPKEYS :: win.RIDEV_APPKEYS
RIDEV_EXINPUTSINK :: win.RIDEV_EXINPUTSINK
RIDEV_DEVNOTIFY :: win.RIDEV_DEVNOTIFY

// raw input command
RID_INPUT :: win.RID_INPUT
RID_HEADER :: win.RID_HEADER

// raw input message
RIM_INPUT :: 0 // foreground
RIM_INPUTSINK :: 1 // background
RIM_TYPEMOUSE :: win.RIM_TYPEMOUSE
RIM_TYPEKEYBOARD :: win.RIM_TYPEKEYBOARD
RIM_TYPEHID :: win.RIM_TYPEHID

// raw input mouse
MOUSE_MOVE_ABSOLUTE :: win.MOUSE_MOVE_ABSOLUTE
MOUSE_MOVE_RELATIVE :: win.MOUSE_MOVE_RELATIVE
MOUSE_VIRTUAL_DESKTOP :: win.MOUSE_VIRTUAL_DESKTOP
RI_MOUSE_LEFT_BUTTON_UP :: win.RI_MOUSE_LEFT_BUTTON_UP
RI_MOUSE_RIGHT_BUTTON_UP :: win.RI_MOUSE_RIGHT_BUTTON_UP
RI_MOUSE_MIDDLE_BUTTON_UP :: win.RI_MOUSE_MIDDLE_BUTTON_UP
