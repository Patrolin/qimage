package lib_init
import "../math"
import "core:fmt"
import "core:intrinsics"

running_thread_count := 1 // TODO: remove this?
ThreadInfo :: struct {
	thread_id:    OsThreadId,
	thread_index: int,
}
threadProc :: proc "stdcall" (thread_info: rawptr) -> u32 {
	thread_info := cast(^ThreadInfo)thread_info
	context = defaultContext()
	context.user_index = thread_info.thread_index
	ctx := context
	for {
		intrinsics.atomic_add(&running_thread_count, 1)
		for doNextWorkItem(&work_queue) {}
		intrinsics.atomic_add(&running_thread_count, -1)
		waitForSemaphore(work_queue.semaphore)
	}
}
initThreads :: proc() -> []ThreadInfo {
	thread_count := os_info.logical_core_count - 1
	work_queue = {
		semaphore = createSemaphore(i32(thread_count)),
	}
	thread_infos := make([]ThreadInfo, thread_count)
	for i in 1 ..= thread_count {
		thread_infos[i - 1] = ThreadInfo {
			thread_id    = createThread(math.kibiBytes(64), threadProc, &thread_infos[i - 1]),
			thread_index = i,
		}
	}
	return thread_infos
}
