package lib_threads
import "../alloc"
import "../math"
import "../os"
import "./_threads"
import "base:intrinsics"
import "core:fmt"
import "core:testing"

/* A threading api needs to support:
	- adding work items
	- waiting until work items are complete
	- prioritizing work items that needs to be done immediately (throughput)
	- giving each async work item a chance to start (I/O latency)
*/
TicketMutex :: _threads.TicketMutex
getMutexTicket :: _threads.getMutexTicket
getMutexTicketUpTo :: _threads.getMutexTicketUpTo
getMutex :: _threads.getMutex
releaseMutex :: _threads.releaseMutex
ThreadInfo :: _threads.ThreadInfo
OsThreadId :: _threads.OsThreadId

// threads
threadProc :: proc "stdcall" (thread_info: rawptr) -> u32 {
	thread_info := cast(^ThreadInfo)thread_info
	context = alloc.defaultContext(true)
	context.user_index = int(thread_info.index)
	for {
		intrinsics.atomic_add(&_threads.running_thread_count, 1)
		for doNextWorkItem(&work_queue) {}
		intrinsics.atomic_add(&_threads.running_thread_count, -1)
		_threads._waitForSemaphore()
	}
}
initThreads :: proc() -> []ThreadInfo {
	thread_count := os.info.logical_core_count - 1
	_threads._semaphore = _threads._createSemaphore(i32(thread_count))
	thread_infos := make([]ThreadInfo, thread_count)
	for i in 1 ..= thread_count {
		thread_infos[i - 1] = ThreadInfo {
			thread_id = _threads._createThread(
				math.kibiBytes(64),
				threadProc,
				&thread_infos[i - 1],
			),
			index     = u32(i),
		}
	}
	return thread_infos
}

// work queue
work_queue: WorkQueue
WorkQueue :: struct {
	write_mutex, read_mutex: TicketMutex,
	completed_count:         u32,
	items:                   [32]WorkItem,
}
WorkItem :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
}
launchThread_withWork :: proc(queue: ^WorkQueue, work: WorkItem) {
	ticket := getMutexTicket(&queue.write_mutex)
	for {
		written_count := intrinsics.atomic_load(&queue.write_mutex.serving)
		read_count := intrinsics.atomic_load(&queue.read_mutex.serving)
		open_slots := read_count - written_count + len(queue.items) // NOTE: this handles overflows
		if open_slots > 0 && written_count == ticket {
			queue.items[ticket % len(queue.items)] = work
			releaseMutex(&queue.write_mutex)
			_threads.launchThread()
			break
		}
		doNextWorkItem(queue)
	}
}
launchThread :: proc {
	_threads.launchThread,
	launchThread_withWork,
}
doNextWorkItem :: proc(queue: ^WorkQueue) -> (_continue: bool) {
	ticket, ok := getMutexTicketUpTo(&queue.read_mutex, queue.write_mutex.serving)
	if ok {
		work := queue.items[ticket % len(queue.items)]
		releaseMutex(&queue.read_mutex)
		work.procedure(work.data)
		free_all(allocator = context.temp_allocator)
		intrinsics.atomic_add(&queue.completed_count, 1)
	} // TODO!: handle thread_utils.pending_async_files
	writing_count := queue.write_mutex.next
	return queue.completed_count != writing_count
}
joinQueue :: proc(queue: ^WorkQueue) {
	for doNextWorkItem(queue) {
		//fmt.printfln("wm: %v, rm: %v", work_queue.write_mutex, work_queue.read_mutex)
	}
}
// odin test lib/threads
@(test)
tests_workQueue :: proc(t: ^testing.T) {
	checkWorkQueue :: proc(data: rawptr) {
		//fmt.printfln("thread %v: checkWorkQueue", context.user_index)
		data := (^int)(data)
		intrinsics.atomic_add(data, -1)
	}
	os.initInfo()
	context = alloc.defaultContext()
	thread_infos := initThreads()
	total_count := 200
	checksum := total_count
	for i in 0 ..< total_count {
		launchThread(&work_queue, WorkItem{procedure = checkWorkQueue, data = &checksum})
	}
	joinQueue(&work_queue)
	got_checksum := intrinsics.atomic_load(&checksum)
	testing.expectf(t, got_checksum == 0, "checksum should be 0, got: %v", got_checksum)
}
