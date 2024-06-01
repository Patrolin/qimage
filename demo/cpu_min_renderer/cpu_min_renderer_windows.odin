// odin run demo/cpu_min_renderer -subsystem:windows
// odin run demo/cpu_min_renderer -subsystem:windows -o:speed
package main

import "../../lib/events"
import "../../lib/math"
import "../../lib/os"
import "../../lib/paint"
import "core:fmt"

isRunning := false
frame_buffer := paint.FrameBuffer{} // NOTE: copying the frameBuffer is very slow, so we instead we store it in an OS specific format

main :: proc() {
	context = os.init()
	events.initEvents({onPaint})
	window := events.openWindow("cpu_min_renderer", {1200, 800})
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
			#partial switch event in os_event {
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
		fmt.printf(
			"dt: %v ms, max_ddt: %v ms, frame_msg_time: %v ms, frame_render_time: %v ms\n",
			math.millis(dt),
			timing.max_ddt,
			math.millis(msg_t - timing.t),
			math.millis(render_t - msg_t),
		)
		timing.prev_t = timing.t
		timing.t = events.doVsyncBadly()
		onPaint(window^)
		free_all(context.temp_allocator)
	}
}
updateAndRender :: proc() {
	// NOTE: this takes 7 ms (.7 ms with -o:speed)
	for y in 0 ..< int(frame_buffer.height) {
		for x in 0 ..< int(frame_buffer.width) {
			rgba := math.f32x4{128, 128, 255, 0}
			paint.packRGBA(frame_buffer, x, y, rgba)
		}
	}
}
onPaint :: proc(window: events.Window) {
	paint.copyFrameBufferToWindow(frame_buffer, window)
}

// NOTE: WS_EX_LAYERED -> alpha channel (but everything is slower, so destroy and recreate the window later)
// NOTE: casey says use D3D11/Metal: https://guide.handmadehero.org/code/day570/#7492
// NOTE: casey not using OpenGL: https://guide.handmadehero.org/code/day655/#10552
// TODO!: fonts (163/164): https://www.youtube.com/playlist?list=PLEMXAbCVnmY43tjaptnJW0rMP-DsXww1Y
// NOTE: does windows render in sRGB by default? - yes, SetICMMode() to use non sRGB
// https://learn.microsoft.com/en-us/windows/win32/wcs/srgb--a-standard-color-space
// https://learn.microsoft.com/en-us/windows/win32/wcs/basic-functions-for-use-within-a-device-context
