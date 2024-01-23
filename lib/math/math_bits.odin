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
getBit :: proc{getBit_u8, getBit_u16, getBit_u32, getBit_u64}
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
writeBit :: proc{writeBit_u8, writeBit_u16, writeBit_u32, writeBit_u64}

when ODIN_OS == .Windows {
	packRgba_v4 :: proc(v: v4) -> u32 {
		return(
			(u32(v.b) & 0xff << 0) |
			(u32(v.g) & 0xff << 8) |
			(u32(v.r) & 0xff << 16) |
			(u32(v.a) & 0xff << 24)
		)
	}
	packRgba_v4i :: proc(v: v4i) -> u32 {
		return(
			(u32(v.b) & 0xff << 0) |
			(u32(v.g) & 0xff << 8) |
			(u32(v.r) & 0xff << 16) |
			(u32(v.a) & 0xff << 24)
		)
	}
	packRgba :: proc{packRgba_v4, packRgba_v4i}
	unpackRgba :: proc(rgba: u32) -> v4 {
		return v4{
			f32((rgba >> 16) & 0xff),
			f32((rgba >> 8) & 0xff),
			f32((rgba >> 0) & 0xff),
			f32((rgba >> 24) & 0xff),
		}
	}
} else {
	packRgba :: proc(v: v4) -> u32 {
		return(
			(u32(v.r) & 0xff << 0) |
			(u32(v.g) & 0xff << 8) |
			(u32(v.b) & 0xff << 16) |
			(u32(v.a) & 0xff << 24)
		)
	}
	unpackRgba :: proc(rgba: u32) -> v4 {
		return v4{
			f32((rgba >> 0) & 0xff),
			f32((rgba >> 8) & 0xff),
			f32((rgba >> 16) & 0xff),
			f32((rgba >> 24) & 0xff),
		}
	}
}
