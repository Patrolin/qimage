package lib_alloc
import "core:mem"

ArenaData :: struct {
	data: []u8,
	used: int,
}
arenaAllocator :: proc(size: int) -> mem.Allocator {
	data := pageAlloc(size)
	used := size_of(ArenaData)
	arena_allocator := (^ArenaData)(&data[0])
	arena_allocator.data = data
	arena_allocator.used = used
	return mem.Allocator{procedure = arenaAllocatorProc, data = rawptr(&arena_allocator)}
}
destroyArenaAllocator :: proc(allocator: mem.Allocator) {
	pageFree(allocator.data)
}

isAtEnd :: proc(arena_allocator: ^ArenaData, ptr: rawptr, size: int) -> bool {
	ptr_end := &([^]u8)(ptr)[size]
	arena_end := &arena_allocator.data[arena_allocator.used]
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
	arena_allocator := (^ArenaData)(allocator_data)
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data := ([^]u8)(&arena_allocator.data[arena_allocator.used])[:size]
		arena_allocator.used += size
		if arena_allocator.used > len(arena_allocator.data) {
			return nil, .Out_Of_Memory
		} else {
			return data, nil
		}
	case .Free:
		return nil, nil
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize, .Resize_Non_Zeroed:
		if isAtEnd(arena_allocator, old_ptr, old_size) {
			arena_allocator.used += size - old_size
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
