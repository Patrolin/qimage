package lib_threads
import "../math"
import "base:intrinsics"
import win "core:sys/windows"

OsThreadId :: struct #packed {
	handle: win.HANDLE,
	id:     u32,
}
@(private)
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

@(private)
OsSemaphore :: distinct win.HANDLE
@(private)
createSemaphore :: proc(max_count: i32) -> OsSemaphore {
	//fmt.printfln("createSemaphore: %v", max_count)
	initial_count: i32 = 0
	return OsSemaphore(win.CreateSemaphoreW(nil, initial_count, max_count, nil))
}
@(private)
signalSemaphore :: proc(semaphore: OsSemaphore) {
	//fmt.printfln("incrementSemaphore")
	win.ReleaseSemaphore(win.HANDLE(semaphore), 1, nil)
}
@(private)
waitForSemaphore :: proc(semaphore: OsSemaphore) {
	//fmt.printfln("thread %v: sleep", context.user_index)
	win.WaitForSingleObject(win.HANDLE(semaphore), win.INFINITE)
}
