package lib_alloc
import "../math"
import "../os/windows"
import "core:mem"
import win "core:sys/windows"

pageAlloc :: proc "contextless" (size: int) -> []u8 {
	size := size
	size = (size + (windows.info.min_page_size - 1)) & windows.info.min_page_size_mask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := win.VirtualAlloc(nil, uint(size), win.MEM_RESERVE | win.MEM_COMMIT, win.PAGE_READWRITE)
	return (cast([^]u8)ptr)[:size]
}
pageFree :: proc "contextless" (ptr: win.LPVOID) {
	win.VirtualFree(ptr, 0, win.MEM_RELEASE)
}
