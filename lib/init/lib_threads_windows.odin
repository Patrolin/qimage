package lib_init
import "../math"
import win "core:sys/windows"

createThread :: proc(
	stack_size: math.bytes,
	thread_proc: proc "stdcall" (data: rawptr) -> u32,
	param: rawptr,
) {
	thread_id: u32
	win.CreateThread(nil, uint(stack_size), thread_proc, param, 0, &thread_id)
}

OsSemaphore :: distinct win.HANDLE
createSemaphore :: proc(max_count: i32) -> OsSemaphore {
	initial_count: i32 = 0
	return OsSemaphore(win.CreateSemaphoreW(nil, initial_count, max_count, nil))
}
incrementSemaphore :: proc(semaphore: OsSemaphore) {
	win.ReleaseSemaphore(win.HANDLE(semaphore), 1, nil)
}
waitForSemaphore :: proc(semaphore: OsSemaphore) {
	win.WaitForSingleObject(win.HANDLE(semaphore), win.INFINITE)
}
