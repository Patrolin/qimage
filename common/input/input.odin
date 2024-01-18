package input
import "../../lib/math"

Input :: struct {
    mouse: Mouse,
    keyboard: Keyboard,
}
Mouse :: struct {
    clickPos: math.vec2i,
    path: []math.vec2i,
    path_buffer: [4]math.vec2i,
    LMB: b8,
    LMB_count: u8,
    RMB: b8,
    RMB_count: u8,
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
