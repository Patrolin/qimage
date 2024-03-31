package lib_math
import intrinsics "core:intrinsics"
import bits "core:math/bits"
import "core:testing"

clz :: bits.count_leading_zeros
ctz :: bits.count_trailing_zeros
count_ones :: bits.count_ones
count_zeros :: bits.count_zeros

upperBitsMask :: proc(n: $T) -> T where intrinsics.type_is_unsigned(T) {
	tmp := (transmute(uint)int(-1))
	return tmp << n
}
lowerBitsMask :: proc(n: $T) -> T where intrinsics.type_is_unsigned(T) {
	tmp := (transmute(uint)int(-1))
	return ~(tmp << n)
}
getBit :: proc(x, index: $T) -> T where intrinsics.type_is_unsigned(T) {
	return (x >> index) & 1
}
writeBit :: proc(x, index, value: $T) -> T where intrinsics.type_is_unsigned(T) {
	return (x >> index) & 1
}
ilog2_ceil :: proc(x: $T) -> T where intrinsics.type_is_unsigned(T) {
	if x == 0 {return 0}
	leading_zeros := clz(x)
	remainder := T((x << (leading_zeros + 1)) > 0)
	return size_of(T) * 8 - 1 - leading_zeros + remainder
}
@(test)
test_ilog2 :: proc(t: ^testing.T) {
	testing.expect(t, ilog2_ceil(u64(0)) == 0)
	testing.expect(t, ilog2_ceil(u64(1)) == 0)
	testing.expect(t, ilog2_ceil(u64(2)) == 1)
	testing.expect(t, ilog2_ceil(u64(3)) == 2)
	testing.expect(t, ilog2_ceil(u64(4)) == 2)
	testing.expect(t, ilog2_ceil(u64(7)) == 3)
	testing.expect(t, ilog2_ceil(u64(4096)) == 12)
}
