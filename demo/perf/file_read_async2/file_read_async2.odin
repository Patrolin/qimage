// odin run demo/perf/file_read_async2
package main

foreign import ioringapi "system:onecore.lib"
import "core:fmt"
import win "core:sys/windows"

HIORING__ :: struct {
	unused: i32,
}
HIORING :: ^HIORING__
main :: proc() {
	ioring_handle: HIORING__
	flags := IORING_CREATE_FLAGS {
		Required = .NONE,
		Advisory = .NONE,
	}
	error := CreateIoRing(.VERSION_1, flags, 8, 8, &ioring_handle)
	fmt.printf("error = %v, ioring_handle: %v", error, ioring_handle)
}

IORING_VERSION :: enum i32 {
	INVALID   = 0,
	VERSION_1 = 1,
}

IORING_CREATE_REQUIRED_FLAGS :: enum i32 {
	NONE = 0,
}
IORING_CREATE_ADVISORY_FLAGS :: enum i32 {
	NONE = 0,
}
IORING_CREATE_FLAGS :: struct {
	Required: IORING_CREATE_REQUIRED_FLAGS,
	Advisory: IORING_CREATE_ADVISORY_FLAGS,
}

@(default_calling_convention = "std")
foreign ioringapi {
	CreateIoRing :: proc(ioringVersion: IORING_VERSION, flags: IORING_CREATE_FLAGS, submissionQueueSize: u32, completionQueueSize: u32, out_handle: ^HIORING__) -> win.HRESULT ---
}
