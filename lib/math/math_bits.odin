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
	return (x >> index) & 1
}
set_bit :: proc(x: u32, index: u32) -> u32 {
	return x | (1 << index)
}
reset_bit :: proc(x: u32, index: u32) -> u32 {
	return x &~ (1 << index)
}
flip_bit :: proc(x: u32, index: u32) -> u32 {
	return x ~ (1 << index)
}

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
