package lib_file

foreign import ioringapi "system:onecore.lib"
import "../threads"
import "base:intrinsics"
import "core:fmt"
import win "core:sys/windows"
import "core:time"

HIORING :: distinct win.HANDLE
@(default_calling_convention = "std")
foreign ioringapi {
	CreateIoRing :: proc(version: IORING_VERSION, flags: IORING_CREATE_FLAGS, submission_queue_size: u32, completion_queue_size: u32, ioring: ^HIORING) -> win.HRESULT ---
	GetIoRingInfo :: proc(ioring: HIORING, info: ^IORING_INFO) -> win.HRESULT ---
	BuildIoRingReadFile :: proc(ioring: HIORING, file: IORING_HANDLE_REF, data: IORING_BUFFER_REF, bytes_to_read: u64, file_offset: u64, user_data: ^u32, flags: IORING_SQE_FLAGS) -> win.HRESULT ---
	BuildIoRingCancelRequest :: proc(ioring: HIORING, file: IORING_HANDLE_REF, op_to_cancel: win.PVOID, user_data: win.PVOID) -> win.HRESULT ---
	SubmitIoRing :: proc(ioring: HIORING, buffer_size: u32, timeout_millis: u32, buffer: ^u32) -> win.HRESULT ---
	PopIoRingCompletion :: proc(ioring: HIORING, cqe: ^IORING_CQE) ---
}

io_ring: HIORING
initIoRing :: proc() {
	flags := IORING_CREATE_FLAGS {
		required = .NONE,
		advisory = .NONE,
	}
	error := CreateIoRing(.VERSION_3, flags, 0, 0, &io_ring)
	fmt.assertf(error == 0, "Couldn't create io ring, error: %v", error)
}
readFileAsync :: proc(path: string) {
	// open file
	file := win.CreateFileW(
		win.utf8_to_wstring(path),
		win.GENERIC_READ,
		win.FILE_SHARE_READ,
		nil,
		win.OPEN_EXISTING,
		win.FILE_ATTRIBUTE_NORMAL,
		nil,
	)
	assert(file != nil)
	// make buffer
	file_size: win.LARGE_INTEGER
	win.GetFileSizeEx(file, &file_size)
	buffer := make([]u8, file_size)
	// submit async read request
	error := BuildIoRingReadFile(
		io_ring,
		IORING_HANDLE_REF{Kind = .IORING_REF_RAW, HandleUnion = win.HANDLE(file)},
		IORING_BUFFER_REF{Kind = .IORING_REF_RAW, BufferUnion = win.LPVOID(&buffer[0])},
		u64(len(buffer)),
		0,
		nil,
		IORING_SQE_FLAGS.NONE,
	)
	fmt.assertf(error == 0, "Couldn't submit async read request, error: %v", error)
	// launch thread to get result
	intrinsics.atomic_add(&pending_file_requests, 1)
	threads.launchThread()
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
