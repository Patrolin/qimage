package threads_lib

// thread info
_semaphore: OsSemaphore
thread_count := 1
running_thread_count := 1 // ?TODO: delete this
pending_async_files := 0
ThreadInfo :: struct {
	thread_id: OsThreadId,
	index:     u32,
}
#assert(size_of(ThreadInfo) <= 16)
