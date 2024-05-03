package lib_init
import "../math"

// createThread :: proc(stack_size: uint, thread_proc: proc "stdcall" (data: rawptr) -> u32, param: rawptr)
// OsSemaphore :: ...
// createSemaphore :: proc(max_count: i32) -> OsSemaphore
// incrementSemaphore :: proc(semaphore: OsSemaphore)
// waitForSemaphore :: proc(semaphore: OsSemaphore)

ThreadInfo :: struct {
	thread_index: int, // TODO: throw this in context.user_index?
}
threadProc :: proc "stdcall" (thread_info: rawptr) -> u32 {
	thread_info := cast(^ThreadInfo)thread_info
	context = defaultContext() // TODO: pass in thread_index?
	for {
		if doNextWorkItem(&work_queue) {
			waitForSemaphore(work_queue.semaphore)
		}
	}
}
initThreads :: proc() {
	core_count := 2 // TODO: get cpu core counts
	background_threads := core_count - 1
	work_queue = {
		semaphore = createSemaphore(i32(background_threads)),
	}
	i: int
	for i = 1; i < background_threads + 1; i += 1 {
		info := new(ThreadInfo)
		info^ = ThreadInfo {
			thread_index = i,
		}
		createThread(math.kibiBytes(64), threadProc, info)
	}
}
