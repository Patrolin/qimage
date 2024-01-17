package main

updateAndRender :: proc() {
	stride := int(imageBuffer.width)
	pitch := 1
	for Y := 0; Y < int(imageBuffer.height); Y += 1 {
		for X := 0; X < int(imageBuffer.width); X += 1 {
			red: u32 = 128
			green: u32 = 128
			blue: u32 = 255
			// NOTE: register: xxRRGGBB, memory: BBGGRRxx
			BGRX := blue | (green << 8) | (red << 16)
			imageBuffer.data[Y * stride + X * pitch] = BGRX
		}
	}
}
