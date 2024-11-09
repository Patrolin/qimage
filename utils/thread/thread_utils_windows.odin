package thread_utils
import "../math"
import win "core:sys/windows"

OsThreadId :: struct #packed {
	handle: win.HANDLE,
	id:     u32,
}
_createThread :: proc(
	stack_size: math.bytes,
	thread_proc: proc "stdcall" (data: rawptr) -> u32,
	param: rawptr,
) -> (
	thread_id: OsThreadId,
) {
	thread_id.handle = win.CreateThread(
		nil,
		uint(stack_size),
		thread_proc,
		param,
		0,
		&thread_id.id,
	)
	return
}

OsSemaphore :: distinct win.HANDLE
_createSemaphore :: proc(max_count: i32) -> OsSemaphore {
	return OsSemaphore(win.CreateSemaphoreW(nil, 0, max_count, nil))
}
launchThread :: proc() {
	win.ReleaseSemaphore(win.HANDLE(_semaphore), 1, nil)
}
_waitForSemaphore :: proc() {
	win.WaitForSingleObject(win.HANDLE(_semaphore), win.INFINITE)
}
