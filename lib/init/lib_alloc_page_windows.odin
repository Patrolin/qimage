package lib_init
import "../math"
import win "core:sys/windows"

pageAlloc :: proc(size: math.bytes) -> []u8 {
	size := int(size)
	size = (size + (os_info.min_page_size - 1)) & os_info.min_page_size_mask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := win.VirtualAlloc(nil, uint(size), win.MEM_RESERVE | win.MEM_COMMIT, win.PAGE_READWRITE)
	return (cast([^]u8)ptr)[:size]
}
pageFree :: proc(ptr: win.LPVOID) {
	win.VirtualFree(ptr, 0, win.MEM_RELEASE)
}
