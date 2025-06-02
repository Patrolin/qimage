package test_time
import "../../utils/os"
import "../../utils/test"
import "../../utils/time"
import "core:fmt"
import "core:testing"

@(test)
test_sleep_ns :: proc(t: ^testing.T) {
	test.start_test(t)
	testing.set_fail_timeout(t, 1 * time.SECOND)

	os.init()
	// TODO: test random amounts to sleep?
	for i := 0; i < 5; i += 1 {
		time.sleep_ns(4 * time.MILLISECOND)
	}

	test.end_test()
}
