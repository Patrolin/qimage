package main
import "../lib/math"

updateAndRender :: proc() {
	stride := int(imageBuffer.width)
	pitch := 1
	for Y := 0; Y < int(imageBuffer.height); Y += 1 {
		for X := 0; X < int(imageBuffer.width); X += 1 {
			rgba := math.v4{128, 128, 255, 0}
			imageBuffer.data[Y * stride + X * pitch] = math.pack_rgba(rgba)
		}
	}
}
