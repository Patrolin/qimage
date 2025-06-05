package threads_utils
import "../math"
import "base:intrinsics"

// mutex
Lock :: distinct bool
get_lock_or_error :: #force_inline proc "contextless" (lock: ^Lock) -> (ok: bool) {
	old_value := intrinsics.atomic_exchange(lock, true)
	return old_value == false
}
get_lock :: #force_inline proc "contextless" (lock: ^Lock) {
	for {
		old_value := intrinsics.atomic_exchange(lock, true)
		if intrinsics.expect(old_value == false, true) {return}
		intrinsics.cpu_relax()
	}
	read_write_fence()
}
release_lock :: #force_inline proc "contextless" (lock: ^Lock) {
	intrinsics.atomic_store(lock, false)
}
read_write_fence :: #force_inline proc "contextless" () {
	intrinsics.atomic_thread_fence(.Seq_Cst)
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
