package lib_threads
import "../math"
import "base:intrinsics"
import win "core:sys/windows"

OsSemaphore :: distinct win.HANDLE
OsThreadId :: struct {
	id:     u32,
	handle: win.HANDLE,
}
createThread :: proc(
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

createSemaphore :: proc(max_count: i32) -> OsSemaphore {
	//fmt.printfln("createSemaphore: %v", max_count)
	initial_count: i32 = 0
	return OsSemaphore(win.CreateSemaphoreW(nil, initial_count, max_count, nil))
}
signalSemaphore :: proc(semaphore: OsSemaphore) {
	//fmt.printfln("incrementSemaphore")
	win.ReleaseSemaphore(win.HANDLE(semaphore), 1, nil)
}
waitForSemaphore :: proc(semaphore: OsSemaphore) {
	//fmt.printfln("thread %v: sleep", context.user_index)
	win.WaitForSingleObject(win.HANDLE(semaphore), win.INFINITE)
}
