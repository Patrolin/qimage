package mem_utils

CACHE_LINE_SIZE :: 1 << 6
PAGE_SIZE :: 1 << 12
HUGE_PAGE_SIZE :: 1 << 21

zero_simd_64B :: proc(dest: rawptr, size: int) {
	dest := uintptr(dest)
	dest_end := dest + transmute(uintptr)(size)

	zero := (#simd[64]byte)(0)
	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = zero
		dest += 64
	}
}
copy_simd_64B :: proc(dest, src: rawptr, size: int) {
	dest := uintptr(dest)
	dest_end := dest + transmute(uintptr)(size)
	src := uintptr(src)

	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = (^#simd[64]byte)(src)^
		dest += 64
		src += 64
	}
}
