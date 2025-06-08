package threads_utils
import "../math"
import "../os"
import "base:intrinsics"
import "core:fmt"
import "core:testing"
import "core:time"

/* A threading api needs to support:
	- adding tasks
	- waiting until tasks are complete
	- prioritizing tasks that needs to be done immediately (throughput)
*/

// globals
work_queue: WorkQueue

// types
WorkQueue :: struct {
	buffer:          [32]Work,
	pending_count:   int,
	completed_count: int,
}
Work :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
	state:     WorkItemState,
}
#assert(size_of(Work) == 24)
WorkItemState :: enum {
	Empty,
	Writing,
	Written,
	Reading,
}

// procedures
init_thread_pool :: proc() {
	thread_index_start := total_thread_count
	thread_index_end := os.info.logical_core_count
	new_thread_count := thread_index_end - thread_index_start

	semaphore = _create_semaphore(i32(max(0, new_thread_count)))
	for i in thread_index_start ..< thread_index_end {
		thread_infos[i].os_info = launch_os_thread(64 * math.KIBI_BYTES, work_queue_thread_proc, &thread_infos[i - 1])
	}
}
work_queue_thread_proc :: proc "stdcall" (thread_info: rawptr) -> u32 {
	thread_info := cast(^ThreadInfo)thread_info
	context = thread_context(int(thread_info.index))
	for {
		intrinsics.atomic_add(&running_thread_count, 1)
		join_queue(&work_queue)
		intrinsics.atomic_add(&running_thread_count, -1)
		_wait_for_semaphore()
	}
}
append_work :: proc(queue: ^WorkQueue, work: Work) {
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
				_resume_thread()
				return
			}
		}
		do_next_work(queue)
	}
}
do_next_work :: proc(queue: ^WorkQueue) -> (_continue: bool) {
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
join_queue :: #force_inline proc(queue: ^WorkQueue) {
	for do_next_work(queue) {
		//fmt.printfln("queue: %v", queue)
	}
}
