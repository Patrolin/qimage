// odin run demo/perf/file_read_async2
package main

foreign import ioringapi "system:onecore.lib"
import "core:fmt"
import win "core:sys/windows"

HIORING__ :: struct {
	id: i64,
}
HIORING :: ^HIORING__
main :: proc() {
	ioring: HIORING__
	flags := IORING_CREATE_FLAGS {
		required = .NONE,
		advisory = .NONE,
	}
	error := CreateIoRing(.VERSION_3, flags, 0, 0, &ioring)
	fmt.printf(
		"CreateIoRing, error = %v, ioring: %v, ioring_ptr: %v\n",
		error,
		ioring,
		uintptr(&ioring),
	)
	checkIoRingInfo(&ioring)
	/*
	BuildIoRingReadFile
	BuildIoRingRegisterBuffers
	BuildIoRingRegisterFileHandles
	BuildIoRingCancelRequest
	*/
}
checkIoRingInfo :: proc(ioring: HIORING) {
	info: IORING_INFO
	error := GetIoRingInfo(ioring, &info)
	fmt.printf(
		"GetIoRingInfo, error = %v, size_of = %v, info = %v\n",
		error,
		size_of(IORING_INFO),
		info,
	)
}

IORING_VERSION :: enum i32 {
	INVALID,
	VERSION_1,
	VERSION_2,
	VERSION_3 = 300,
	//VERSION_4 = ?,
}
IORING_CREATE_REQUIRED_FLAGS :: enum i32 {
	NONE,
}
IORING_CREATE_ADVISORY_FLAGS :: enum i32 {
	NONE,
}
IORING_CREATE_FLAGS :: struct {
	required: IORING_CREATE_REQUIRED_FLAGS,
	advisory: IORING_CREATE_ADVISORY_FLAGS,
}
IORING_INFO :: struct {
	version:               IORING_VERSION, // NOTE: windows returns random garbage
	flags:                 IORING_CREATE_FLAGS, // NOTE: windows returns {32758, 0}
	submission_queue_size: u32, // NOTE: windows returns 0
	completion_queue_size: u32, // NOTE: windows returns 32766
	reserved:              [4]u32,
}
IORING_REF_KIND :: enum i32 {
	IORING_REF_RAW,
	IORING_REF_REGISTERED,
}
IORING_HANDLE_REF :: struct {
	Kind:        IORING_REF_KIND,
	HandleUnion: union {
		win.HANDLE, // handle if Kind == IORING_REF_RAW
		u32, // index if Kind == IORING_REF_REGISTERED
	},
}
IORING_REGISTERED_BUFFER :: struct {
	BufferIndex: u32,
	Offset:      u32,
}
IORING_BUFFER_REF :: struct {
	Kind:        IORING_REF_KIND,
	BufferUnion: union {
		win.LPVOID, // buffer address if Kind == IORING_REF_RAW
		IORING_REGISTERED_BUFFER, // registered buffer if Kind == IORING_REF_REGISTERED
	},
}
IORING_SQE_FLAGS :: enum i32 {
	NONE,
}

@(default_calling_convention = "std")
foreign ioringapi {
	CreateIoRing :: proc(version: IORING_VERSION, flags: IORING_CREATE_FLAGS, submission_queue_size: u32, completion_queue_size: u32, ioring: HIORING) -> win.HRESULT ---
	GetIoRingInfo :: proc(ioring: HIORING, info: ^IORING_INFO) -> win.HRESULT ---
	BuildIoRingReadFile :: proc(ioring: HIORING, file: IORING_HANDLE_REF, data: IORING_BUFFER_REF, bytes_to_read: u64, file_offset: u64, user_data: ^u32, flags: IORING_SQE_FLAGS) -> win.HRESULT ---
	BuildIoRingCancelRequest :: proc(ioring: HIORING, file: IORING_HANDLE_REF, op_to_cancel: win.PVOID, user_data: win.PVOID) -> win.HRESULT ---
	SubmitIoRing :: proc(ioring: HIORING, buffer_size: u32, timeout_millis: u32, buffer: ^u32) -> win.HRESULT ---
}
