package lib_test
import "base:runtime"
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
get_context :: proc(t: ^testing.T) -> runtime.Context {
	test_context := new(TestContext)
	test_context.t = t
	ctx := context
	ctx.user_ptr = test_context
	return ctx
}
expect :: proc(condition: bool, format: string, args: ..any, loc := #caller_location) {
	if !condition {
		test_context := (^TestContext)(context.user_ptr)
		test_context.failed = true
		testing.expectf(test_context.t, condition, format, ..args, loc = loc)
	}
}
free_context :: proc() {
	free((^TestContext)(context.user_ptr))
}
