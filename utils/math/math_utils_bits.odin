package lib_math
import "../test"
import intrinsics "base:intrinsics"
import "core:fmt"
import bits "core:math/bits"
import "core:testing"

bytes :: distinct int
kibiBytes :: #force_inline proc "contextless" (v: int) -> bytes {return bytes(1024 * v)}
mebiBytes :: #force_inline proc "contextless" (v: int) -> bytes {return bytes(1024 * 1024 * v)}
gibiBytes :: #force_inline proc "contextless" (v: int) -> bytes {return bytes(
		1024 * 1024 * 1024 * v,
	)}
// return hash step for a power_of_two size hash table
hashStep :: #force_inline proc "contextless" (hash: $T) -> T {
	return hash | 1
}

clz :: bits.count_leading_zeros
ctz :: bits.count_trailing_zeros
countOnes :: bits.count_ones
countZeros :: bits.count_zeros

lowMask :: #force_inline proc "contextless" (
	power_of_two: $T,
) -> T where intrinsics.type_is_unsigned(T) {
	return power_of_two - 1
}
getBit :: #force_inline proc "contextless" (
	x, bit_index: $T,
) -> T where intrinsics.type_is_unsigned(T) {
	return (x >> bit_index) & 1
}
setBit :: proc(x, bit_index, bit_value: $T) -> T where intrinsics.type_is_unsigned(T) {
	toggle_bit := ((x >> bit_index) ~ bit_value) & 1
	return x ~ (toggle_bit << bit_index)
}
ilog2Ceil :: proc(x: $T) -> T where intrinsics.type_is_unsigned(T) {
	leading_zeros := clz(x)
	remainder := T((x << (leading_zeros + 1)) > 0)
	return size_of(T) * 8 - T(x > 0) - leading_zeros + remainder
}
// odin test lib/math
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
test_ilog2 :: proc(t: ^testing.T) {
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
		got := ilog2Ceil(key)
		testing.expectf(t, got == expected, "ilog2_ceil(%v): %v", key, got)
	}
}
