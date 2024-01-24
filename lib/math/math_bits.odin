package lib_math
import coreBits "core:math/bits"

clz_uint :: proc(v: uint) -> uint {
	return coreBits.count_leading_zeros(v)
}
clz_int :: proc(v: int) -> uint {
	return clz_uint(uint(v))
}
clz :: proc {
	clz_uint,
	clz_int,
}
ctz_uint :: proc(v: uint) -> uint {
	return coreBits.count_trailing_zeros(v)
}
ctz_int :: proc(v: int) -> uint {
	return ctz_uint(uint(v))
}
ctz :: proc {
	ctz_uint,
	ctz_int,
}
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
