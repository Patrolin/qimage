package pageAllocator
import con "../../console"
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
// NOTE: large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
//MEM_LARGE_PAGES :: coreWin.MEM_LARGE_PAGES

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
	result.minLargePageSize = GetLargePageMinimum()
	result.minLargePageSizeMask = math.mask_upper_bits(math.ctz(result.minLargePageSize))
	return
}

page_alloc :: proc "contextless" (size: uint) -> ([]byte, mem.Allocator_Error) {
	size := size
	size = (size + (pageSizeInfo.minPageSize - 1)) & pageSizeInfo.minPageSizeMask
	// NOTE: VirtualAlloc() always initializes to zero
	ptr := ([^]u8)(VirtualAlloc(nil, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE))
	if ptr == nil {
		return nil, .Out_Of_Memory
	}
	return ptr[:size], nil
}
page_free :: proc "contextless" (ptr: LPVOID) -> ([]byte, mem.Allocator_Error) {
	VirtualFree(ptr, 0, MEM_RELEASE)
	return nil, nil
}
page_realloc :: proc "contextless" (
	size: uint,
	oldPtr: LPVOID,
	oldSize: uint,
) -> (
	[]byte,
	mem.Allocator_Error,
) {
	ptr, err := page_alloc(size)
	if ptr == nil {
		return ptr, err
	}
	size := uint(len(ptr))
	oldPtr := ([^]u8)(oldPtr)
	for i in 0 ..< oldSize {
		ptr[i] = oldPtr[i]
	}
	page_free(oldPtr)
	return ptr, nil
}

page_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data, err = page_alloc(uint(size))
	case .Free:
		data, err = page_free(old_memory)
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize:
		data, err = page_realloc(uint(size), old_memory, uint(old_size))
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Query_Features}
		}
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	assert((uintptr(&data[0]) & 15) == 0)
	return
}

page_allocator :: proc() -> mem.Allocator {
	return mem.Allocator{procedure = page_allocator_proc, data = nil}
}
