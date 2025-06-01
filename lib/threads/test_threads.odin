// odin test lib/threads
package threads_lib
import "../../utils/alloc"
import "../../utils/os"
import "base:intrinsics"
import "core:testing"
import "core:time"

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
