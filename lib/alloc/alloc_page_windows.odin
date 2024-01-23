package alloc
import "../math"
import win "../windows"
import "core:mem"
import coreWin "core:sys/windows"

pageAlloc :: proc "contextless" (size: int) -> []u8 {
	size := size
	size = (size + (win.windows_info.min_page_size - 1)) & win.windows_info.min_page_size_mask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := ([^]u8)(
		coreWin.VirtualAlloc(
			nil,
			uint(size),
			coreWin.MEM_RESERVE | coreWin.MEM_COMMIT,
			coreWin.PAGE_READWRITE,
		),
	)
	return ptr[:size]
}
pageFree :: proc "contextless" (ptr: coreWin.LPVOID) {
	coreWin.VirtualFree(ptr, 0, coreWin.MEM_RELEASE)
}
pageResize :: proc "contextless" (size: int, oldPtr: coreWin.LPVOID, oldSize: uint) -> []u8 {
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
