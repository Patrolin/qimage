package lib_input
import "../alloc"
import "../math"

MAX_MOUSE_PATH_SIZE :: 4
Mouse :: struct {
	pos:      alloc.FixedBuffer(math.v2i, MAX_MOUSE_PATH_SIZE),
	clickPos: math.v2i,
	LMB:      Button,
	RMB:      Button,
}
reset_mouse :: proc(inputs: ^Inputs) {
	inputs.mouse.pos.slice = inputs.mouse.pos.buffer[MAX_MOUSE_PATH_SIZE - 1:]
	reset_transitions(&inputs.mouse.LMB)
	reset_transitions(&inputs.mouse.RMB)
}
add_mouse_path :: proc(inputs: ^Inputs, moveTo: math.v2i) {
	alloc.fixedBufferAppendOrReplace(&inputs.mouse.pos, moveTo)
}
