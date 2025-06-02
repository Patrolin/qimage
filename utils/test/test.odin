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
expectf :: #force_inline proc(condition: bool, format: string, args: ..any, loc := #caller_location) {
	if ODIN_TEST {
		testing.expectf(test_context.t, condition, format, ..args, loc = loc)
	} else {
		fmt.assertf(condition, format, ..args, loc = loc)
	}
}
expect_case :: proc(test_case: Case($K, $V), got: V, expression := #caller_expression) {
	buffer: [64]u8
	sb := strings.builder_from_slice(buffer[:])
	key_string := fmt.sbprint(&sb, test_case.key)

	subexpression := expression[len("test.expect_case(test_case, "):len(expression) - len(")")]
	formatted_subexpression, _was_allocation := strings.replace_all(subexpression, "key", key_string, allocator = context.temp_allocator)

	expectf(got == test_case.expected, "%v: %v, expected: %v", formatted_subexpression, got, test_case.expected)
}
end_test :: proc() {
	fmt.print("\n\n", flush = true) // NOTE: fix printing
}
