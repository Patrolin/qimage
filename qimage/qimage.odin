package main
import "../lib/file"
import "../lib/math"
import "../lib/paint"
import "core:fmt"

updateAndRender :: proc() {
	// NOTE: this takes 7+ ms
	for y := 0; y < int(frame_buffer.height); y += 1 {
		for x := 0; x < int(frame_buffer.width); x += 1 {
			rgba := math.v4{128, 128, 255, 0}
			paint.packRGBA(frame_buffer, x, y, rgba)
		}
	}
}
