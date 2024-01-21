package lib_input
import "../math"

Mouse :: struct {
	using _:  MousePathBuffer,
	path:     []math.v2i,
	clickPos: math.v2i,
	LMB:      Button,
	RMB:      Button,
}
reset_mouse :: proc(inputs: ^Inputs) {
	inputs.mouse.path = inputs.mouse.path_buffer[MOUSE_PATH_SIZE - 1:]
	reset_transitions(&inputs.mouse.LMB)
	reset_transitions(&inputs.mouse.RMB)
}
MOUSE_PATH_SIZE :: 4
MousePathBuffer :: struct #raw_union {
	path_buffer: [MOUSE_PATH_SIZE]math.v2i,
	using _:     struct {
		_:   [MOUSE_PATH_SIZE - 1]math.v2i,
		pos: math.v2i,
	},
}
add_mouse_path :: proc(inputs: ^Inputs, moveTo: math.v2i) {
	new_path_size := len(inputs.mouse.path) + 1
	assert(new_path_size <= MOUSE_PATH_SIZE)
	curr := moveTo
	for i := MOUSE_PATH_SIZE - 1; i > 0; i -= 1 {
		curr, inputs.mouse.path_buffer[i] = inputs.mouse.path_buffer[i], curr
	}
	inputs.mouse.path = inputs.mouse.path_buffer[MOUSE_PATH_SIZE - new_path_size:]
}
