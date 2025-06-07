package test_threads
import "../../lib/threads"
import "../../utils/alloc"
import "../../utils/os"
import "../../utils/test"
import "base:intrinsics"
import "core:testing"
import "core:time"

@(test)
tests_workQueue :: proc(t: ^testing.T) {
	test.start_test(t)
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
	context = alloc.init()
	//thread_infos := initThreads()
	N := 200
	checksum := N * 4
	for i in 0 ..< N {
		threads.launchThread(&threads.work_queue, threads.WorkItem{procedure = checkWorkQueue, data = &checksum})
		threads.launchThread(&threads.work_queue, threads.WorkItem{procedure = checkWorkQueue, data = &checksum})
		threads.launchThread(&threads.work_queue, threads.WorkItem{procedure = checkWorkQueue2, data = &checksum})
	}
	threads.joinQueue(&threads.work_queue)
	got_checksum := intrinsics.atomic_load(&checksum)
	test.expectf(got_checksum == 0, "checksum should be 0, got: %v", got_checksum)

	alloc.free_all_for_tests()
	test.end_test()
}
