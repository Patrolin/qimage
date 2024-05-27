// odin run demo/gl_min_renderer -subsystem:windows
package main

import "../../lib/events"
import "../../lib/gl"
import "../../lib/math"
import "../../lib/os"
import "core:fmt"

isRunning := false

main :: proc() {
	context = os.init()
	events.setOnPaint(onPaint)
	events.initWindow()
	window := events.openWindow("gl_min_renderer", {-1, -1, 1366, 768})
	gl.initOpenGL(window.dc)
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
				gl.resizeImageBuffer(window.width, window.height)
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
	// NOTE: this takes 0.005 ms
	gl.glClearColor(.5, .5, 1, 1)
	gl.glClear(gl.COLOR_BUFFER_BIT)
	// NOTE: render image here (hmh 237-238)
}
onPaint :: proc(window: events.Window) {
	gl.renderImageBufferToWindow(window)
}

// TODO!: tell OpenGL we want sRGB - handmade hero 236-241
// NOTE: hmh 240: DisplayBitmapViaOpenGL() https://guide.handmadehero.org/code/day240/#1497
// NOTE: enable vsync via wglSwapIntervalExt(1)
// NOTE: are we able to disable vsync? https://guide.handmadehero.org/code/day549/#1043
