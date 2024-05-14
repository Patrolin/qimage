package lib_init
import "core:fmt"
import "core:intrinsics"

work_queue: WorkQueue
WorkQueue :: struct {
	semaphore:                                                         OsSemaphore,
	index_to_write, submission_count, index_to_read, completion_count: int,
	items:                                                             [32]WorkItem,
}
WorkItem :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
}

addWorkItem :: proc(queue: ^WorkQueue, work: WorkItem) {
	for {
		index_to_write_old := intrinsics.atomic_load(&queue.index_to_write)
		if (index_to_write_old - intrinsics.atomic_load(&queue.index_to_read)) < len(queue.items) {
			index_to_write := intrinsics.atomic_compare_exchange_weak(
				&queue.index_to_write,
				index_to_write_old,
				index_to_write_old + 1,
			)
			if index_to_write == index_to_write_old {
				queue.items[index_to_write % len(queue.items)] = work
				intrinsics.atomic_add(&queue.submission_count, 1)
				incrementSemaphore(queue.semaphore)
				break
			}
		}
		doNextWorkItem(queue)
	}
}
doNextWorkItem :: proc(queue: ^WorkQueue) -> (_continue: bool) {
	index_to_read_old := queue.index_to_read
	if index_to_read_old < work_queue.submission_count {
		index_to_read_got := intrinsics.atomic_compare_exchange_weak(
			&queue.index_to_read,
			index_to_read_old,
			index_to_read_old + 1,
		)
		if index_to_read_got == index_to_read_old {
			work := queue.items[index_to_read_old % len(queue.items)]
			work.procedure(work.data)
			intrinsics.atomic_add(&queue.completion_count, 1)
		}
	}
	return work_queue.completion_count != work_queue.index_to_write
}
joinQueue :: proc(queue: ^WorkQueue) {
	/*a, b, c := queue.submission_count, queue.in_progress_count, queue.completion_count
	new_a, new_b, new_c := a, b, c*/
	for doNextWorkItem(queue) {
		/*new_a, new_b, new_c =
			intrinsics.atomic_load(&queue.submission_count),
			intrinsics.atomic_load(&queue.in_progress_count),
			intrinsics.atomic_load(&queue.completion_count)
		if new_a != a || new_b != b || new_c != c {
			a, b, c = new_a, new_b, new_c
			fmt.printfln("vals: %v, %v, %v", a, b, c)
		}*/
	}
	/*new_a, new_b, new_c =
		intrinsics.atomic_load(&queue.submission_count),
		intrinsics.atomic_load(&queue.in_progress_count),
		intrinsics.atomic_load(&queue.completion_count)
	if new_a != a || new_b != b || new_c != c {
		a, b, c = new_a, new_b, new_c
		fmt.printfln("vals: %v, %v, %v", a, b, c)
	}*/
}
