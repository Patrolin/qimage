package lib_input
import "../math"

Inputs :: struct {
	mouse:    Mouse,
	keyboard: Keyboard,
}
Mouse :: struct {
	pos:      [dynamic]math.v2i,
	clickPos: math.v2i,
	LMB:      Button,
	RMB:      Button,
}
initMouse :: proc(inputs: ^Inputs) {
	inputs.mouse.pos = make([dynamic]math.v2i, 0, 4)
	append(&inputs.mouse.pos, math.v2i{max(i16), max(i16)})
}
addMousePath :: proc(inputs: ^Inputs, moveTo: math.v2i) {
	MAX_MOUSE_PATH :: 4
	if (len(inputs.mouse.pos) < MAX_MOUSE_PATH) { 	// NOTE: we may get an infinite number of mouse events when sizing on windows
		append(&inputs.mouse.pos, moveTo)
	} else {
		inputs.mouse.pos[MAX_MOUSE_PATH - 1] = moveTo
	}
}
lastMousePos :: proc(inputs: ^Inputs) -> math.v2i {
	return inputs.mouse.pos[len(inputs.mouse.pos) - 1]
}
resetInputs :: proc(inputs: ^Inputs) {
	// mouse
	last_mouse_pos := lastMousePos(inputs)
	clear(&inputs.mouse.pos)
	addMousePath(inputs, last_mouse_pos)
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
