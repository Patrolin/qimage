package alloc
import "core:mem"

SlabCache :: struct {
	data:       []u8, // 16
	used_slots: u32, // 4
	slot_size:  u32, // 4
	free_list:  ^SlabSlot, // 8
}
SlabSlot :: struct {
	next: ^SlabSlot,
}
bootstrapSlabCache_first :: proc(slot_size: u32) -> ^SlabCache {
	assert(slot_size >= size_of(SlabCache), "Must have slot_size >= size_of(SlabCache)")
	data := pageAlloc(1)
	slab := transmute(^SlabCache)&data[0]
	slab.data = data
	slab.used_slots = 1
	slab.slot_size = slot_size
	return slab
}
bootstrapSlabCache_second :: proc(prev_slab: ^SlabCache, slot_size: u32) -> ^SlabCache {
	slab := cast(^SlabCache)slabAlloc(prev_slab, size_of(SlabCache))
	slab.slot_size = slot_size
	return slab
}
bootstrapSlabCache :: proc {
	bootstrapSlabCache_first,
	bootstrapSlabCache_second,
}

slabAlloc :: proc(slab: ^SlabCache, size: int) -> rawptr { 	// TODO: zero: bool
	assert(size <= int(slab.slot_size), "Must have size <= slab.slot_size")
	curr := slab.free_list
	if (curr != nil) {
		slab.free_list = curr.next
		return curr
	} else {
		used_bytes := int(slab.used_slots) * int(slab.slot_size)
		assert(len(slab.data) >= used_bytes)
		curr := &slab.data[used_bytes]
		slab.used_slots += 1
		return curr
	}
}
slabFree :: proc(slab: ^SlabCache, old_ptr: rawptr) {
	assert(
		(old_ptr >= &slab.data[0]) && (old_ptr < &slab.data[len(slab.data)]),
		"Can't free old_ptr outside the slab",
	)
	slot := cast(^SlabSlot)old_ptr
	slot.next = slab.free_list
	slab.free_list = slot
}
freeSlabCache :: proc(slab: SlabCache) {
	pageFree(&slab.data[0])
}

SlabAllocator :: struct {
	_8_bytes:    ^SlabCache,
	_16_bytes:   ^SlabCache,
	_32_bytes:   ^SlabCache,
	_64_bytes:   ^SlabCache,
	_128_bytes:  ^SlabCache,
	_256_bytes:  ^SlabCache,
	_512_bytes:  ^SlabCache,
	_1024_bytes: ^SlabCache,
	_2048_bytes: ^SlabCache,
	_4096_bytes: ^SlabCache,
}
slabAllocator :: proc() -> mem.Allocator {
	data := SlabAllocator {
		_32_bytes = bootstrapSlabCache(32),
	}
	data._8_bytes = bootstrapSlabCache(data._32_bytes, 8)
	data._16_bytes = bootstrapSlabCache(data._32_bytes, 16)
	data._64_bytes = bootstrapSlabCache(data._32_bytes, 64)
	data._128_bytes = bootstrapSlabCache(data._32_bytes, 128)
	data._256_bytes = bootstrapSlabCache(data._32_bytes, 256)
	data._512_bytes = bootstrapSlabCache(data._32_bytes, 512)
	data._1024_bytes = bootstrapSlabCache(data._32_bytes, 1024)
	data._2048_bytes = bootstrapSlabCache(data._32_bytes, 2048)
	data._4096_bytes = bootstrapSlabCache(data._32_bytes, 4096)
	return mem.Allocator{procedure = slabAllocatorProc, data = rawptr(data)}
}
slabAllocatorProc :: proc(
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
	// TODO
	/*
	arena_data := (^ArenaData)(allocator_data)
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data := ([^]u8)(&arena_data.memory[arena_data.used])[:size]
		arena_data.used += size
		if arena_data.used > len(arena_data.memory) {
			return nil, .Out_Of_Memory
		} else {
			return data, nil
		}
	case .Free:
		return nil, nil
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize, .Resize_Non_Zeroed:
		if isAtEnd(arena_data, old_ptr, old_size) {
			arena_data.used += size - old_size
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
	*/
	return
}
