package lib_math
import "../test"
import intrinsics "base:intrinsics"
import "core:fmt"
import bits "core:math/bits"
import "core:testing"

Size :: distinct int
BYTES :: Size(1)
KIBI_BYTES :: 1024 * BYTES
MEBI_BYTES :: 1024 * KIBI_BYTES
GIBI_BYTES :: 1024 * MEBI_BYTES

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
) -> T where intrinsics.type_is_integer(T) {
	return power_of_two - 1
}
highMask :: #force_inline proc "contextless" (
	power_of_two: $T,
) -> T where intrinsics.type_is_integer(T) {
	return ~(power_of_two - 1)
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
log2_floor :: proc(x: $T) -> T where intrinsics.type_is_unsigned(T) {
	leading_zeros := clz(x)
	return size_of(T) * 8 - T(x > 0) - leading_zeros
}
log2_ceil :: proc(x: $T) -> T where intrinsics.type_is_unsigned(T) {
	leading_zeros := clz(x)
	remainder := T((x << (leading_zeros + 1)) > 0)
	return size_of(T) * 8 - T(x > 0) - leading_zeros + remainder
}
floorTo :: #force_inline proc "contextless" (
	x, floor_to: $T,
) -> T where intrinsics.type_is_integer(T) {
	return x / floor_to * floor_to
}
