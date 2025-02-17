package thread_lib
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
import thread_utils "../../utils/thread"
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
				64 * math.KIBI_BYTES,
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
			prev_state := intrinsics.atomic_compare_exchange_weak(
				&item.state,
				WorkItemState.Empty,
				WorkItemState.Writing,
			)
			if prev_state == WorkItemState.Empty {
				item^ = work
				intrinsics.atomic_store(&item.state, WorkItemState.Written)
				thread_utils.launchThread()
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
		prev_state := intrinsics.atomic_compare_exchange_weak(
			&item.state,
			WorkItemState.Written,
			WorkItemState.Reading,
		)
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
// odin test lib/thread
@(test)
tests_workQueue :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, 1 * time.Second)
	checkWorkQueue :: proc(data: rawptr) {
		//fmt.printfln("thread %v: checkWorkQueue", context.user_index)
		data := (^int)(data)
		intrinsics.atomic_add(data, -1)
	}
	checkWorkQueue2 :: proc(data: rawptr) {
		//fmt.printfln("thread %v: checkWorkQueue2", context.user_index)
		data := (^int)(data)
		intrinsics.atomic_add(data, -2)
	}
	os.initInfo()
	context = alloc.defaultContext(0)
	//thread_infos := initThreads()
	N := 200
	checksum := N * 4
	for i in 0 ..< N {
		launchThread(&work_queue, WorkItem{procedure = checkWorkQueue, data = &checksum})
		launchThread(&work_queue, WorkItem{procedure = checkWorkQueue, data = &checksum})
		launchThread(&work_queue, WorkItem{procedure = checkWorkQueue2, data = &checksum})
	}
	joinQueue(&work_queue)
	got_checksum := intrinsics.atomic_load(&checksum)
	testing.expectf(t, got_checksum == 0, "checksum should be 0, got: %v", got_checksum)
}
