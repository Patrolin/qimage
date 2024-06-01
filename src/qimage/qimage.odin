package main
import "../../lib/file"
import "../../lib/input"
import "../../lib/math"
import "../../lib/paint"
import "core:fmt"

updateAndRender :: proc() {
	// TODO: use opengl instead
	// clear to blue // NOTE: this takes .7+ ms
	for y in 0 ..< int(frame_buffer.height) {
		for x in 0 ..< int(frame_buffer.width) {
			rgba := math.f32x4{128, 128, 255, 0}
			paint.packRGBA(frame_buffer, x, y, rgba)
		}
	}
	// show an image at the cursor // TODO!: how do we offset to window top left?
	pitch := 3
	stride := pitch * int(image.width)
	last_mouse_pos := input.lastMousePos()
	if last_mouse_pos.x >= 0 && last_mouse_pos.y >= 0 {
		y_end := min(int(image.height), int(frame_buffer.height) - int(last_mouse_pos.y))
		x_end := min(int(image.width), int(frame_buffer.width) - int(last_mouse_pos.x))
		for y in 0 ..< y_end {
			for x in 0 ..< x_end {
				R := image.data[y * stride + x * pitch]
				G := image.data[y * stride + x * pitch + 1]
				B := image.data[y * stride + x * pitch + 2]
				paint.packRGBA(
					frame_buffer,
					int(last_mouse_pos.x) + x,
					int(last_mouse_pos.y) + y,
					math.i32x4{i32(R), i32(G), i32(B), 0xff},
				)
			}
		}
	}
}
