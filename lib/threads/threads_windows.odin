package threads_lib
import "../../utils/math"
import "base:intrinsics"
import win "core:sys/windows"

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
	if increment_thread_count {intrinsics.atomic_add(&running_thread_count, 1)}
	os_thread_info.handle = win.CreateThread(nil, uint(stack_size), thread_proc, param, 0, &os_thread_info.id)
	return
}

OsSemaphore :: distinct win.HANDLE
_createSemaphore :: proc(max_count: i32) -> OsSemaphore {
	return OsSemaphore(win.CreateSemaphoreW(nil, 0, max_count, nil))
}
_resumeThread :: proc() {
	win.ReleaseSemaphore(win.HANDLE(_semaphore), 1, nil)
}
_waitForSemaphore :: proc() {
	win.WaitForSingleObject(win.HANDLE(_semaphore), win.INFINITE)
}
