// odin run demo/perf/file_read_async
package main

import "../utils"
import "../utils/ioringapi"
import "core:fmt"
import vmem "core:mem/virtual"
import "core:strings"
import win "core:sys/windows"
import "core:time"

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
	// create ioring
	ioring: ioringapi.HIORING
	flags := ioringapi.IORING_CREATE_FLAGS {
		required = .NONE,
		advisory = .NONE,
	}
	error := ioringapi.CreateIoRing(.VERSION_3, flags, 2048, 2048, &ioring)
	assert(error == 0)
	utils.log_time(&log, "CreateIoRing()")
	logIoRingInfo(&log, ioring)
	// open files
	files: [1 + utils.SMALL_TEST_FILE_COUNT]FileInfo
	files[0].handle = open_file_for_reading(
		win.utf8_to_wstring(utils.sbprint_file_path("%v/1gb_file.txt", utils.TEST_FILE_PATH)),
	)
	files[0].size = 1024 * 1024 * 1024
	for i in 1 ..< 1 + utils.SMALL_TEST_FILE_COUNT {
		file_path := win.utf8_to_wstring(
			utils.sbprint_file_path("%v/small_file_%v.txt", utils.TEST_FILE_PATH, i - 1),
		)
		files[i].handle = open_file_for_reading(file_path)
		files[i].size = 4096
	}
	utils.log_time(&log, "open a 1GB file and 8 4KB files")
	// read files asynchronously
	utils.log_group(&log, "-- READ 8 4KB files --")
	read_files_asynchronously(&log, ioring, files[1:])
	utils.log_group(&log, "-- READ a 1GB file and 8 4KB files --")
	read_files_asynchronously(&log, ioring, files[:])
	// print log
	utils.print_timing_log(log)
}
FileInfo :: struct {
	handle: win.HANDLE,
	size:   i64,
}
open_file_for_reading :: proc(file_path: [^]u16) -> (handle: win.HANDLE) {
	handle = win.CreateFileW(
		file_path,
		win.GENERIC_READ,
		win.FILE_SHARE_READ,
		nil,
		win.OPEN_EXISTING,
		win.FILE_ATTRIBUTE_NORMAL,
		nil,
	)
	fmt.assertf(win.GetLastError() == 0, "Failed to open file: %v", file_path)
	return
}
read_files_asynchronously :: proc(
	log: ^utils.TimingLog,
	ioring: ioringapi.HIORING,
	files: []FileInfo,
) {
	buffers := make([][]u8, len(files))
	for file, i in files {
		buffers[i] = make([]u8, file.size)
	}
	utils.log_time(log, "buffers[i] = make([]u8, files[i].size)")
	for file, i in files {
		buffer := buffers[i]
		error := ioringapi.BuildIoRingReadFile(
			ioring,
			ioringapi.IORING_HANDLE_REF {
				Kind = .IORING_REF_RAW,
				HandleUnion = win.HANDLE(file.handle),
			},
			ioringapi.IORING_BUFFER_REF {
				Kind = .IORING_REF_RAW,
				BufferUnion = win.LPVOID(&buffer[0]),
			},
			u64(len(buffer)),
			0,
			(^u32)(uintptr(i)),
			ioringapi.IORING_SQE_FLAGS.NONE,
		)
		fmt.assertf(error == 0, "error: %v", error)
	}
	utils.log_time(log, "BuildIoRingReadFile(..file[i], ..buffers[i])")
	ioringapi.SubmitIoRing(ioring, 0, 0, nil)
	utils.log_time(log, "SubmitIoRing(ioring, 0, 0, nil)")
	read_count := 0
	for read_count < len(files) {
		result := new(ioringapi.IORING_CQE)
		if ioringapi.PopIoRingCompletion(ioring, result) == win.S_OK {
			fmt.assertf(
				string(buffers[read_count][:8]) == "aaaabbb\n",
				"%v",
				buffers[read_count][:8],
			)
			fmt.assertf(int(result.user_data) == read_count, "Out of order reads!")
			utils.logf(log, "result: %v", result)
			read_count += 1
		}
	}
	utils.log_time(log, "wait for results via PopIoRingCompletion()")
}
logIoRingInfo :: proc(log: ^utils.TimingLog, ioring: ioringapi.HIORING) {
	info: ioringapi.IORING_INFO
	error := i32(ioringapi.GetIoRingInfo(ioring, &info))
	fmt.assertf(error == 0, "error = %v, info = %v", error, info)
	utils.log_time(log, "GetIoRingInfo()")
}

// TODO!: check performance for many small files
// TODO!: use this in lib
