package lib_init
import "../math"
import win "core:sys/windows"

pageAlloc :: proc(size: math.bytes) -> []u8 {
	size := int(size)
	page_mask := os_info.page_size - 1
	size = (size + page_mask) & ~page_mask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := win.VirtualAlloc(nil, uint(size), win.MEM_RESERVE | win.MEM_COMMIT, win.PAGE_READWRITE)
	return (cast([^]u8)ptr)[:size]
}
pageFree :: proc(ptr: win.LPVOID) {
	win.VirtualFree(ptr, 0, win.MEM_RELEASE)
}
