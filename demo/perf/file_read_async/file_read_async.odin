// odin run demo/perf/file_read_async
package main

import "../utils"
import "../utils/ioringapi"
import "base:runtime"
import "core:fmt"
import vmem "core:mem/virtual"
import "core:strings"
import win "core:sys/windows"
import "core:thread"
import "core:time"

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
	ioring: ioringapi.HIORING
	flags := ioringapi.IORING_CREATE_FLAGS {
		required = .NONE,
		advisory = .NONE,
	}
	error := ioringapi.CreateIoRing(.VERSION_3, flags, 64, 64, &ioring)
	assert(error == 0)
	utils.log_time(&log, "CreateIoRing()")
	logIoRingInfo(&log, ioring)
	// open files
	file_handles: [FILE_COUNT]win.HANDLE
	file_infos: [FILE_COUNT]FileInfo
	file_handles[0] = open_file_for_reading(win.utf8_to_wstring(utils.sbprint_file_path("%v/1gb_file.txt", utils.TEST_FILE_PATH)))
	file_infos[0] = FileInfo{0, 1024 * 1024 * 1024}
	for i in 1 ..< FILE_COUNT {
		file_path := win.utf8_to_wstring(utils.sbprint_file_path("%v/small_file_%v.txt", utils.TEST_FILE_PATH, i - 1))
		file_handles[i] = open_file_for_reading(file_path)
		file_infos[i] = FileInfo{u32(i), 4096}
	}
	//utils.logf(&log, "file_infos: %v", file_infos)
	utils.log_time(&log, "open a 1GB file and 8 4KB files")
	ioringapi.BuildIoRingRegisterFileHandles(ioring, u32(len(file_handles)), &file_handles[0], win.UINT_PTR(0xc0ffee))
	utils.log_time(&log, "BuildIoRingRegisterFileHandles(.., 0xc0ffee)")
	// make buffers
	buffer_infos: [FILE_COUNT]ioringapi.IORING_BUFFER_INFO
	for file, i in file_infos {
		buffer := make([]u8, file.size)
		buffer_infos[i] = ioringapi.IORING_BUFFER_INFO{&buffer[0], u32(len(buffer))}
	}
	utils.log_time(&log, "buffers[i] = make([]u8, files[i].size)")
	ioringapi.BuildIoRingRegisterBuffers(ioring, len(buffer_infos), &buffer_infos[0], 0xf00dbabe)
	utils.log_time(&log, "BuildIoRingRegisterBuffers(.., 0xf00dbabe)")
	// read files asynchronously
	utils.log_group(&log, "-- READ 8 4KB files --")
	read_files_asynchronously(&log, ioring, file_infos[1:], buffer_infos[1:])
	utils.log_group(&log, "-- READ a 1GB file and 8 4KB files --")
	read_files_asynchronously(&log, ioring, file_infos[:], buffer_infos[:])
	// print log
	utils.print_timing_log(log)
}
FileInfo :: struct {
	id:   u32,
	size: i64,
}
open_file_for_reading :: proc(file_path: [^]u16) -> (handle: win.HANDLE) {
	handle = win.CreateFileW(file_path, win.GENERIC_READ, win.FILE_SHARE_READ, nil, win.OPEN_EXISTING, win.FILE_ATTRIBUTE_NORMAL, nil)
	fmt.assertf(win.GetLastError() == 0, "Failed to open file: %v", file_path)
	return
}
read_files_asynchronously :: proc(
	log: ^utils.TimingLog,
	ioring: ioringapi.HIORING,
	file_infos: []FileInfo,
	buffer_infos: []ioringapi.IORING_BUFFER_INFO,
) {
	ThreadData :: struct {
		allocator:  runtime.Allocator,
		log:        ^utils.TimingLog,
		ioring:     ioringapi.HIORING,
		file_infos: []FileInfo,
	}
	thread_data := ThreadData{context.allocator, log, ioring, file_infos}
	thread_proc :: proc(raw_data: rawptr) {
		thread_data := (^ThreadData)(raw_data)
		context.allocator = thread_data.allocator
		context.temp_allocator = thread_data.allocator
		for file, i in thread_data.file_infos {
			user_data := (^u32)(uintptr(file.id))
			error := ioringapi.BuildIoRingReadFile(
				thread_data.ioring,
				ioringapi.IORING_HANDLE_REF{Kind = .IORING_REF_REGISTERED, HandleUnion = file.id},
				ioringapi.IORING_BUFFER_REF{Kind = .IORING_REF_REGISTERED, BufferUnion = ioringapi.IORING_REGISTERED_BUFFER{file.id, 0}},
				u64(file.size),
				0,
				user_data,
				ioringapi.IORING_SQE_FLAGS.NONE,
			)
			fmt.assertf(error == 0, "error: %v")
		}
		utils.log_time(thread_data.log, "thread 1: BuildIoRingReadFile(IORING_REF_REGISTERED(i), IORING_REF_REGISTERED(i))")
		ioringapi.SubmitIoRing(thread_data.ioring, 0, 0, nil)
		utils.log_time(thread_data.log, "thread 1: SubmitIoRing(ioring, 0, 0, nil)")
	}
	thread2 := thread.create_and_start_with_data(&thread_data, thread_proc)
	completions := 0
	for completions < len(file_infos) {
		result: ioringapi.IORING_CQE
		for {
			if ioringapi.PopIoRingCompletion(ioring, &result) == win.S_OK {
				if result.user_data < FILE_COUNT {
					break
				} else {
					// previously issued operations get completed only when we issue a read..
					utils.log_timef(log, "thread 0: misc_result: %v", result)
				}
			}
		}
		buffer := ([^]byte)(buffer_infos[completions].address)
		fmt.assertf(string(buffer[:8]) == "aaaabbb\n", "%v", buffer[:8])
		start_file_id := file_infos[0].id
		fmt.assertf(int(result.user_data) == int(start_file_id) + completions, "Out of order reads!")
		utils.log_timef(log, "thread 0: result: %v", result)
		completions += 1
	}
	utils.log_time(log, "thread 0: wait for results via PopIoRingCompletion()")
	thread.join(thread2)
}
logIoRingInfo :: proc(log: ^utils.TimingLog, ioring: ioringapi.HIORING) {
	info: ioringapi.IORING_INFO
	error := i32(ioringapi.GetIoRingInfo(ioring, &info))
	fmt.assertf(error == 0, "error = %v, info = %v", error, info)
	utils.log_time(log, "GetIoRingInfo()")
}

// !TODO: use this in lib
