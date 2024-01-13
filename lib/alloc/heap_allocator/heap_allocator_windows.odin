package heapAllocator
import "core:mem"
import coreWin "core:sys/windows"

LPVOID :: coreWin.LPVOID
HANDLE :: coreWin.HANDLE

HEAP_ZERO_MEMORY: u32 : 0x00000008

GetProcessHeap :: coreWin.GetProcessHeap
HeapAlloc :: coreWin.HeapAlloc
HeapReAlloc :: coreWin.HeapReAlloc
HeapFree :: coreWin.HeapFree

@(private)
processHeap: HANDLE
_alloc :: proc "contextless" (size: uint, clearToZero: bool) -> ([]byte, mem.Allocator_Error) {
	ptr := ([^]u8)(HeapAlloc(processHeap, HEAP_ZERO_MEMORY * u32(clearToZero), uint(size)))
	if ptr == nil {
		return nil, .Out_Of_Memory
	}
	return ptr[:size], nil
}
_free :: proc "contextless" (ptr: LPVOID) -> ([]byte, mem.Allocator_Error) {
	HeapFree(processHeap, 0, ptr)
	return nil, nil
}
_resize :: proc "contextless" (size: uint, oldPtr: LPVOID) -> ([]byte, mem.Allocator_Error) {
	if oldPtr == nil {
		return _alloc(size, true)
	}
	ptr := ([^]u8)(HeapReAlloc(processHeap, HEAP_ZERO_MEMORY, oldPtr, uint(size)))
	if ptr == nil {
		return nil, .Out_Of_Memory
	}
	return ptr[:size], nil
}

heap_allocator_proc :: proc(
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
		data, err = _alloc(uint(size), mode == .Alloc)
	case .Free:
		data, err = _free(old_memory)
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize:
		data, err = _resize(uint(size), old_memory)
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
heap_allocator :: proc() -> mem.Allocator {
	processHeap = GetProcessHeap()
	return mem.Allocator{procedure = heap_allocator_proc, data = nil}
}
