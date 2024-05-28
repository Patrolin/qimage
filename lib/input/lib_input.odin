package lib_input
import "../math"

// TODO: just make these globals
Inputs :: struct {
	mouse:    Mouse,
	keyboard: Keyboard,
}
Mouse :: struct {
	pos:      [dynamic]math.i32x2,
	clickPos: math.i32x2,
	LMB:      Button,
	RMB:      Button,
}
MAX_MOUSE_PATH :: 4 // NOTE: we may get an infinite number of mouse events when sizing on windows
initMouse :: proc(inputs: ^Inputs) {
	shrink(&inputs.mouse.pos, MAX_MOUSE_PATH)
	clear(&inputs.mouse.pos)
	append(&inputs.mouse.pos, math.i32x2{max(i32), max(i32)})
}
addMousePath :: proc(inputs: ^Inputs, moveTo: math.i32x2) {
	if (len(inputs.mouse.pos) < MAX_MOUSE_PATH) {
		append(&inputs.mouse.pos, moveTo)
	} else {
		inputs.mouse.pos[MAX_MOUSE_PATH - 1] = moveTo
	}
}
lastMousePos :: proc(inputs: ^Inputs) -> math.i32x2 {
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
