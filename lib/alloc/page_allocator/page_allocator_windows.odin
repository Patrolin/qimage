package pageAllocator
import "../../math"
import "core:mem"
import coreWin "core:sys/windows"

LPVOID :: coreWin.LPVOID
BOOL :: coreWin.BOOL
SYSTEM_INFO :: coreWin.SYSTEM_INFO

MEM_RESERVE :: coreWin.MEM_RESERVE
MEM_COMMIT :: coreWin.MEM_COMMIT
MEM_RELEASE :: coreWin.MEM_RELEASE
PAGE_READWRITE :: coreWin.PAGE_READWRITE

GetSystemInfo :: coreWin.GetSystemInfo
GetLargePageMinimum :: coreWin.GetLargePageMinimum
VirtualAlloc :: coreWin.VirtualAlloc
VirtualFree :: coreWin.VirtualFree

PageSizeInfo :: struct {
	minPageSize:          uint,
	minPageSizeMask:      uint,
	minLargePageSize:     uint,
	minLargePageSizeMask: uint,
}
pageSizeInfo := getPageSizeInfo()
getPageSizeInfo :: proc() -> (result: PageSizeInfo) {
	systemInfo: SYSTEM_INFO
	GetSystemInfo(&systemInfo)
	result.minPageSize = uint(systemInfo.dwAllocationGranularity)
	result.minPageSizeMask = math.mask_upper_bits(math.ctz(result.minPageSize))
	// NOTE: windows large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
	result.minLargePageSize = GetLargePageMinimum()
	result.minLargePageSizeMask = math.mask_upper_bits(math.ctz(result.minLargePageSize))
	return
}

page_alloc :: proc "contextless" (size: uint) -> []u8 {
	size := size
	size = (size + (pageSizeInfo.minPageSize - 1)) & pageSizeInfo.minPageSizeMask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := ([^]u8)(VirtualAlloc(nil, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE))
	return ptr[:size]
}
page_free :: proc "contextless" (ptr: LPVOID) {
	VirtualFree(ptr, 0, MEM_RELEASE)
}
page_resize :: proc "contextless" (size: uint, oldPtr: LPVOID, oldSize: uint) -> []u8 {
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
