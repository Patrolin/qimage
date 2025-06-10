package test_threads_utils
import "../../../utils/alloc"
import "../../../utils/os"
import "../../../utils/test"
import "../../../utils/threads"
import "base:intrinsics"
import "core:fmt"
import "core:testing"
import "core:time"

@(test)
tests_work_queue :: proc(t: ^testing.T) {
	test.start_test(t)
	test.set_fail_timeout(time.Second)
	context = threads.init()
	threads.init_thread_pool(threads.work_queue_thread_proc)

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
	N := 200
	checksum := N * 4
	for i in 0 ..< N {
		threads.append_work(&threads.work_queue, threads.Work{procedure = checkWorkQueue, data = &checksum})
		threads.append_work(&threads.work_queue, threads.Work{procedure = checkWorkQueue, data = &checksum})
		threads.append_work(&threads.work_queue, threads.Work{procedure = checkWorkQueue2, data = &checksum})
	}
	threads.join_queue(&threads.work_queue)
	got_checksum := intrinsics.atomic_load(&checksum)
	test.expectf(got_checksum == 0, "checksum should be 0, got: %v", got_checksum)

	threads.free_all_for_tests()
	test.end_test()
}
