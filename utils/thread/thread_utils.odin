package thread_utils
import "../math"
import "base:intrinsics"

// lock group
LockGroup :: distinct ^u64
getLock :: proc(lock_group: LockGroup, lock_index: int) {
	for {
		old_value := intrinsics.atomic_load(lock_group)
		new_value := math.setBit(old_value, u64(lock_index), 1)
		value, ok := intrinsics.atomic_compare_exchange_strong(lock_group, old_value, new_value)
		if ok {break}
	}
}
releaseLock :: proc(lock_group: LockGroup, lock_index: int) {
	for {
		old_value := intrinsics.atomic_load(lock_group)
		new_value := math.setBit(old_value, u64(lock_index), 0)
		value, ok := intrinsics.atomic_compare_exchange_strong(lock_group, old_value, new_value)
		if ok {break}
	}
}

// mutex
TicketMutex :: struct {
	next, serving: u32,
}
getMutexTicket :: proc(mutex: ^TicketMutex) -> u32 {
	return intrinsics.atomic_add(&mutex.next, 1)
}
getMutexTicketUpTo :: proc(mutex: ^TicketMutex, end: u32) -> (ticket: u32, ok: bool) {
	value := mutex.next
	if value != end {
		value_got := intrinsics.atomic_compare_exchange_weak(&mutex.next, value, value + 1)
		return value, value_got == value
	}
	return value, false
}
getMutex :: proc(mutex: ^TicketMutex) {
	ticket := getMutexTicket(mutex)
	for intrinsics.atomic_load(&mutex.serving) != ticket {}
}
releaseMutex :: proc(mutex: ^TicketMutex) {
	intrinsics.atomic_add(&mutex.serving, 1)
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
