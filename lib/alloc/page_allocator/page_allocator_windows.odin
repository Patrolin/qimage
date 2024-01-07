package pageAllocator
import "core:mem"
import coreWin "core:sys/windows"

LPVOID :: coreWin.LPVOID
BOOL :: coreWin.BOOL

MEM_COMMIT :: coreWin.MEM_COMMIT
MEM_RESERVE :: coreWin.MEM_RESERVE
MEM_DECOMMIT :: coreWin.MEM_DECOMMIT
MEM_RELEASE :: coreWin.MEM_RELEASE
MEM_FREE :: coreWin.MEM_FREE
MEM_PRIVATE :: coreWin.MEM_PRIVATE
MEM_MAPPED :: coreWin.MEM_MAPPED
MEM_RESET :: coreWin.MEM_RESET
MEM_TOP_DOWN :: coreWin.MEM_TOP_DOWN
MEM_LARGE_PAGES :: coreWin.MEM_LARGE_PAGES
MEM_4MB_PAGES :: coreWin.MEM_4MB_PAGES

PAGE_NOACCESS :: coreWin.PAGE_NOACCESS
PAGE_READONLY :: coreWin.PAGE_READONLY
PAGE_READWRITE :: coreWin.PAGE_READWRITE
PAGE_WRITECOPY :: coreWin.PAGE_WRITECOPY
PAGE_EXECUTE :: coreWin.PAGE_EXECUTE
PAGE_EXECUTE_READ :: coreWin.PAGE_EXECUTE_READ
PAGE_EXECUTE_READWRITE :: coreWin.PAGE_EXECUTE_READWRITE
PAGE_EXECUTE_WRITECOPY :: coreWin.PAGE_EXECUTE_WRITECOPY
PAGE_GUARD :: coreWin.PAGE_GUARD
PAGE_NOCACHE :: coreWin.PAGE_NOCACHE
PAGE_WRITECOMBINE :: coreWin.PAGE_WRITECOMBINE

GetSystemInfo :: coreWin.GetSystemInfo
VirtualAlloc :: coreWin.VirtualAlloc
VirtualFree :: coreWin.VirtualFree
// TODO: get page size? (~64KB): systemInfo.dwAllocationGranularity
// TODO: get large page size? (~2MB): GetLargePageMinimum()

// NOTE: VirtualAlloc() always initializes to zero
_alloc :: proc "contextless" (size: int) -> ([]byte, mem.Allocator_Error) {
	ptr := ([^]u8)(VirtualAlloc(nil, uint(size), MEM_COMMIT, PAGE_READWRITE))
	if ptr == nil {
		return nil, .Out_Of_Memory
	}
	return ptr[:size], nil
}
_free :: proc "contextless" (ptr: LPVOID) -> ([]byte, mem.Allocator_Error) {
	VirtualFree(ptr, 0, MEM_RELEASE)
	return nil, nil
}
_realloc :: proc "contextless" (size: int, oldPtr: LPVOID) -> ([]byte, mem.Allocator_Error) {
	// TODO: move the data?
	if oldPtr != nil {
		_free(oldPtr)
	}
	return _alloc(size)
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
		data, err = _alloc(size)
	case .Free:
		data, err = _free(old_memory)
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize:
		data, err = _realloc(size, old_memory)
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
