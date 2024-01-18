package lib_math
import coreBits "core:math/bits"

clz :: coreBits.count_leading_zeros
ctz :: coreBits.count_trailing_zeros
count_ones :: coreBits.count_ones
count_zeros :: coreBits.count_zeros

mask_upper_bits :: proc(n: uint) -> uint {
	tmp := (transmute(uint)int(-1))
	return tmp << n
}
mask_lower_bits :: proc(n: uint) -> uint {
	tmp := (transmute(uint)int(-1))
	return ~(tmp << n)
}
get_bit :: proc(x: u32, index: u32) -> u32 {
	return (x >> index) & 1;
}
set_bit :: proc(x: u32, index: u32) -> u32 {
	return x | (1 << index);
}
reset_bit :: proc(x: u32, index: u32) -> u32 {
	return x &~ (1 << index);
}
flip_bit :: proc(x: u32, index: u32) -> u32 {
	return x ~ (1 << index);
}
