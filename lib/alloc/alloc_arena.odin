package alloc
import "core:mem"

ArenaData :: struct {
	memory: []u8,
	used:   uint, // TODO?: remove uint from allocators
}

isAtEnd :: proc(arena_data: ^ArenaData, ptr: rawptr, size: int) -> bool {
	ptr_end := &([^]u8)(ptr)[size]
	arena_end := &arena_data.memory[arena_data.used]
	return ptr_end == arena_end
}
arenaAllocatorProc :: proc(
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
	arena_data := (^ArenaData)(allocator_data)
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data := ([^]u8)(&arena_data.memory[arena_data.used])[:size]
		arena_data.used += uint(size)
		if arena_data.used > len(arena_data.memory) {
			return nil, .Out_Of_Memory
		} else {
			return data, nil
		}
	case .Free:
		return nil, nil
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize:
		if isAtEnd(arena_data, old_ptr, old_size) {
			arena_data.used += uint(size) - uint(old_size)
			data := ([^]u8)(old_ptr)[:size]
			return data, nil
		} else {
			return nil, .Invalid_Pointer
		}
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
arenaAllocator :: proc(size: uint) -> mem.Allocator {
	memory := pageAlloc(size)
	used := uint(size_of(ArenaData))
	arena_data := (^ArenaData)(&memory[0])
	arena_data.memory = memory
	arena_data.used = used
	return mem.Allocator{procedure = arenaAllocatorProc, data = rawptr(&arena_data)}
}
destroyArenaAllocator :: proc(allocator: mem.Allocator) {
	pageFree(allocator.data)
}
