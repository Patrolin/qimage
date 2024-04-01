package lib_alloc
import "../math"
import "../os/windows"
import "core:mem"
import win "core:sys/windows"

pageAlloc :: proc "contextless" (size: int) -> []u8 {
	size := size
	size = (size + (windows.info.min_page_size - 1)) & windows.info.min_page_size_mask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := ([^]u8)(
		win.VirtualAlloc(nil, uint(size), win.MEM_RESERVE | win.MEM_COMMIT, win.PAGE_READWRITE),
	)
	return mem.slice_ptr(ptr, size)
}
pageFree :: proc "contextless" (ptr: win.LPVOID) {
	win.VirtualFree(ptr, 0, win.MEM_RELEASE)
}
pageResize :: proc "contextless" (size: int, oldPtr: win.LPVOID, oldSize: int) -> []u8 {
	ptr := pageAlloc(size)
	if ptr != nil {
		size := len(ptr)
		oldPtr := ([^]u8)(oldPtr)
		for i in 0 ..< oldSize {
			ptr[i] = oldPtr[i]
		}
		pageFree(oldPtr)
	}
	return ptr
}
