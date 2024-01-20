package lib_input
import "../math"

Input :: struct {
	mouse:    Mouse,
	keyboard: Keyboard,
}

MOUSE_PATH_SIZE :: 4
MousePathBuffer :: struct #raw_union {
	path_buffer: [MOUSE_PATH_SIZE]math.v2i,
	using _:     struct {
		_:   [MOUSE_PATH_SIZE - 1]math.v2i,
		pos: math.v2i,
	},
}
Mouse :: struct {
	using _:   MousePathBuffer,
	path:      []math.v2i,
	clickPos:  math.v2i,
	LMB:       b8,
	LMB_count: u8,
	RMB:       b8,
	RMB_count: u8,
}
add_mouse_path :: proc(input: ^Input, moveTo: math.v2i) {
	new_path_size := len(input.mouse.path) + 1
	assert(new_path_size <= MOUSE_PATH_SIZE)
	curr := moveTo
	for i := MOUSE_PATH_SIZE - 1; i > 0; i -= 1 {
		curr, input.mouse.path_buffer[i] = input.mouse.path_buffer[i], curr
	}
	input.mouse.path = input.mouse.path_buffer[MOUSE_PATH_SIZE - new_path_size:]
}
reset_mouse_path :: proc(input: ^Input) {
	input.mouse.path = input.mouse.path_buffer[MOUSE_PATH_SIZE - 1:]
}

Keyboard :: struct {
	Ctrl:    b8,
	Alt:     b8,
	Shift:   b8,
	W:       b8,
	W_count: u8,
	A:       b8,
	A_count: u8,
	S:       b8,
	S_count: u8,
	D:       b8,
	D_count: u8,
}
