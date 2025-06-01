package test_utils
import "core:fmt"
import "core:strings"
import "core:testing"
import "core:time"

Case :: struct($K: typeid, $V: typeid) {
	key:      K,
	expected: V,
}
TestContext :: struct {
	t:      ^testing.T,
	failed: bool,
}
test_context: TestContext
start_test :: proc(t: ^testing.T) {
	time.sleep(100 * time.Millisecond) // NOTE: fix printing
	test_context.t = t
}
expect :: proc(condition: bool, format: string, args: ..any, loc := #caller_location) {
	if !condition {
		test_context.failed = true
		testing.expectf(test_context.t, condition, format, ..args, loc = loc)
	}
}
end_test :: proc() {
	fmt.printfln("\n\n", flush = true) // NOTE: fix printing
}
