package lib_events
import "../math"

@(private)
os_events_info: struct {
	current_window:   ^Window,
	got_resize_event: bool,
}
os_events: [dynamic]OsEvent // NOTE: windows is stupid and breaks if you don't get all events at once

OsEvent :: union {
	MouseEvent,
	KeyboardEvent,
	WindowResizeEvent,
	WindowCloseEvent,
}
ButtonState :: enum {
	Unchanged,
	Down,
	Up,
}
MouseEvent :: struct {
	pos: math.i32x2,
	LMB: ButtonState,
}
KeyboardEvent :: struct {
	key_code, scan_code: u32,
	text:                string,
	repeat_count:        u32,
	is_dead_char:        b32,
}
WindowResizeEvent :: struct {}
WindowCloseEvent :: struct {}
