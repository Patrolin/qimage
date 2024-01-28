package main
import "../lib/file"
import "../lib/math"
import "../lib/paint"
import "../lib/input"
import "core:fmt"

updateAndRender :: proc() {
	// clear to blue NOTE: this takes .7+ ms
	for y := 0; y < int(frame_buffer.height); y += 1 {
		for x := 0; x < int(frame_buffer.width); x += 1 {
			rgba := math.v4{128, 128, 255, 0}
			paint.packRGBA(frame_buffer, x, y, rgba)
		}
	}
	// show an image at the cursor // TODO!: how do we offset to window top left?
	pitch := 3
	stride := pitch * int(image.width)
	last_mouse_pos := input.lastMousePos(&inputs)
	fmt.println("last_mouse_pos", last_mouse_pos)
	if last_mouse_pos.x >= 0 && last_mouse_pos.y >= 0 {
		for y := 0; y < int(image.height) && (int(last_mouse_pos.y)+y) < int(frame_buffer.height); y += 1 {
			for x := 0; x < int(image.width) && (int(last_mouse_pos.x)+x) < int(frame_buffer.width); x += 1 {
				R := image.data[y * stride + x * pitch]
				G := image.data[y * stride + x * pitch + 1]
				B := image.data[y * stride + x * pitch + 2]
				paint.packRGBA(frame_buffer, int(last_mouse_pos.x) + x, int(last_mouse_pos.y) + y, math.v4i{
					i16(R), i16(G), i16(B), 0xff
				})
			}
		}
	}
}
