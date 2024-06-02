package lib_input

keyboard: struct {
	Ctrl:  Button,
	Alt:   Button,
	Shift: Button,
	W:     Button,
	A:     Button,
	S:     Button,
	D:     Button,
}
@(private)
applyKeyboardInputs :: proc() {
	applyTransitions(&keyboard.Ctrl)
	applyTransitions(&keyboard.Shift)
	applyTransitions(&keyboard.Alt)
	applyTransitions(&keyboard.W)
	applyTransitions(&keyboard.A)
	applyTransitions(&keyboard.S)
	applyTransitions(&keyboard.D)
}
