// odin test utils/math
package lib_math
import "../test"
import "base:intrinsics"
import "core:fmt"
import "core:testing"

@(test)
test_clz :: proc(t: ^testing.T) {
	for test_case in ([]test.Case(u64, u64){{0, 64}, {1, 63}, {2, 62}, {3, 62}}) {
		using test_case
		got := clz(key)
		testing.expectf(t, got == expected, "clz(%v): %v", key, got)
	}
	for test_case in ([]test.Case(u8, u8){{0, 8}, {1, 7}, {2, 6}, {3, 6}}) {
		using test_case
		got := clz(key)
		testing.expectf(t, got == expected, "clz(%v): %v", key, got)
	}
}

@(test)
math_log2_floor :: proc(t: ^testing.T) {
	test_cases := []test.Case(uint, uint) {
		{0, 0},
		{1, 0},
		{2, 1},
		{3, 1},
		{4, 2},
		{7, 2},
		{4096, 12},
	}
	for test_case in test_cases {
		using test_case
		testing.expectf(
			t,
			log2_floor(key) == expected,
			"log2_ceil(%v): %v, expected: %v",
			key,
			log2_floor(key),
			expected,
		)
	}
}
@(test)
test_log2_ceil :: proc(t: ^testing.T) {
	for test_case in ([]test.Case(u64, u64) {
			{0, 0},
			{1, 0},
			{2, 1},
			{3, 2},
			{4, 2},
			{7, 3},
			{4096, 12},
		}) {
		using test_case
		testing.expectf(
			t,
			log2_ceil(key) == expected,
			"log2_ceil(%v): %v, expected: %v",
			key,
			log2_ceil(key),
			expected,
		)
	}
}
