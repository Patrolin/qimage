package lib_os
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
	context = defaultContext(false)
	context.user_index = thread_info.thread_index
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

// mutex
TicketMutex :: struct {
	next, serving: u32,
}
getMutexTicket :: proc(mutex: ^TicketMutex) -> u32 {
	return intrinsics.atomic_add(&mutex.next, 1)
}
getMutexTicketUntil :: proc(mutex: ^TicketMutex, max: u32) -> (ticket: u32, ok: bool) {
	value := mutex.next
	if value != max {
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

// queue
work_queue: WorkQueue
WorkQueue :: struct {
	semaphore:               OsSemaphore,
	write_mutex, read_mutex: TicketMutex,
	completed_count:         u32,
	items:                   [32]WorkItem,
}
WorkItem :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
}
addWorkItem :: proc(queue: ^WorkQueue, work: WorkItem) {
	ticket := getMutexTicket(&queue.write_mutex)
	for {
		written_count := intrinsics.atomic_load(&queue.write_mutex.serving)
		read_count := intrinsics.atomic_load(&queue.read_mutex.serving)
		open_slots := len(queue.items) + read_count - written_count // NOTE: len: 8, read: 99, written: 100 -> open: 8+99-100 = 7-0 = 7
		if open_slots > 0 && written_count == ticket {
			queue.items[ticket % len(queue.items)] = work
			releaseMutex(&queue.write_mutex)
			incrementSemaphore(queue.semaphore)
			break
		}
		doNextWorkItem(queue)
	}
}
doNextWorkItem :: proc(queue: ^WorkQueue) -> (_continue: bool) {
	ticket, ok := getMutexTicketUntil(&queue.read_mutex, queue.write_mutex.serving)
	if ok {
		work := queue.items[ticket % len(queue.items)]
		releaseMutex(&queue.read_mutex)
		work.procedure(work.data)
		free_all(allocator = context.temp_allocator)
		intrinsics.atomic_add(&queue.completed_count, 1)
	}
	writing_count := queue.write_mutex.next
	return queue.completed_count != writing_count
}
joinQueue :: proc(queue: ^WorkQueue) {
	for doNextWorkItem(queue) {
		//fmt.printfln("wm: %v, rm: %v", work_queue.write_mutex, work_queue.read_mutex)
	}
}
