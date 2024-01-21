package main
import win "core:sys/windows"
Image :: struct {
	width, height: u16,
}
foo :: proc(image: Image) {
	imageInfo := win.BITMAPINFO {
		bmiHeader =  {
			biSize = size_of(win.BITMAPINFOHEADER),
			biPlanes = 1,
			biBitCount = u16(32),
			biCompression = win.BI_RGB,
			biWidth = i32(image.width),
			// biHeight = -i32(image.height), // NOTE: top-down DIB
			biHeight = i32(image.height), // NOTE: bottom-up DIB
		},
	}
}
