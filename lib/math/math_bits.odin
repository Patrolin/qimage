package lib_math
import coreBits "core:math/bits"

clz :: coreBits.count_leading_zeros
ctz :: coreBits.count_trailing_zeros
count_ones :: coreBits.count_ones
count_zeros :: coreBits.count_zeros

maskUpperBits :: proc(n: uint) -> uint {
	tmp := (transmute(uint)int(-1))
	return tmp << n
}
maskLowerBits :: proc(n: uint) -> uint {
	tmp := (transmute(uint)int(-1))
	return ~(tmp << n)
}
getBit_u8 :: proc(x: u8, index: u8) -> u8 {
	return (x >> index) & 1
}
getBit_u16 :: proc(x: u16, index: u16) -> u16 {
	return (x >> index) & 1
}
getBit_u32 :: proc(x: u32, index: u32) -> u32 {
	return (x >> index) & 1
}
getBit_u64 :: proc(x: u64, index: u64) -> u64 {
	return (x >> index) & 1
}
getBit :: proc {
	getBit_u8,
	getBit_u16,
	getBit_u32,
	getBit_u64,
}
writeBit_u8 :: proc(x: u8, index: u8, value: u8) -> u8 {
	return (x &~ (1 << index)) | (value << index)
}
writeBit_u16 :: proc(x: u16, index: u16, value: u16) -> u16 {
	return (x &~ (1 << index)) | (value << index)
}
writeBit_u32 :: proc(x: u32, index: u32, value: u32) -> u32 {
	return (x &~ (1 << index)) | (value << index)
}
writeBit_u64 :: proc(x: u64, index: u64, value: u64) -> u64 {
	return (x &~ (1 << index)) | (value << index)
}
writeBit :: proc {
	writeBit_u8,
	writeBit_u16,
	writeBit_u32,
	writeBit_u64,
}
ilog2_ceil_u8 :: proc(x: u8) -> u8 {
	if x == 0 {return 0}
	leading_zeros := clz(x)
	remainder := u8((x << (leading_zeros + 1)) > 0)
	return 7 - leading_zeros + remainder
}
ilog2_ceil_u16 :: proc(x: u16) -> u16 {
	if x == 0 {return 0}
	leading_zeros := clz(x)
	remainder := u16((x << (leading_zeros + 1)) > 0)
	return 15 - leading_zeros + remainder
}
ilog2_ceil_u32 :: proc(x: u32) -> u32 {
	if x == 0 {return 0}
	leading_zeros := clz(x)
	remainder := u32((x << (leading_zeros + 1)) > 0)
	return 31 - leading_zeros + remainder
}
ilog2_ceil_u64 :: proc(x: u64) -> u64 {
	if x == 0 {return 0}
	leading_zeros := clz(x)
	remainder := u64((x << (leading_zeros + 1)) > 0)
	return 63 - leading_zeros + remainder
}
ilog2_ceil :: proc {
	ilog2_ceil_u8,
	ilog2_ceil_u16,
	ilog2_ceil_u32,
	ilog2_ceil_u64,
}
