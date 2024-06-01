// odin run src/qimage -subsystem:windows
package main
import "../../lib/ast"
import "../../lib/events"
import "../../lib/file"
import "../../lib/gl"
import "../../lib/input"
import "../../lib/math"
import "../../lib/os"
import "../../lib/paint"
import "../assets"
import "core:fmt"
import "core:runtime"
import win "core:sys/windows"

isRunning := false
frame_buffer := paint.FrameBuffer{} // NOTE: copying the frameBuffer is slow (.7+ ms), so we instead we store it in an OS specific format
image: file.Image

main :: proc() {
	context = os.init()
	events.initEvents({onPaint})
	input.initInputs()
	window := events.openWindow("qimage", {-1, -1, 1200, 800})
	image = assets.loadImage("test_image.bmp")
	/*
	file.printImage(image, 0, 0, 3, 3)
	x := "bÄ + 2"
	for codepoint, index in x {
		fmt.println(index, codepoint)
		// 0 A
		// 1 B
		// 2 C
	}
	tokens := ast.tokenize(x, "+-0123456789", "\"'", "\\", "abcdefxyz", " \n\r\t")
	fmt.println(tokens)
	assert(false, "ayaya")
	*/
	paint.resizeFrameBuffer(
		&frame_buffer,
		i16(window.client_rect.width),
		i16(window.client_rect.height),
	)
	// TODO: Timer?
	timing: struct {
		t, prev_t, max_ddt: f64,
		frame:              int,
	}
	timing.t = os.time()
	timing.prev_t = timing.t
	for isRunning = true; isRunning; {
		dt := timing.t - timing.prev_t
		timing.frame += 1
		if (timing.frame > 30) {
			timing.max_ddt = max(timing.max_ddt, abs(math.millis(dt) - 16.6666666666666666666))
		}
		events.getAllEvents()
		for os_event in events.os_events {
			switch event in os_event {
			case events.MouseEvent:
				fmt.printfln("event: %v", event)
			case events.KeyboardEvent:
				fmt.printfln("event: %v", event)
				switch event.key_code {
				// TODO
				}
			case events.WindowResizeEvent:
				paint.resizeFrameBuffer(
					&frame_buffer,
					i16(window.client_rect.width),
					i16(window.client_rect.height),
				)
			case events.WindowCloseEvent:
				isRunning = false
			}
		}
		msg_t := os.time()
		updateAndRender()
		render_t := os.time()
		if false {
			fmt.printf(
				"dt: %v ms, max_ddt: %v ms, frame_msg_time: %v ms, frame_render_time: %v ms\n",
				math.millis(dt),
				timing.max_ddt,
				math.millis(msg_t - timing.t),
				math.millis(render_t - msg_t),
			)
		}
		timing.prev_t = timing.t
		timing.t = events.doVsyncBadly()
		onPaint(window^)
		free_all(context.temp_allocator)
	}
}
onPaint :: proc(window: events.Window) {
	paint.copyFrameBufferToWindow(frame_buffer, window)
}

// NOTE: WS_EX_LAYERED -> alpha channel
// NOTE: perfmon = systrace for windows
// TODO!: load windows screenshots
// TODO!: allow cropping svgs
// TODO?: 1D LUTs + 16x16x16 3D LUTs
// TODO?: multithreading around windows events to get above 10000fps
