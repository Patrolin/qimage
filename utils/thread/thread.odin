package thread_utils
import "../math"
import "base:intrinsics"

// mutex
TicketMutex :: struct {
	next, finished: u32,
}
getMutexTicketUntil :: proc(mutex: ^TicketMutex, end: u32) -> (ticket: u32, ok: bool) {
	value := mutex.next
	if value != end {
		value_got := intrinsics.atomic_compare_exchange_weak(&mutex.next, value, value + 1)
		return value, value_got == value
	}
	return value, false
}
getMutex :: proc(mutex: ^TicketMutex) { 	// TODO: give each thread its own allocator instead
	ticket := intrinsics.atomic_add(&mutex.next, 1)
	for intrinsics.atomic_load(&mutex.finished) != ticket {}
}
releaseMutex :: proc(mutex: ^TicketMutex) {
	intrinsics.atomic_add(&mutex.finished, 1)
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
