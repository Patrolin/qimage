package lib_input
import "../math"

mouse: struct {
	pos:      [dynamic]math.i32x2,
	clickPos: math.i32x2,
	LMB:      Button,
	RMB:      Button,
}
firstMousePos :: #force_inline proc "contextless" () -> math.i32x2 {
	return mouse.pos[0]
}
lastMousePos :: #force_inline proc "contextless" () -> math.i32x2 {
	return mouse.pos[len(mouse.pos) - 1]
}
addMousePath :: proc(moveTo: math.i32x2) {
	if (len(mouse.pos) < MAX_MOUSE_PATH) {
		append(&mouse.pos, moveTo)
	} else {
		mouse.pos[MAX_MOUSE_PATH - 1] = moveTo
	}
}
@(private)
MAX_MOUSE_PATH :: 4 // NOTE: we may get an infinite number of mouse events when sizing on windows
@(private)
DEFAULT_MOUSE_POS :: math.i32x2{0, 0}
@(private)
initMouse :: proc() {
	shrink(&mouse.pos, MAX_MOUSE_PATH)
	clear(&mouse.pos)
	append(&mouse.pos, DEFAULT_MOUSE_POS)
}
@(private)
applyMouseInputs :: proc() {
	last_mouse_pos := lastMousePos()
	clear(&mouse.pos)
	append(&mouse.pos, last_mouse_pos)
	applyTransitions(&mouse.LMB)
	applyTransitions(&mouse.RMB)
}
