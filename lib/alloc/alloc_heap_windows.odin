package alloc
import "core:mem"
import coreWin "core:sys/windows"

@(private)
HEAP_ZERO_MEMORY: u32 : 0x00000008
// TODO: move this to windows_info.odin
@(private)
processHeap: coreWin.HANDLE
heap_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_ptr: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		ptr := ([^]u8)(
			coreWin.HeapAlloc(processHeap, HEAP_ZERO_MEMORY * u32(mode == .Alloc), uint(size)),
		)
		if ptr == nil {
			return nil, .Out_Of_Memory
		}
		return ptr[:size], nil
	case .Free:
		coreWin.HeapFree(processHeap, 0, old_ptr)
		return nil, nil
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize:
		if old_ptr == nil {
			ptr := ([^]u8)(coreWin.HeapAlloc(processHeap, HEAP_ZERO_MEMORY, uint(size)))
			if ptr == nil {
				return nil, .Out_Of_Memory
			}
			return ptr[:size], nil
		}
		ptr := ([^]u8)(coreWin.HeapReAlloc(processHeap, HEAP_ZERO_MEMORY, old_ptr, uint(size)))
		if ptr == nil {
			return nil, .Out_Of_Memory
		}
		return ptr[:size], nil
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_ptr)
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
	processHeap = coreWin.GetProcessHeap()
	return mem.Allocator{procedure = heap_allocator_proc, data = nil}
}