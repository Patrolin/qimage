// odin run demo/perf/file_read_async
package file_read_async
import "core:c"
import "core:fmt"
import "core:intrinsics"
import "core:strings"
import win "core:sys/windows"

IORING_VERSION :: enum u32 {
	INVALID,
	V1,
	V2,
	V3,
	V4,
}
IORING_CREATE_REQUIRED_FLAGS :: enum u32 {
	IORING_CREATE_REQUIRED_FLAGS_NONE,
}
IORING_CREATE_ADVISORY_FLAGS :: enum u32 {
	IORING_CREATE_ADVISORY_FLAGS_NONE,
	IORING_CREATE_SKIP_BUILDER_PARAM_CHECKS,
}
IORING_CREATE_FLAGS :: struct {
	Required: IORING_CREATE_REQUIRED_FLAGS,
	Advisory: IORING_CREATE_ADVISORY_FLAGS,
}
HIORING :: distinct win.LPVOID

when ODIN_OS == .Windows do foreign import io_ring "io_ring.lib"
foreign io_ring {
	foo_add_int :: proc(a, b: c.int) -> c.int ---
	//MyCreateIoRing :: proc(ioringVersion: IORING_VERSION, flags: IORING_CREATE_FLAGS, submissionQueueSize: win.UINT32, completionQueueSize: win.UINT32, h: ^HIORING) -> win.HRESULT ---
	MyCreateIoRing :: proc() -> HIORING ---
}

cycles :: proc() -> u64 {
	return u64(intrinsics.read_cycle_counter())
}
printTime :: proc(t1, t2: u64) {
	time := f64(t2 - t1) / 3e9
	fmt.printf("cycles: %v, time: %.5f s\n", t2 - t1, time)
}
main :: proc() {
	fmt.println(foo_add_int(2, 2))
	t1 := cycles()
	printTime(0, t1)
	io_ring: HIORING
	io_ring = MyCreateIoRing() // NOTE: CreateIoRing() fails to link for some reason
	/*IORING_VERSION.V1,
		IORING_CREATE_FLAGS {
			Required = IORING_CREATE_REQUIRED_FLAGS.IORING_CREATE_REQUIRED_FLAGS_NONE,
			Advisory = IORING_CREATE_ADVISORY_FLAGS.IORING_CREATE_ADVISORY_FLAGS_NONE,
		},
		10,
		10,
		&io_ring,*/

	t2 := cycles()
	printTime(t1, t2)
}
