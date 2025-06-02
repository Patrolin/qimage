package threads_lib
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
import threads_utils "../../utils/threads"
import "base:intrinsics"
import "core:fmt"
import "core:testing"
import "core:time"

/* A threading api needs to support:
	- adding tasks
	- waiting until tasks are complete
	- prioritizing tasks that needs to be done immediately (throughput)
*/

// threads
threadProc :: proc "stdcall" (thread_info: rawptr) -> u32 {
	thread_info := cast(^ThreadInfo)thread_info
	context = alloc.defaultContext(int(thread_info.index))
	for {
		intrinsics.atomic_add(&threads_utils.running_thread_count, 1)
		for doNextWorkItem(&work_queue) {}
		intrinsics.atomic_add(&threads_utils.running_thread_count, -1)
		threads_utils._waitForSemaphore()
	}
}
ThreadInfo :: threads_utils.ThreadInfo
init_threads :: proc() -> []ThreadInfo {
	assert(threads_utils.thread_count == 1)
	thread_count := os.info.logical_core_count - 1
	threads_utils._semaphore = threads_utils._createSemaphore(i32(thread_count))
	thread_infos := make([]ThreadInfo, thread_count)
	intrinsics.atomic_store(&threads_utils.thread_count, thread_count)
	for i in 1 ..= thread_count {
		thread_infos[i - 1] = ThreadInfo {
			thread_id = threads_utils._createThread(64 * math.KIBI_BYTES, threadProc, &thread_infos[i - 1]),
			index     = u32(i),
		}
	}
	return thread_infos
}

// work queue
work_queue: WorkQueue
WorkQueue :: struct {
	items:           [32]WorkItem,
	pending_count:   int,
	completed_count: int,
}
WorkItem :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
	state:     WorkItemState,
}
#assert(size_of(WorkItem) == 24)
WorkItemState :: enum {
	Empty,
	Writing,
	Written,
	Reading,
}
launchThread :: proc(queue: ^WorkQueue, work: WorkItem) {
	intrinsics.atomic_add(&queue.pending_count, 1)
	for {
		start_index := context.user_index // random number
		slot_step := start_index | 1 // NOTE: len(items) must be a power of two
		for i := 0; i < len(queue.items); i += 1 {
			slot_index := start_index + i * slot_step
			item := &queue.items[slot_index]
			prev_state := intrinsics.atomic_compare_exchange_weak(&item.state, WorkItemState.Empty, WorkItemState.Writing)
			if prev_state == WorkItemState.Empty {
				item^ = work
				intrinsics.atomic_store(&item.state, WorkItemState.Written)
				threads_utils.launchThread()
				return
			}
		}
		doNextWorkItem(queue)
	}
}
doNextWorkItem :: proc(queue: ^WorkQueue) -> (_continue: bool) {
	start_index := context.user_index // random number
	slot_step := start_index | 1 // NOTE: len(items) must be a power of two
	for i := 0; i < len(queue.items); i += 1 {
		slot_index := start_index + i * slot_step
		item := &queue.items[slot_index & (len(queue.items) - 1)]
		prev_state := intrinsics.atomic_compare_exchange_weak(&item.state, WorkItemState.Written, WorkItemState.Reading)
		if prev_state == WorkItemState.Written {
			work := item^
			intrinsics.atomic_store(&item.state, WorkItemState.Empty)
			work.procedure(work.data)
			intrinsics.atomic_add(&queue.completed_count, 1)
		}
	}
	return queue.completed_count != queue.pending_count
}
joinQueue :: proc(queue: ^WorkQueue) {
	for doNextWorkItem(queue) {
		//fmt.printfln("queue: %v", queue)
	}
}
