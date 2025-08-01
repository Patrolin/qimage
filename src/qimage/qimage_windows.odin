// odin run src/qimage -subsystem:windows -default-to-nil-allocator
package main
import "../../lib/event"
import "../../lib/file"
import "../../lib/gl"
import "../../lib/input"
import "../../lib/paint"
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
import "../../utils/threads"
import "../../utils/time"
import "../assets"
import "base:runtime"
import "core:fmt"
import win "core:sys/windows"

// globals
is_running := false
frame_buffer := paint.FrameBuffer{} // NOTE: copying the frameBuffer is slow (.7+ ms), so we instead we store it in an OS specific format
image: file.Image

// procedures
main :: proc() {
	context = threads.init()
	event.initEvents({on_paint})
	input.initInputs()
	window := event.openWindow("qimage", {1200, 800})
	image = assets.loadImage("test_image.bmp")
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
			switch event in os_event {
			case event.RawMouseEvent:
				//fmt.printfln("event: %v", event)
				#partial switch event.LMB {
				case .Down, .Up:
					input.setButton(&input.mouse.LMB, event.LMB == .Up)
					fmt.printfln("mouse: %v", input.mouse)
				}
				#partial switch event.RMB {
				case .Down, .Up:
					input.setButton(&input.mouse.RMB, event.RMB == .Up)
					fmt.printfln("mouse: %v", input.mouse)
				}
			case event.MouseMoveEvent:
				input.addMousePath(event.client_pos)
			case event.KeyboardEvent:
				//fmt.printfln("event: %v", event)
				switch event.key_code {
				// TODO
				}
			case event.WindowResizeEvent:
				paint.resizeFrameBuffer(&frame_buffer, i16(window.client_rect.width), i16(window.client_rect.height))
			case event.WindowCloseEvent:
				is_running = false
			}
		}
		msg_t := time.time()
		update_and_render()
		render_t := time.time()
		if false {
			fmt.printf(
				"dt: %.3v ms, max_dt: %.3v ms, frame_msg_time: %.3v ms, frame_render_time: %.3v ms\n",
				time.as(dt, time.MILLISECOND),
				time.as(timing.max_dt, time.MILLISECOND),
				time.as(msg_t - timing.t, time.MILLISECOND),
				time.as(render_t - msg_t, time.MILLISECOND),
			)
		}
		timing.prev_t = timing.t
		timing.t = event.doVsyncBadly()
		on_paint(window^)
		free_all(context.temp_allocator)
		input.applyInputs()
	}
}
on_paint :: proc(window: event.Window) {
	paint.copyFrameBufferToWindow(frame_buffer, window)
}

// TODO: perfmon = systrace for windows
// TODO: load windows screenshots
// TODO: allow cropping/padding svgs
// ?TODO: 1D LUTs + 16x16x16 3D LUTs
// ?TODO: multithreading around windows events to get above 10000fps
