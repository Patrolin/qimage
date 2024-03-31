package lib_alloc
import "../math"
import "../windows"
import "core:fmt"
import "core:mem"
import "core:testing"

SlabCache :: struct {
	data:         []u8 `fmt:"p"`, // 16 B
	used_slots:   u32, // 4 B
	slot_size:    u16, // 2 B
	header_slots: u16, // 2 B
	free_list:    ^SlabSlot, // 8 B
}
SlabSlot :: struct {
	next: ^SlabSlot, // 8 B
}
bootstrapSlabCache_first :: proc(slot_size: u16) -> ^SlabCache {
	assert(slot_size >= size_of(SlabCache), "Must have slot_size >= size_of(SlabCache)")
	data := pageAlloc(1)
	slab := transmute(^SlabCache)&data[0]
	slab.data = data
	slab.used_slots = 1
	slab.header_slots = 1
	slab.slot_size = slot_size
	return slab
}
bootstrapSlabCache_second :: proc(prev_slab: ^SlabCache, slot_size: u16) -> ^SlabCache {
	assert(slot_size >= size_of(SlabSlot), "Must have slot_size >= size_of(SlabSlot)")
	prev_slab.header_slots += 1
	slab := cast(^SlabCache)slabAlloc(prev_slab, size_of(SlabCache))
	slab.slot_size = slot_size
	return slab
}
bootstrapSlabCache :: proc {
	bootstrapSlabCache_first,
	bootstrapSlabCache_second,
}

slabAlloc :: proc(slab: ^SlabCache, size: int, zero: bool = true) -> rawptr {
	assert(size <= int(slab.slot_size), "Must have size <= slab.slot_size")
	ptr := rawptr(nil)
	if (slab.free_list != nil) {
		ptr = slab.free_list
		slab.free_list = (cast(^SlabSlot)ptr).next
	} else {
		if slab.data == nil {
			slab.data = pageAlloc(1)
		}
		used_bytes := int(slab.used_slots) * int(slab.slot_size)
		if used_bytes >= len(slab.data) {return nil}
		ptr = &slab.data[used_bytes]
		slab.used_slots += 1
	}
	if zero {
		curr_slice := (cast([^]u8)ptr)[:slab.slot_size]
		curr_slice = {}
	}
	return ptr
}
slabFree :: proc(slab: ^SlabCache, old_ptr: rawptr) {
	assert(
		(old_ptr >= &slab.data[0]) && (old_ptr <= &slab.data[len(slab.data) - 1]),
		"Can't free old_ptr outside the slab",
	)
	slot := cast(^SlabSlot)old_ptr
	slot.next = slab.free_list
	slab.free_list = slot
}
slabRealloc :: proc(
	old_slab: ^SlabCache,
	old_ptr: rawptr,
	slab: ^SlabCache,
	size: int,
	zero: bool = true,
) -> rawptr {
	ptr := slabAlloc(slab, size, zero)
	old_ptr_slice := (cast([^]u8)old_ptr)[:old_slab.slot_size]
	ptr_slice := (cast([^]u8)ptr)[:slab.slot_size]
	min_size := min(int(old_slab.slot_size), int(slab.slot_size))
	for i := 0; i < min_size; i += 1 {
		ptr_slice[i] = old_ptr_slice[i]
	}
	slabFree(old_slab, old_slab)
	return ptr
}
slabFreeAll :: proc(slab: ^SlabCache) {
	slab.free_list = nil
	slab.used_slots = u32(slab.header_slots)
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
	_32_bytes := bootstrapSlabCache(32)
	_128_bytes := bootstrapSlabCache(_32_bytes, 128)
	data := cast(^SlabAllocator)slabAlloc(_128_bytes, size_of(SlabAllocator))
	_128_bytes.header_slots += 1
	data._32_bytes = _32_bytes
	data._128_bytes = _128_bytes
	data._8_bytes = bootstrapSlabCache(_32_bytes, 8)
	data._16_bytes = bootstrapSlabCache(_32_bytes, 16)
	data._64_bytes = bootstrapSlabCache(_32_bytes, 64)
	data._128_bytes = bootstrapSlabCache(_32_bytes, 128)
	data._256_bytes = bootstrapSlabCache(_32_bytes, 256)
	data._512_bytes = bootstrapSlabCache(_32_bytes, 512)
	data._1024_bytes = bootstrapSlabCache(_32_bytes, 1024)
	data._2048_bytes = bootstrapSlabCache(_32_bytes, 2048)
	data._4096_bytes = bootstrapSlabCache(_32_bytes, 4096)
	return mem.Allocator{procedure = slabAllocatorProc, data = rawptr(data)}
}
chooseSlab :: proc(slab_allocator: ^SlabAllocator, size: int) -> ^SlabCache {
	assert(size <= 4096) // TODO: handle this?
	group := math.ilog2_ceil(u64(size))
	switch group {
	case:
		return slab_allocator._8_bytes
	case 4:
		return slab_allocator._16_bytes
	case 5:
		return slab_allocator._32_bytes
	case 6:
		return slab_allocator._64_bytes
	case 7:
		return slab_allocator._128_bytes
	case 8:
		return slab_allocator._256_bytes
	case 9:
		return slab_allocator._512_bytes
	case 10:
		return slab_allocator._1024_bytes
	case 11:
		return slab_allocator._2048_bytes
	case 12:
		return slab_allocator._4096_bytes
	}
}
// TODO: alignment?
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
	slab_allocator := cast(^SlabAllocator)allocator_data
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		slab := chooseSlab(slab_allocator, size)
		ptr := slabAlloc(slab, size, mode == .Alloc)
		data = (cast([^]u8)ptr)[:slab.slot_size]
		if data == nil {
			err = .Out_Of_Memory
		}
	case .Free:
		old_slab := chooseSlab(slab_allocator, old_size)
		slabFree(old_slab, old_ptr)
		return nil, nil
	case .Free_All:
		slabFreeAll(slab_allocator._8_bytes)
		slabFreeAll(slab_allocator._16_bytes)
		slabFreeAll(slab_allocator._32_bytes)
		slabFreeAll(slab_allocator._64_bytes)
		slabFreeAll(slab_allocator._128_bytes)
		slabFreeAll(slab_allocator._256_bytes)
		slabFreeAll(slab_allocator._512_bytes)
		slabFreeAll(slab_allocator._1024_bytes)
		slabFreeAll(slab_allocator._2048_bytes)
		slabFreeAll(slab_allocator._4096_bytes)
		return nil, nil
	case .Resize, .Resize_Non_Zeroed:
		old_slab := chooseSlab(slab_allocator, old_size)
		slab := chooseSlab(slab_allocator, size)
		data =
		(cast([^]u8)slabRealloc(old_slab, old_ptr, slab, size, mode == .Resize))[:slab.slot_size]
		if data == nil {
			err = .Out_Of_Memory
		}
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_ptr)
		if set != nil {
			set^ =  {
				.Alloc,
				.Alloc_Non_Zeroed,
				.Free,
				.Free_All,
				.Resize,
				.Resize_Non_Zeroed,
				.Query_Features,
			}
		}
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return
}

@(test)
testSlabAlloc :: proc(t: ^testing.T) {
	context = defaultContext()
	slab := bootstrapSlabCache(64)
	x := cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, x != nil, "Failed to allocate, x: %v", x)
	x^ = 13
	testing.expect(t, x^ == 13, "Failed to allocate")
	slabFree(slab, x)
	y := cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, y == x, "Failed to free, x: %v, y: %v", x, y)
	z := cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, z != y, "Failed to allocate, y: %v, z: %v", y, z)
	slabFreeAll(slab)
	y = cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, y == x, "Failed to free all, x: %v, y: %v", x, y)
	slab_2 := bootstrapSlabCache(slab, 8)
	y = cast(^u8)slabRealloc(slab, x, slab_2, 1)
	testing.expectf(t, (y != x) && (y != z), "Failed to realloc, x: %v, y: %v, z: %v", x, y, z)
}
