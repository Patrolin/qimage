package lib_events
import "../math"

@(private)
InitEventsProps :: struct {
	onPaint: proc(window: Window),
}
initEvents :: proc(props: InitEventsProps) {
	if props.onPaint != nil {onPaint = props.onPaint}
	initWindow()
}

@(private)
os_events_info: struct {
	current_window: ^Window,
	raw_mouse_pos:  math.i32x2,
	resized_window: bool,
	moved_window:   bool,
}
@(private)
resetOsEventsInfo :: proc() {
	os_events_info.resized_window = false
	os_events_info.moved_window = false
}
os_events: [dynamic]OsEvent

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
	pos: math.f32x2,
	LMB: ButtonState,
	RMB: ButtonState,
}
KeyboardEvent :: struct {
	key_code, scan_code: u32,
	text:                string,
	repeat_count:        u32,
	is_dead_char:        b32,
}
WindowResizeEvent :: struct {}
WindowCloseEvent :: struct {}
