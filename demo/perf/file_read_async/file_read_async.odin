// odin run demo/perf/file_read_async
package main

foreign import ioringapi "system:onecore.lib"
import "../utils"
import "core:fmt"
import vmem "core:mem/virtual"
import win "core:sys/windows"
import "core:time"

HIORING :: distinct win.HANDLE
main :: proc() {
	// setup
	win.SetConsoleOutputCP(win.CODEPAGE(win.CP_UTF8))
	arena: vmem.Arena
	ARENA_SIZE :: 2 * 1024 * 1024 * 1024
	arena_buffer_ptr := win.VirtualAlloc(
		nil,
		ARENA_SIZE,
		win.MEM_RESERVE | win.MEM_COMMIT,
		win.PAGE_READWRITE,
	)
	assert(arena_buffer_ptr != nil)
	arena_buffer := (cast([^]u8)arena_buffer_ptr)[:ARENA_SIZE]
	assert(arena_buffer != nil)
	arena_err := vmem.arena_init_buffer(&arena, arena_buffer)
	ensure(arena_err == nil)
	context.allocator = vmem.arena_allocator(&arena)
	context.temp_allocator = context.allocator
	log := utils.make_log()
	// get file_path
	file_path := win.utf8_to_wstring("demo/perf/make_1gb_file/1gb_file.txt")
	utils.log_time(&log, "utf8_to_wstring()")
	// create ioring
	ioring: HIORING
	flags := IORING_CREATE_FLAGS {
		required = .NONE,
		advisory = .NONE,
	}
	error := CreateIoRing(.VERSION_3, flags, 0, 0, &ioring)
	assert(error == 0)
	utils.log_time(&log, "CreateIoRing()")
	info1, error1 := getIoRingInfo(ioring)
	utils.logf(&log, "GetIoRingInfo, error = %v, info = %v", error1, info1)
	utils.log_time(&log, "GetIoRingInfo()")
	// open file
	file := win.CreateFileW(
		file_path,
		win.GENERIC_READ,
		win.FILE_SHARE_READ,
		nil,
		win.OPEN_EXISTING,
		win.FILE_ATTRIBUTE_NORMAL,
		nil,
	)
	utils.log_time(&log, "CreateFileW()")
	assert(file != nil)
	// make buffer
	buffer := make([]u8, 1024 * 1024 * 1024)
	utils.log_time(&log, "buffer := make([]u8, 1GB)")
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
	utils.log_time(&log, "BuildIoRingReadFile()")
	assert(error == 0)
	info2, error2 := getIoRingInfo(ioring)
	utils.logf(&log, "GetIoRingInfo, error = %v, info = %v", error2, info2)
	utils.log_time(&log, "GetIoRingInfo()")
	// submit operations
	error = SubmitIoRing(ioring, 0, 0, nil)
	utils.logf(&log, "SubmitIoRing, error = %v", error)
	utils.log_time(&log, "SubmitIoRing()")
	// wait for result
	did_read := false
	results: [1]IORING_CQE
	for !did_read {
		did_read = PopIoRingCompletion(ioring, &results[0]) == win.S_OK
	}
	utils.logf(&log, "buffer[:8]: %v", buffer[:8])
	utils.log_time(&log, "wait for result via PopIoRingCompletion()")
	// print log
	utils.print_timing_log(log)
}
getIoRingInfo :: proc(ioring: HIORING) -> (info: IORING_INFO, error: i32) {
	error = i32(GetIoRingInfo(ioring, &info))
	return
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
	PopIoRingCompletion :: proc(ioring: HIORING, cqe: ^IORING_CQE) -> win.HRESULT ---
}

// TODO!: check performance for many small files
// TODO!: use this in lib
