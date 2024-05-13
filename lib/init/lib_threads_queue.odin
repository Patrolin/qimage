package lib_init
import "core:fmt"
import "core:intrinsics"

work_queue: WorkQueue
WorkQueue :: struct {
	semaphore:                                             OsSemaphore,
	submission_count, in_progress_count, completion_count: int,
	items:                                                 [32]WorkItem,
}
WorkItem :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
}

// NOTE: single producer
addWorkItem :: proc(queue: ^WorkQueue, work: WorkItem) {
	if (queue.submission_count - queue.in_progress_count) >= len(queue.items) {
		doNextWorkItem(queue)
	}
	queue.items[queue.submission_count % len(queue.items)] = work
	intrinsics.atomic_add(&queue.submission_count, 1)
}
doNextWorkItem :: proc(queue: ^WorkQueue) -> (can_sleep: bool) {
	in_progress_count_a := queue.in_progress_count
	if in_progress_count_a < work_queue.submission_count {
		in_progress_count_b := intrinsics.atomic_compare_exchange_weak(
			&queue.in_progress_count,
			in_progress_count_a,
			in_progress_count_a + 1,
		)
		if in_progress_count_b == in_progress_count_a {
			work := queue.items[in_progress_count_a % len(queue.items)]
			work.procedure(work.data)
			intrinsics.atomic_add(&queue.completion_count, 1)
		}
	}
	return work_queue.completion_count == intrinsics.atomic_load(&work_queue.submission_count)
}
joinFrontQueue :: proc(queue: ^WorkQueue) {
	for !doNextWorkItem(queue) {}
}
