// odin run demo/gl_min_renderer -subsystem:windows
// odin run demo/gl_min_renderer -subsystem:windows -o:speed
package main

import "../../lib/event"
import "../../lib/gl"
import "../../lib/threads"
import "../../utils/alloc"
import "../../utils/os"
import "../../utils/time"
import "core:fmt"

isRunning := false

main :: proc() {
	os.initInfo()
	alloc.init_thread_contexts()
	context = alloc.defaultContext(0)
	threads.init_threads()
	event.initEvents({onPaint})
	window := event.openWindow("gl_min_renderer", {1200, 800})
	gl.initOpenGL(window.dc)
	timing: struct {
		t, prev_t, max_dt: time.Duration,
		frame:             int,
	}
	timing.t = time.time()
	timing.prev_t = timing.t
	for isRunning = true; isRunning; {
		dt := timing.t - timing.prev_t
		timing.frame += 1
		if (timing.frame > 30) {timing.max_dt = max(timing.max_dt, abs(dt))}
		event.getAllEvents()
		for os_event in event.os_events {
			#partial switch event in os_event {
			case event.WindowResizeEvent:
				gl.resizeImageBuffer(window.client_rect.width, window.client_rect.height)
			case event.WindowCloseEvent:
				isRunning = false
			}
		}
		msg_t := time.time()
		updateAndRender()
		render_t := time.time()
		fmt.printf(
			"dt: %.3v ms, max_dt: %.3v ms, frame_msg_time: %.3v ms, frame_render_time: %.3v ms\n",
			time.as(dt, time.MILLISECOND),
			time.as(timing.max_dt, time.MILLISECOND),
			time.as(msg_t - timing.t, time.MILLISECOND),
			time.as(render_t - msg_t, time.MILLISECOND),
		)
		timing.prev_t = timing.t
		timing.t = event.doVsyncBadly()
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
onPaint :: proc(window: event.Window) {
	gl.renderImageBufferToWindow(window)
}

// !TODO: tell OpenGL we want sRGB - handmade hero 236-241
// NOTE: hmh 240: DisplayBitmapViaOpenGL() https://guide.handmadehero.org/code/day240/#1497
// NOTE: enable vsync via wglSwapIntervalExt(1)
// NOTE: are we able to disable vsync? https://guide.handmadehero.org/code/day549/#1043
