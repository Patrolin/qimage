package alloc
import "../math"
import "core:mem"
import coreWin "core:sys/windows"

PageSizeInfo :: struct {
	minPageSize:          uint,
	minPageSizeMask:      uint,
	minLargePageSize:     uint,
	minLargePageSizeMask: uint,
}
// TODO: move this to windows_info.odin
pageSizeInfo := getPageSizeInfo()
getPageSizeInfo :: proc() -> (result: PageSizeInfo) {
	systemInfo: coreWin.SYSTEM_INFO
	coreWin.GetSystemInfo(&systemInfo)
	result.minPageSize = uint(systemInfo.dwAllocationGranularity)
	result.minPageSizeMask = math.mask_upper_bits(math.ctz(result.minPageSize))
	// NOTE: windows large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
	result.minLargePageSize = coreWin.GetLargePageMinimum()
	result.minLargePageSizeMask = math.mask_upper_bits(math.ctz(result.minLargePageSize))
	return
}

page_alloc :: proc "contextless" (size: uint) -> []u8 {
	size := size
	size = (size + (pageSizeInfo.minPageSize - 1)) & pageSizeInfo.minPageSizeMask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := ([^]u8)(
		coreWin.VirtualAlloc(
			nil,
			size,
			coreWin.MEM_RESERVE | coreWin.MEM_COMMIT,
			coreWin.PAGE_READWRITE,
		),
	)
	return ptr[:size]
}
page_free :: proc "contextless" (ptr: coreWin.LPVOID) {
	coreWin.VirtualFree(ptr, 0, coreWin.MEM_RELEASE)
}
page_resize :: proc "contextless" (size: uint, oldPtr: coreWin.LPVOID, oldSize: uint) -> []u8 {
	ptr := page_alloc(size)
	if ptr != nil {
		size := uint(len(ptr))
		oldPtr := ([^]u8)(oldPtr)
		for i in 0 ..< oldSize {
			ptr[i] = oldPtr[i]
		}
		page_free(oldPtr)
	}
	return ptr
}
