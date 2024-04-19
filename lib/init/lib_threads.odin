package lib_init
import "../math"

// createThread :: proc(stack_size: uint, thread_proc: proc "stdcall" (data: rawptr) -> u32, param: rawptr)
// OsSemaphore :: ...
// createSemaphore :: proc(max_count: i32) -> OsSemaphore
// incrementSemaphore :: proc(semaphore: OsSemaphore)
// waitForSemaphore :: proc(semaphore: OsSemaphore)

ThreadInfo :: struct {
	queue:        ^WorkQueue,
	thread_index: int,
}
threadProc :: proc "stdcall" (thread_info: rawptr) -> u32 {
	thread_info := cast(^ThreadInfo)thread_info
	context = defaultContext() // TODO: pass in thread_index?
	for {
		for work := submitAndGetNextWorkItem(thread_info.queue, nil);
		    work != nil;
		    work = submitAndGetNextWorkItem(thread_info.queue, work) {
			work.function(work.data)
		}
		waitForSemaphore(thread_info.queue.semaphore)
	}
}
initThreads :: proc() {
	core_count := 2 // TODO: get cpu core counts
	MAX_BACKGROUND_THREADS :: 1
	work_queues.front = {
		semaphore = createSemaphore(i32(core_count - MAX_BACKGROUND_THREADS - 1)),
	}
	work_queues.background = {
		semaphore = createSemaphore(1),
	}
	i: int
	for i = 1; i < core_count - MAX_BACKGROUND_THREADS; i += 1 {
		info := new(ThreadInfo)
		info^ = ThreadInfo {
			queue        = &work_queues.front,
			thread_index = 1,
		}
		createThread(math.kibiBytes(64), threadProc, info)
	}
	for ; i < core_count; i += 1 {
		info := new(ThreadInfo)
		info^ = ThreadInfo {
			queue        = &work_queues.background,
			thread_index = 1,
		}
		createThread(math.kibiBytes(64), threadProc, info)
	}
}
