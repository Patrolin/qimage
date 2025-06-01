package threads_utils
import "../math"
import "base:intrinsics"

// mutex
Lock :: distinct bool
get_lock :: #force_inline proc "contextless" (lock: ^Lock) {
	for {
		old_value := intrinsics.atomic_exchange(lock, true)
		if intrinsics.expect(old_value == false, true) {return}
		intrinsics.cpu_relax()
	}
}
release_lock :: #force_inline proc "contextless" (lock: ^Lock) {
	intrinsics.atomic_store(lock, false)
}

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
