package lib_input
import "../alloc"
import "../math"

Inputs :: struct {
	mouse:    Mouse,
	keyboard: Keyboard,
}
MAX_MOUSE_PATH_SIZE :: 4
Mouse :: struct {
	pos:      alloc.FixedBuffer(math.v2i, MAX_MOUSE_PATH_SIZE),
	clickPos: math.v2i,
	LMB:      Button,
	RMB:      Button,
}
addMousePath :: proc(inputs: ^Inputs, moveTo: math.v2i) {
	alloc.fixedBufferAppendOrReplace(&inputs.mouse.pos, moveTo)
}
lastMousePos :: proc(inputs: ^Inputs) -> math.v2i {
	return inputs.mouse.pos.slice[len(inputs.mouse.pos.slice) - 1]
}
resetInputs :: proc(inputs: ^Inputs) {
	// mouse
	inputs.mouse.pos.slice = inputs.mouse.pos.buffer[MAX_MOUSE_PATH_SIZE - 1:]
	resetTransitions(&inputs.mouse.LMB)
	resetTransitions(&inputs.mouse.RMB)
	// keyboard
	resetTransitions(&inputs.keyboard.Ctrl)
	resetTransitions(&inputs.keyboard.Shift)
	resetTransitions(&inputs.keyboard.Alt)
	resetTransitions(&inputs.keyboard.W)
	resetTransitions(&inputs.keyboard.A)
	resetTransitions(&inputs.keyboard.S)
	resetTransitions(&inputs.keyboard.D)
}

Button :: distinct u8 // transitions: u7, wasDown: u1
Keyboard :: struct {
	Ctrl:  Button,
	Alt:   Button,
	Shift: Button,
	W:     Button,
	A:     Button,
	S:     Button,
	D:     Button,
}
addTransitions :: proc(button: ^Button, transitions: u8) {
	button^ = Button(u8(button^) + (transitions << 1))
}
wasDown :: proc(button: Button) -> bool {
	return bool(button & 1)
}
wentUp :: proc(button: Button) -> bool {
	return wasDown(button) && bool(getTransitions(button))
}
wentDown :: proc(button: Button) -> bool {
	return !wasDown(button) && bool(getTransitions(button))
}
getTransitions :: proc(button: Button) -> u8 {
	return u8(button) >> 1
}
resetTransitions :: proc(button: ^Button) {
	transitions := getTransitions(button^)
	is_down := (u8(button^) & 1) ~ (transitions & 1)
	button^ = Button(is_down)
}
