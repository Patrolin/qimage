// odin run demo/perf/file_read_async
package file_read_async
import "core:fmt"
import "core:intrinsics"
import "core:strings"
import win "core:sys/windows"

IORING_VERSION :: enum {
	INVALID,
	V1,
	V2,
	V3,
	V4,
}
IORING_CREATE_REQUIRED_FLAGS :: enum {
	IORING_CREATE_REQUIRED_FLAGS_NONE,
}
IORING_CREATE_ADVISORY_FLAGS :: enum {
	IORING_CREATE_ADVISORY_FLAGS_NONE,
	IORING_CREATE_SKIP_BUILDER_PARAM_CHECKS,
}
IORING_CREATE_FLAGS :: struct {
	Required: IORING_CREATE_REQUIRED_FLAGS,
	Advisory: IORING_CREATE_ADVISORY_FLAGS,
}
HIORING :: distinct win.HANDLE

foreign import io_ring "io_ring.lib"
@(default_calling_convention = "std")
foreign io_ring {
	MyCreateIoRing :: proc(ioringVersion: IORING_VERSION, flags: IORING_CREATE_FLAGS, submissionQueueSize: win.UINT32, completionQueueSize: win.UINT32, h: ^HIORING) -> win.HRESULT ---
}

cycles :: proc() -> u64 {
	return u64(intrinsics.read_cycle_counter())
}
printTime :: proc(t1, t2: u64) {
	time := f64(t2 - t1) / 3e9
	fmt.printf("cycles: %v, time: %.5f s\n", t2 - t1, time)
}
main :: proc() {
	t1 := cycles()
	printTime(0, t1)
	io_ring: HIORING
	// this crashes when not available
	MyCreateIoRing(
		IORING_VERSION.V4,
		IORING_CREATE_FLAGS {
			Required = IORING_CREATE_REQUIRED_FLAGS.IORING_CREATE_REQUIRED_FLAGS_NONE,
			Advisory = IORING_CREATE_ADVISORY_FLAGS.IORING_CREATE_ADVISORY_FLAGS_NONE,
		},
		10,
		10,
		&io_ring,
	)
	t2 := cycles()
	printTime(t1, t2)
}
