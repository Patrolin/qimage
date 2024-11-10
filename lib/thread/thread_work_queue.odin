package thread_lib
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
import thread_utils "../../utils/thread"
import "base:intrinsics"
import "core:fmt"
import "core:testing"

/* A threading api needs to support:
	- adding work items
	- waiting until work items are complete
	- prioritizing work items that needs to be done immediately (throughput)
	- giving each async work item a chance to start (I/O latency)
*/

// threads
threadProc :: proc "stdcall" (thread_info: rawptr) -> u32 {
	thread_info := cast(^ThreadInfo)thread_info
	context = alloc.defaultContext(true)
	context.user_index = int(thread_info.index)
	for {
		intrinsics.atomic_add(&thread_utils.running_thread_count, 1)
		for doNextWorkItem(&work_queue) {}
		intrinsics.atomic_add(&thread_utils.running_thread_count, -1)
		thread_utils._waitForSemaphore()
	}
}
ThreadInfo :: thread_utils.ThreadInfo
initThreads :: proc() -> []ThreadInfo {
	assert(thread_utils.thread_count == 1)
	thread_count := os.info.logical_core_count - 1
	thread_utils._semaphore = thread_utils._createSemaphore(i32(thread_count))
	thread_infos := make([]ThreadInfo, thread_count)
	intrinsics.atomic_store(&thread_utils.thread_count, thread_count)
	for i in 1 ..= thread_count {
		thread_infos[i - 1] = ThreadInfo {
			thread_id = thread_utils._createThread(
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
	write_mutex, read_mutex: thread_utils.TicketMutex,
	completed_count:         u32,
	items:                   [32]WorkItem,
}
WorkItem :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
}
launchThread :: proc(queue: ^WorkQueue, work: WorkItem) {
	for {
		read_count := intrinsics.atomic_load(&queue.read_mutex.finished)
		ticket, ok := thread_utils.getMutexTicketUntil(
			&queue.write_mutex,
			read_count + len(queue.items),
		)
		if ok {
			queue.items[ticket % len(queue.items)] = work
			thread_utils.releaseMutex(&queue.write_mutex)
			thread_utils.launchThread()
			return
		}
		doNextWorkItem(queue)
	}
}
doNextWorkItem :: proc(queue: ^WorkQueue) -> (_continue: bool) {
	ticket, ok := thread_utils.getMutexTicketUntil(&queue.read_mutex, queue.write_mutex.finished)
	if ok {
		work := queue.items[ticket % len(queue.items)]
		thread_utils.releaseMutex(&queue.read_mutex)
		work.procedure(work.data)
		free_all(allocator = context.temp_allocator)
		intrinsics.atomic_add(&queue.completed_count, 1)
	} // TODO!: handle thread_utils.pending_async_files?
	writing_count := queue.write_mutex.next
	return queue.completed_count != writing_count
}
joinQueue :: proc(queue: ^WorkQueue) {
	for doNextWorkItem(queue) {
		//fmt.printfln("wm: %v, rm: %v", work_queue.write_mutex, work_queue.read_mutex)
	}
}
// odin test lib/thread
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
