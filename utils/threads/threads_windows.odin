package threads_utils
import "../../utils/math"
import "../../utils/mem"
import "base:intrinsics"
import "base:runtime"
import win "core:sys/windows"

ThreadInfo :: struct #align(mem.CACHE_LINE_SIZE) {
	temporary_allocator_data: mem.ArenaAllocator,
	os_info:                  OsThreadInfo,
	index:                    u32,
}
#assert(size_of(ThreadInfo) <= mem.CACHE_LINE_SIZE)
#assert((size_of(ThreadInfo) % mem.CACHE_LINE_SIZE) == 0)

OsThreadInfo :: struct #packed {
	handle: win.HANDLE,
	id:     u32,
}
launch_os_thread :: proc(
	stack_size: math.Size,
	thread_proc: proc "stdcall" (data: rawptr) -> u32,
	param: rawptr,
	increment_thread_count := true,
) -> (
	os_thread_info: OsThreadInfo,
) {
	if increment_thread_count {intrinsics.atomic_add(&total_thread_count, 1)}
	os_thread_info.handle = win.CreateThread(nil, uint(stack_size), thread_proc, param, 0, &os_thread_info.id)
	return
}

OsSemaphore :: distinct win.HANDLE
_create_semaphore :: proc(max_count: i32) -> OsSemaphore {
	return OsSemaphore(win.CreateSemaphoreW(nil, 0, max_count, nil))
}
_wait_for_semaphore :: proc() {
	win.WaitForSingleObject(win.HANDLE(semaphore), win.INFINITE)
}
_resume_thread :: proc() {
	win.ReleaseSemaphore(win.HANDLE(semaphore), 1, nil)
}
