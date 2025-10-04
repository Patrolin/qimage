// odin run demo/perf/file_read_async
package main

import "../utils"
import "base:runtime"
import "core:fmt"
import vmem "core:mem/virtual"
import "core:strings"
import win "core:sys/windows"
import "core:thread"
import "core:time"

Ioring :: win.HANDLE /* IocpHandle */

FILE_COUNT :: 1 + utils.SMALL_TEST_FILE_COUNT
main :: proc() {
	// setup
	win.SetConsoleOutputCP(win.CODEPAGE(win.CP_UTF8))
	arena: vmem.Arena
	ARENA_SIZE :: 2 * 1024 * 1024 * 1024
	arena_buffer_ptr := win.VirtualAlloc(nil, ARENA_SIZE, win.MEM_RESERVE | win.MEM_COMMIT, win.PAGE_READWRITE)
	assert(arena_buffer_ptr != nil)
	arena_buffer := (cast([^]byte)arena_buffer_ptr)[:ARENA_SIZE]
	assert(arena_buffer != nil)
	arena_err := vmem.arena_init_buffer(&arena, arena_buffer)
	ensure(arena_err == nil)
	context.allocator = vmem.arena_allocator(&arena)
	context.temp_allocator = context.allocator
	log := utils.make_log()
	// create ioring
	ioring := win.CreateIoCompletionPort(win.INVALID_HANDLE, nil, 0, 0)
	fmt.assertf(ioring != nil, "Failed to create an IOCP")
	// associate ioring with file
	// open files
	file_handles: [FILE_COUNT]win.HANDLE
	file_infos: [FILE_COUNT]FileInfo
	big_file_info := &file_infos[0]
	big_file_info.handle = open_file_for_reading(utils.sbprint_file_path("%v/1gb_file.txt", utils.TEST_FILE_PATH))
	big_file_info.size = 1024 * 1024 * 1024
	for i in 1 ..< FILE_COUNT {
		file_path := utils.sbprint_file_path("%v/small_file_%v.txt", utils.TEST_FILE_PATH, i - 1)
		file_info := &file_infos[i]
		file_info.handle = open_file_for_reading(file_path)
		file_info.size = 4096
	}
	utils.log_time(&log, "open a 1GB file and 8 4KB files")
	// make buffers
	for &file_info, index in file_infos {
		file_info.index = index
		file_info.buffer = make([]u8, file_info.size)
	}
	utils.log_time(&log, "buffers[i] = make([]u8, files[i].size)")
	// associate ioring with files
	for file_info in file_infos {
		result := win.CreateIoCompletionPort(file_info.handle, ioring, 0, 0)
		fmt.assertf(result != nil, "Failed to associate ioring %v with file %v", ioring, file_info)
	}
	utils.log_time(&log, "CreateIoCompletionPort(file_info.handle, ioring, 0, 0)")
	// read files asynchronously
	utils.log_group(&log, "-- READ 8 4KB files --")
	read_files_async(&log, ioring, file_infos[1:])
	utils.log_group(&log, "-- READ a 1GB file and 8 4KB files --")
	read_files_async(&log, ioring, file_infos[:])
	// print log
	utils.print_timing_log(log)
}
FileInfo :: struct {
	overlapped: win.OVERLAPPED,
	index:      int,
	handle:     win.HANDLE,
	size:       int,
	buffer:     []byte `fmt:"-"`,
}
open_file_for_reading :: proc(file_path: string) -> (handle: win.HANDLE) {
	wfile_path := ([^]u16)(win.utf8_to_wstring(file_path))
	handle = win.CreateFileW(
		cstring16(wfile_path),
		win.GENERIC_READ,
		win.FILE_SHARE_READ,
		nil,
		win.OPEN_EXISTING,
		win.FILE_FLAG_OVERLAPPED,
		nil,
	)
	fmt.assertf(handle != win.INVALID_HANDLE, "Failed to open file: %v", file_path)
	return
}
read_files_async :: proc(log: ^utils.TimingLog, ioring: Ioring, file_infos: []FileInfo) {
	ThreadData :: struct {
		allocator:  runtime.Allocator,
		log:        ^utils.TimingLog,
		ioring:     Ioring,
		file_infos: []FileInfo,
	}
	thread_data := ThreadData{context.allocator, log, ioring, file_infos}
	thread_proc :: proc(thread_user_data: rawptr) {
		thread_data := (^ThreadData)(thread_user_data)
		context.allocator = thread_data.allocator
		context.temp_allocator = thread_data.allocator
		for &file_info in thread_data.file_infos {
			result := win.ReadFile(file_info.handle, raw_data(file_info.buffer), u32(len(file_info.buffer)), nil, &file_info.overlapped)
			err := win.GetLastError()
			fmt.assertf(result == true || err == win.ERROR_IO_PENDING, "err: %v", err)
			utils.log_timef(thread_data.log, "thread 1: ReadFile(%v, &file_info.overlapped)", file_info.index)
		}
	}
	second_thread := thread.create_and_start_with_data(&thread_data, thread_proc)
	completions := 0
	for completions < len(file_infos) {
		bytes_transferred: u32
		completion_key: uint
		overlapped: ^win.OVERLAPPED
		ok := win.GetQueuedCompletionStatus(ioring, &bytes_transferred, &completion_key, &overlapped, win.INFINITE)
		assert(bool(ok))

		file_info := (^FileInfo)(overlapped)
		buffer := file_info.buffer
		fmt.assertf(string(buffer[:8]) == "aaaabbb\n", "%v", buffer[:8])
		utils.log_timef(log, "thread 0: finished reading file %v", file_info.index)
		fmt.assertf(file_info.index == file_infos[0].index + completions, "Out of order reads!")
		completions += 1
	}
	utils.log_time(log, "thread 0: got all results")
	thread.join(second_thread)
}
// !TODO: use this in lib
