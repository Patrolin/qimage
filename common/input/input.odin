package input
import "../../lib/math"

Input :: struct {
    mouse: Mouse,
    keyboard: Keyboard,
}
Mouse :: struct {
    pos: math.vec2i,
    path_count: int,
    path: [8]math.vec2i,
}
Keyboard :: struct {
    Ctrl: b8,
    Alt: b8,
    Shift: b8,
    W: b8,
    W_count: u8,
    A: b8,
    A_count: u8,
    S: b8,
    S_count: u8,
    D: b8,
    D_count: u8,
}
// NOTE: are global variables always cache aligned?
g := Input{}
