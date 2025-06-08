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
	t: ^testing.T,
}

test_context: TestContext

start_test :: proc(t: ^testing.T) {
	time.sleep(100 * time.Millisecond) // NOTE: fix printing
	test_context.t = t
}
set_fail_timeout :: proc(duration: time.Duration) {
	testing.set_fail_timeout(test_context.t, duration)
}

expect :: #force_inline proc(condition: bool, message := "", loc := #caller_location) {
	when ODIN_TEST {
		testing.expect(test_context.t, condition, message, loc = loc)
	} else {
		assert(condition, message, loc = loc)
	}
}
expectf :: #force_inline proc(condition: bool, format: string, args: ..any, loc := #caller_location) {
	when ODIN_TEST {
		testing.expectf(test_context.t, condition, format, ..args, loc = loc)
	} else {
		fmt.assertf(condition, format, ..args, loc = loc)
	}
}
expect_case :: proc(test_case: Case($K, $V), got: V, got_expression := #caller_expression(got)) {
	buffer: [64]u8
	sb := strings.builder_from_slice(buffer[:])
	key_string := fmt.sbprint(&sb, test_case.key)

	expectf(got == test_case.expected, "%v: %v, expected: %v", got_expression, got, test_case.expected)
}
expect_was_allocated :: proc(ptr: ^int, name: string, value: int, loc := #caller_location) {
	expect(ptr != nil, "Failed was_allocated - failed to allocate", loc = loc)
	expectf(ptr^ == 0, "Failed was_allocated - should start zeroed", loc = loc)
	ptr^ = value
	expectf(ptr^ == value, "Failed was_allocated - failed to write", loc = loc)
}
expect_still_allocated :: proc(ptr: ^int, name: string, value: int, loc := #caller_location) {
	expectf(ptr != nil && ptr^ == value, "Failed still_allocated, %v: %v at %v", name, ptr^, ptr, loc = loc)
}

end_test :: proc() {
	fmt.print("\n\n", flush = true) // NOTE: fix printing
}
