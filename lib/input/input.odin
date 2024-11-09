package input_lib

initInputs :: proc() {
	shrink(&mouse.pos, MAX_MOUSE_PATH)
	clear(&mouse.pos)
	append(&mouse.pos, DEFAULT_MOUSE_POS)
}

Button :: distinct u8
@(private)
getTransitions :: #force_inline proc "contextless" (button: Button) -> u8 {
	return u8(button) >> 1
}
wasDown :: #force_inline proc "contextless" (button: Button) -> b8 {
	return b8(button & 1)
}
wentUpCount :: proc(button: Button) -> u8 {
	was_down := wasDown(button)
	transitions := getTransitions(button)
	went_up_count := transitions >> 1
	if was_down && (transitions & 1) != 0 {went_up_count += 1}
	return went_up_count
}
wentDownCount :: proc(button: Button) -> u8 {
	was_down := wasDown(button)
	transitions := getTransitions(button)
	went_down_count := transitions >> 1
	if !was_down && (transitions & 1) != 0 {went_down_count += 1}
	return went_down_count
}
addTransitions :: proc(button: ^Button, transitions: u8) {
	button^ = Button(u8(button^) + (transitions << 1))
}
setButton :: proc(button: ^Button, went_up: b8) {
	set_was_down := u8(button^ &~ 1) | u8(went_up)
	button^ = Button(set_was_down + 0x2)
}
@(private)
applyTransitions :: proc(button: ^Button) {
	is_down := u8(wasDown(button^)) ~ (getTransitions(button^) & 1)
	button^ = Button(is_down)
}
applyInputs :: proc() {
	applyMouseInputs()
	applyKeyboardInputs()
}
