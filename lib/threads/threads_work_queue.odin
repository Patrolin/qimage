package threads_lib
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
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
	context = alloc.thread_context(int(thread_info.index))
	for {
		intrinsics.atomic_add(&running_thread_count, 1)
		for doNextWorkItem(&work_queue) {}
		intrinsics.atomic_add(&running_thread_count, -1)
		_waitForSemaphore()
	}
}
init_thread_pool :: proc() -> []ThreadInfo {
	threads_to_launch_count := os.info.logical_core_count - running_thread_count
	assert(threads_to_launch_count > 0)
	_semaphore = _createSemaphore(i32(threads_to_launch_count))
	thread_infos := make([]ThreadInfo, threads_to_launch_count)
	intrinsics.atomic_add(&running_thread_count, threads_to_launch_count)
	for i in running_thread_count ..= threads_to_launch_count {
		thread_infos[i - 1] = ThreadInfo {
			os_info = launch_os_thread(64 * math.KIBI_BYTES, threadProc, &thread_infos[i - 1]),
			index   = u32(i),
		}
	}
	return thread_infos
}

// work queue
work_queue: WorkQueue
WorkQueue :: struct {
	buffer:          [32]WorkItem,
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
		slot_index := context.user_index // start at a random number
		slot_step := slot_index | 1 // NOTE: len(items) must be a power of two
		for i := 0; i < len(queue.buffer); i += 1 {
			slot_index = (slot_index + slot_step) & len(queue.buffer) // NOTE: len(items) must be a power of two
			item := &queue.buffer[slot_index]
			prev_state := intrinsics.atomic_compare_exchange_weak(&item.state, WorkItemState.Empty, WorkItemState.Writing)
			if prev_state == WorkItemState.Empty {
				item^ = work
				intrinsics.atomic_store(&item.state, WorkItemState.Written)
				_resumeThread()
				return
			}
		}
		doNextWorkItem(queue)
	}
}
doNextWorkItem :: proc(queue: ^WorkQueue) -> (_continue: bool) {
	start_index := context.user_index // random number
	slot_step := start_index | 1 // NOTE: len(items) must be a power of two
	for i := 0; i < len(queue.buffer); i += 1 {
		slot_index := start_index + i * slot_step
		item := &queue.buffer[slot_index & (len(queue.buffer) - 1)]
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
