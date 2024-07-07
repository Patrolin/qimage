// odin run demo/perf/file_read_async
package main

foreign import ioringapi "system:onecore.lib"
import "core:fmt"
import win "core:sys/windows"
import "core:time"

prev_time: time.Time
startTiming :: proc() {
	prev_time = time.now()
}
endTiming :: proc(str: string) {
	current_time := time.now()
	fmt.printf("-- %v: %.3f s\n", str, f64(time.diff(prev_time, current_time)) / f64(time.Second))
	prev_time = current_time
}

HIORING :: distinct win.HANDLE
main :: proc() {
	// create ioring
	startTiming()
	ioring: HIORING
	flags := IORING_CREATE_FLAGS {
		required = .NONE,
		advisory = .NONE,
	}
	error := CreateIoRing(.VERSION_3, flags, 0, 0, &ioring)
	fmt.printf("  CreateIoRing, error = %v, ioring: %v\n", error, ioring)
	checkIoRingInfo(ioring)
	endTiming("create ioring")
	// open file
	file := win.CreateFileW(
		win.utf8_to_wstring("demo/perf/make_1gb_file/1gb_file.txt"),
		win.GENERIC_READ,
		win.FILE_SHARE_READ,
		nil,
		win.OPEN_EXISTING,
		win.FILE_ATTRIBUTE_NORMAL,
		nil,
	)
	endTiming("open file")
	assert(file != nil)
	// make buffer
	buffer := make([]u8, 1024 * 1024 * 1024)
	endTiming("create buffer")
	// async read file
	error = BuildIoRingReadFile(
		ioring,
		IORING_HANDLE_REF{Kind = .IORING_REF_RAW, HandleUnion = win.HANDLE(file)},
		IORING_BUFFER_REF{Kind = .IORING_REF_RAW, BufferUnion = win.LPVOID(&buffer[0])},
		u64(len(buffer)),
		0,
		nil,
		IORING_SQE_FLAGS.NONE,
	)
	fmt.printf("  BuildIoRingReadFile, error = %v\n", error)
	checkIoRingInfo(ioring)
	endTiming("async read file")
	// get result
	submit_buffer := make([]u32, 1)
	error = SubmitIoRing(ioring, u32(len(submit_buffer)), win.INFINITE, &submit_buffer[0]) // TODO: use PopIoRingCompletion() for waiting
	fmt.printf("  SubmitIoRing, error = %v\n", error)
	fmt.printf("  buffer[:4]: %v\n", buffer[:8])
	endTiming("get result")
}
checkIoRingInfo :: proc(ioring: HIORING) {
	info: IORING_INFO
	error := GetIoRingInfo(ioring, &info)
	fmt.printf("  GetIoRingInfo, error = %v, info = %v\n", error, info)
}

IORING_VERSION :: enum i32 {
	INVALID,
	VERSION_1,
	VERSION_2,
	VERSION_3 = 300,
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
	version:               IORING_VERSION,
	flags:                 IORING_CREATE_FLAGS,
	submission_queue_size: u32,
	completion_queue_size: u32,
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
IORING_CQE :: struct {
	user_data:   uintptr,
	result_code: win.HRESULT,
	information: win.ULONG_PTR,
}

@(default_calling_convention = "std")
foreign ioringapi {
	CreateIoRing :: proc(version: IORING_VERSION, flags: IORING_CREATE_FLAGS, submission_queue_size: u32, completion_queue_size: u32, ioring: ^HIORING) -> win.HRESULT ---
	GetIoRingInfo :: proc(ioring: HIORING, info: ^IORING_INFO) -> win.HRESULT ---
	BuildIoRingReadFile :: proc(ioring: HIORING, file: IORING_HANDLE_REF, data: IORING_BUFFER_REF, bytes_to_read: u64, file_offset: u64, user_data: ^u32, flags: IORING_SQE_FLAGS) -> win.HRESULT ---
	BuildIoRingCancelRequest :: proc(ioring: HIORING, file: IORING_HANDLE_REF, op_to_cancel: win.PVOID, user_data: win.PVOID) -> win.HRESULT ---
	SubmitIoRing :: proc(ioring: HIORING, buffer_size: u32, timeout_millis: u32, buffer: ^u32) -> win.HRESULT ---
	PopIoRingCompletion :: proc(ioring: HIORING, cqe: ^IORING_CQE) ---
}

// TODO!: use this in lib
