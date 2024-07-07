package lib_thread_utils
import "base:intrinsics"

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
