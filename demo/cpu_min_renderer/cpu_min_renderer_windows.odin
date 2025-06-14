// odin run demo/cpu_min_renderer -subsystem:windows
// odin run demo/cpu_min_renderer -subsystem:windows -o:speed
package main

import "../../lib/event"
import "../../lib/paint"
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
import "../../utils/threads"
import "../../utils/time"
import "core:fmt"

// globals
is_running := false
frame_buffer := paint.FrameBuffer{} // NOTE: copying the frameBuffer is very slow, so we instead we store it in an OS specific format

// procedures
main :: proc() {
	context = threads.init()
	event.initEvents({on_paint})
	window := event.openWindow("cpu_min_renderer", {1200, 800})
	paint.resizeFrameBuffer(&frame_buffer, i16(window.client_rect.width), i16(window.client_rect.height))
	// TODO: Timer?
	timing: struct {
		t, prev_t, max_dt: time.Duration,
		frame:             int,
	}
	timing.t = time.time()
	timing.prev_t = timing.t
	for is_running = true; is_running; {
		dt := timing.t - timing.prev_t
		timing.frame += 1
		if (timing.frame > 30) {timing.max_dt = max(timing.max_dt, abs(dt))}
		event.getAllEvents()
		for os_event in event.os_events {
			#partial switch event in os_event {
			case event.WindowResizeEvent:
				paint.resizeFrameBuffer(&frame_buffer, i16(window.client_rect.width), i16(window.client_rect.height))
			case event.WindowCloseEvent:
				is_running = false
			}
		}
		msg_t := time.time()
		update_and_render()
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
		on_paint(window^)
		free_all(context.temp_allocator)
	}
}
update_and_render :: proc() {
	// NOTE: this takes 7 ms (.7 ms with -o:speed)
	for y in 0 ..< int(frame_buffer.height) {
		for x in 0 ..< int(frame_buffer.width) {
			rgba := math.f32x4{128, 128, 255, 0}
			paint.packRGBA(frame_buffer, x, y, rgba)
		}
	}
}
on_paint :: proc(window: event.Window) {
	paint.copyFrameBufferToWindow(frame_buffer, window)
}

// NOTE: WS_EX_LAYERED -> alpha channel (but everything is slower, so destroy and recreate the window later)
// NOTE: casey says use D3D11/Metal: https://guide.handmadehero.org/code/day570/#7492
// NOTE: casey not using OpenGL: https://guide.handmadehero.org/code/day655/#10552
// TODO: fonts (163/164): https://www.youtube.com/playlist?list=PLEMXAbCVnmY43tjaptnJW0rMP-DsXww1Y
// NOTE: does windows render in sRGB by default? - yes, SetICMMode() to use non sRGB
// https://learn.microsoft.com/en-us/windows/win32/wcs/srgb--a-standard-color-space
// https://learn.microsoft.com/en-us/windows/win32/wcs/basic-functions-for-use-within-a-device-context
