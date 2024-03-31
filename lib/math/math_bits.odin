package lib_math
import intrinsics "core:intrinsics"
import coreBits "core:math/bits"

clz :: coreBits.count_leading_zeros
ctz :: coreBits.count_trailing_zeros
count_ones :: coreBits.count_ones
count_zeros :: coreBits.count_zeros

upperBitsMask :: proc(n: $T) -> T where intrinsics.type_is_unsigned(T) {
	tmp := (transmute(uint)int(-1))
	return tmp << n
}
lowerBitsMask :: proc(n: $T) -> T where intrinsics.type_is_unsigned(T) {
	tmp := (transmute(uint)int(-1))
	return ~(tmp << n)
}
getBit :: proc(x: $T) -> T where intrinsics.type_is_unsigned(T) {
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
