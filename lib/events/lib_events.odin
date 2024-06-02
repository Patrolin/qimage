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
	RawMouseEvent,
	MouseMoveEvent,
	KeyboardEvent,
	WindowResizeEvent,
	WindowCloseEvent,
}
ButtonState :: enum {
	Unchanged,
	Down,
	Up,
}
RawMouseEvent :: struct {
	dpos: math.i32x2, // NOTE: there is not reliable way to get pos from dpos in windows
	LMB:  ButtonState,
	RMB:  ButtonState,
}
MouseMoveEvent :: struct {
	client_pos: math.i32x2,
}
KeyboardEvent :: struct {
	text:                string,
	key_code, scan_code: u32,
	repeat_count:        u32,
	is_dead_char:        b32,
}
WindowResizeEvent :: struct {}
WindowCloseEvent :: struct {}
