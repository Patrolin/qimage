package threads_utils
import "../math"
import "../os"
import "base:intrinsics"
import "core:fmt"
import "core:testing"
import "core:time"

// globals
work_queue: WorkQueue

// types
WorkQueue :: distinct WaitFreeQueue
Work :: struct {
	procedure: proc(_: rawptr),
	data:      rawptr,
}
#assert(size_of(Work) == 16)

// procedures
init_thread_pool :: proc(thread_proc: ThreadProc) {
	thread_index_start := total_thread_count
	thread_index_end := os.info.logical_core_count
	new_thread_count := thread_index_end - thread_index_start

	semaphore = _create_semaphore(i32(max(0, new_thread_count)))
	for i in thread_index_start ..< thread_index_end {
		thread_infos[i].os_info = launch_os_thread(64 * math.KIBI_BYTES, thread_proc, &thread_infos[i - 1])
	}
}
work_queue_thread_proc :: proc "std" (thread_info: rawptr) -> u32 {
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
	work := work
	queue_append((^WaitFreeQueue)(queue), &work)
	_resume_thread()
}
do_next_work :: proc(queue: ^WorkQueue) -> (_continue: bool) {
	work: Work
	ok := queue_read((^WaitFreeQueue)(queue), &work)
	if ok {work.procedure(work.data)}
	return ok
}
join_queue :: #force_inline proc(queue: ^WorkQueue) {
	for do_next_work(queue) {
		//fmt.printfln("queue: %v", queue)
	}
}
