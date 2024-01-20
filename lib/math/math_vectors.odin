package lib_math

Vec2 :: struct($T: typeid) #raw_union {
	E:         [2]T,
	using _xy: struct {
		x, y: T,
	},
}
Vec3 :: struct($T: typeid) #raw_union {
	E:          [3]T,
	using _xyz: struct {
		x, y, z: T,
	},
	using _rgb: struct {
		r, g, b: T,
	},
}
Vec4 :: struct($T: typeid) #raw_union {
	E:           [4]T,
	using _xyzw: struct {
		x, y, z, w: T,
	},
	using _rgba: struct {
		r, g, b, a: T,
	},
}

v2i :: Vec2(u16)
v3i :: Vec3(u16)
v4i :: Vec4(u16)
v2 :: Vec2(f32)
v3 :: Vec3(f32)
v4 :: Vec4(f32)
