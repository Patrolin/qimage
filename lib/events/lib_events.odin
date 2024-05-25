package lib_events

os_events: [dynamic]OsEvent

OsEvent :: union {
	MouseDownEvent,
	MouseUpEvent,
	MouseMoveEvent,
	KeyboardDownEvent,
	KeyboardUpEvent,
	WindowResizeEvent,
	WindowCloseEvent,
}
MouseDownEvent :: struct {
	pos: [2]int,
}
MouseUpEvent :: struct {
	pos: [2]int,
}
MouseMoveEvent :: struct {
	pos: [2]int,
}
KeyboardDownEvent :: struct {
	using _:      KeyboardUpEvent,
	repeat_count: int,
}
KeyboardUpEvent :: struct {
	char_code, scan_code: u32,
	char:                 rune,
}
WindowResizeEvent :: struct {
	rect: [4]int,
}
WindowCloseEvent :: struct {}
