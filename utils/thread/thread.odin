package thread_utils
import "../math"
import "base:intrinsics"

// mutex
Mutex :: distinct bool
getMutex :: proc(mutex: ^Mutex) {
	for {
		old_value := intrinsics.atomic_exchange(mutex, true)
		if intrinsics.expect(old_value == false, true) {return}
	}
}
releaseMutex :: proc(mutex: ^Mutex) {
	intrinsics.atomic_store(mutex, false)
}
// thread info
_semaphore: OsSemaphore
thread_count := 1
running_thread_count := 1 // TODO: delete this?
pending_async_files := 0
ThreadInfo :: struct {
	thread_id: OsThreadId,
	index:     u32,
}
#assert(size_of(ThreadInfo) <= 16)
