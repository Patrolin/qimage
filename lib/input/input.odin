package lib_input
import "../math"

Inputs :: struct {
	mouse:    Mouse,
	keyboard: Keyboard,
}
lastMousePos :: proc(inputs: ^Inputs) -> math.v2i {
	return inputs.mouse.pos.slice[len(inputs.mouse.pos.slice) - 1]
}
reset_inputs :: proc(inputs: ^Inputs) {
	reset_mouse(inputs)
	reset_transitions(&inputs.keyboard.Ctrl)
	reset_transitions(&inputs.keyboard.Shift)
	reset_transitions(&inputs.keyboard.Alt)
	reset_transitions(&inputs.keyboard.W)
	reset_transitions(&inputs.keyboard.A)
	reset_transitions(&inputs.keyboard.S)
	reset_transitions(&inputs.keyboard.D)
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
add_transitions :: proc(button: ^Button, transitions: u8) {
	button^ = Button(u8(button^) + (transitions << 1))
}
was_down :: proc(button: Button) -> bool {
	return bool(button & 1)
}
went_up :: proc(button: Button) -> bool {
	return was_down(button) && bool(get_transitions(button))
}
went_down :: proc(button: Button) -> bool {
	return !was_down(button) && bool(get_transitions(button))
}
get_transitions :: proc(button: Button) -> u8 {
	return u8(button) >> 1
}
reset_transitions :: proc(button: ^Button) {
	transitions := get_transitions(button^)
	is_down := (u8(button^) & 1) ~ (transitions & 1)
	button^ = Button(is_down)
}
