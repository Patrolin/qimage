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
get_bit_u8 :: proc(x: u8, index: u8) -> u8 {
	return (x >> index) & 1
}
get_bit_u16 :: proc(x: u16, index: u16) -> u16 {
	return (x >> index) & 1
}
get_bit_u32 :: proc(x: u32, index: u32) -> u32 {
	return (x >> index) & 1
}
get_bit_u64 :: proc(x: u64, index: u64) -> u64 {
	return (x >> index) & 1
}
get_bit :: proc{get_bit_u8, get_bit_u16, get_bit_u32, get_bit_u64}
write_bit_u8 :: proc(x: u8, index: u8, value: u8) -> u8 {
	return (x &~ (1 << index)) | (value << index)
}
write_bit_u16 :: proc(x: u16, index: u16, value: u16) -> u16 {
	return (x &~ (1 << index)) | (value << index)
}
write_bit_u32 :: proc(x: u32, index: u32, value: u32) -> u32 {
	return (x &~ (1 << index)) | (value << index)
}
write_bit_u64 :: proc(x: u64, index: u64, value: u64) -> u64 {
	return (x &~ (1 << index)) | (value << index)
}
write_bit :: proc{write_bit_u8, write_bit_u16, write_bit_u32, write_bit_u64}

when ODIN_OS == .Windows {
	pack_rgba_v4 :: proc(v: v4) -> u32 {
		return(
			(u32(v.b) & 0xff << 0) |
			(u32(v.g) & 0xff << 8) |
			(u32(v.r) & 0xff << 16) |
			(u32(v.a) & 0xff << 24)
		)
	}
	pack_rgba_v4i :: proc(v: v4i) -> u32 {
		return(
			(u32(v.b) & 0xff << 0) |
			(u32(v.g) & 0xff << 8) |
			(u32(v.r) & 0xff << 16) |
			(u32(v.a) & 0xff << 24)
		)
	}
	pack_rgba :: proc{pack_rgba_v4, pack_rgba_v4i}
	unpack_rgba :: proc(rgba: u32) -> v4 {
		return v4{
			f32((rgba >> 16) & 0xff),
			f32((rgba >> 8) & 0xff),
			f32((rgba >> 0) & 0xff),
			f32((rgba >> 24) & 0xff),
		}
	}
} else {
	pack_rgba :: proc(v: v4) -> u32 {
		return(
			(u32(v.r) & 0xff << 0) |
			(u32(v.g) & 0xff << 8) |
			(u32(v.b) & 0xff << 16) |
			(u32(v.a) & 0xff << 24)
		)
	}
	unpack_rgba :: proc(rgba: u32) -> v4 {
		return v4{
			f32((rgba >> 0) & 0xff),
			f32((rgba >> 8) & 0xff),
			f32((rgba >> 16) & 0xff),
			f32((rgba >> 24) & 0xff),
		}
	}
}
