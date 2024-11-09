package lib_alloc
import "../math"
import "../thread"
import "core:fmt"
import "core:mem"

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
@(private)
slabCache_first :: proc(data: []u8, slot_size: u16) -> ^SlabCache {
	assert(slot_size >= size_of(SlabCache), "Must have slot_size >= size_of(SlabCache)")
	assert(len(data) >= int(slot_size), "Must have len(data) >= slot_size")
	data := data
	slab := transmute(^SlabCache)&data[0]
	slab.data = data
	slab.used_slots = 1
	slab.header_slots = 1
	slab.slot_size = slot_size
	return slab
}
@(private)
slabCache_second :: proc(prev_slab: ^SlabCache, data: []u8, slot_size: u16) -> ^SlabCache {
	assert(slot_size >= size_of(SlabSlot), "Must have slot_size >= size_of(SlabSlot)")
	assert(len(data) >= int(slot_size), "Must have len(data) >= slot_size")
	slab := cast(^SlabCache)slabAllocHeader(prev_slab, size_of(SlabCache))
	slab.data = data
	slab.slot_size = slot_size
	return slab
}
slabCache :: proc {
	slabCache_first,
	slabCache_second,
}

@(private)
slabAllocHeader :: proc(slab: ^SlabCache, size: int) -> rawptr {
	assert(size <= int(slab.slot_size), "Must have size <= slab.slot_size")
	assert(
		u32(slab.header_slots) == slab.used_slots,
		"Header slots must be allocated at the beginning",
	)
	assert(slab.data != nil)
	used_bytes := int(slab.used_slots) * int(slab.slot_size)
	if used_bytes >= len(slab.data) {return nil}
	slab.used_slots += 1
	slab.header_slots += 1
	return &slab.data[used_bytes]
}
slabAlloc :: proc(slab: ^SlabCache, size: int, zero: bool = true) -> rawptr {
	assert(size <= int(slab.slot_size), "Must have size <= slab.slot_size")
	ptr := rawptr(nil)
	if (slab.free_list != nil) {
		ptr = slab.free_list
		slab.free_list = (cast(^SlabSlot)ptr).next
	} else {
		assert(slab.data != nil)
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
	if old_ptr == nil {return}
	offset := int(uintptr(old_ptr) - uintptr(&slab.data[0]))
	start_offset := int(slab.header_slots) * int(slab.slot_size)
	end_offset := int(slab.used_slots) * int(slab.slot_size)
	fmt.assertf(
		(offset >= 0) && (offset < end_offset),
		"Can't free old_ptr: %v outside the slab: (0x%X - 0x%X)",
		old_ptr,
		int(uintptr(&slab.data[0])) + start_offset,
		int(uintptr(&slab.data[0])) + end_offset,
	)
	assert(offset >= start_offset, "Can't free a header slot")
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
	for i in 0 ..< min_size {
		ptr_slice[i] = old_ptr_slice[i]
	}
	slabFree(old_slab, old_ptr)
	return ptr
}
slabFreeAll :: proc(slab: ^SlabCache) {
	slab.free_list = nil
	slab.used_slots = u32(slab.header_slots)
}

@(private)
MAX_SLAB_SIZE :: 4096
SlabAllocator :: struct {
	using _: struct #raw_union {
		slabs:   [10]^SlabCache,
		using _: struct {
			_16_slab:   ^SlabCache, // NOTE: min SIMD size
			_32_slab:   ^SlabCache,
			_64_slab:   ^SlabCache,
			_128_slab:  ^SlabCache,
			_256_slab:  ^SlabCache,
			_512_slab:  ^SlabCache,
			_1024_slab: ^SlabCache,
			_2048_slab: ^SlabCache,
			_4096_slab: ^SlabCache,
		},
	},
	mutex:   thread.TicketMutex,
}
slabAllocator :: proc() -> mem.Allocator {
	partition := Partition {
		data = pageAlloc(math.kibiBytes(64)),
	}
	// TODO: color cache lines (slabs above 64B)
	_4096_slab_data := partitionBy(&partition, 1.0 / 4)
	_2048_slab_data := partitionBy(&partition, 1.0 / 8)
	_1024_slab_data := partitionBy(&partition, 1.0 / 16)
	_512_slab_data := partitionBy(&partition, 1.0 / 32)
	_256_slab_data := partitionBy(&partition, 1.0 / 32)
	_128_slab_data := partitionBy(&partition, 1.0 / 8)
	_64_slab_data := partitionBy(&partition, 1.0 / 8)
	_32_slab_data := partitionBy(&partition, 1.0 / 8)
	_16_slab_data := partitionBy(&partition, 1.0 / 8)
	assert(partition.used == len(partition.data), "Unused space in partition")

	_32_slab := slabCache(_32_slab_data, 32)
	_128_slab := slabCache(_32_slab, _128_slab_data, 128)
	data := cast(^SlabAllocator)slabAllocHeader(_128_slab, size_of(SlabAllocator))
	data._16_slab = slabCache(_32_slab, _16_slab_data, 16) // NOTE: C ABI demands 16B alignment
	data._32_slab = _32_slab
	data._64_slab = slabCache(_32_slab, _64_slab_data, 64)
	data._128_slab = _128_slab
	data._256_slab = slabCache(_32_slab, _256_slab_data, 256)
	data._512_slab = slabCache(_32_slab, _512_slab_data, 512)
	data._1024_slab = slabCache(_32_slab, _1024_slab_data, 1024)
	data._2048_slab = slabCache(_32_slab, _2048_slab_data, 2048)
	data._4096_slab = slabCache(_32_slab, _4096_slab_data, 4096)
	return mem.Allocator{procedure = slabAllocatorProc, data = rawptr(data)}
}
chooseSlabToAlloc :: proc(slab_allocator: ^SlabAllocator, size: int) -> ^SlabCache {
	assert(size <= MAX_SLAB_SIZE, "Allocation size too big")
	group := math.ilog2Ceil(uint(size))
	switch group {
	case:
		return slab_allocator._16_slab
	case 5:
		return slab_allocator._32_slab
	case 6:
		return slab_allocator._64_slab
	case 7:
		return slab_allocator._128_slab
	case 8:
		return slab_allocator._256_slab
	case 9:
		return slab_allocator._512_slab
	case 10:
		return slab_allocator._1024_slab
	case 11:
		return slab_allocator._2048_slab
	case 12:
		return slab_allocator._4096_slab
	}
}
chooseSlabToFree :: proc(
	slab_allocator: ^SlabAllocator,
	old_ptr: rawptr,
	old_size: int,
) -> ^SlabCache {
	if (old_size != 0) {
		return chooseSlabToAlloc(slab_allocator, old_size)
	} else {
		for &slab in slab_allocator.slabs { 	// NOTE: odin gives us old_size: 0 for free(int_ptr) for some reason
			length := len(slab.data)
			start := int(uintptr(&slab.data[0]))
			end := start + length - 1
			old_ptr_int := int(uintptr(old_ptr))
			if old_ptr_int >= start && old_ptr_int <= end {
				return slab
			}
		}
		fmt.assertf(false, "Cannot free outside slabs, old_ptr: %v", old_ptr)
		return nil
	}
}
@(private)
slabAllocatorProc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, _alignment: int,
	old_ptr: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {
	//fmt.printf("loc = %v\n", loc)
	slab_allocator := cast(^SlabAllocator)allocator_data
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		slab := chooseSlabToAlloc(slab_allocator, size)
		thread.getMutex(&slab_allocator.mutex)
		ptr := slabAlloc(slab, size, mode == .Alloc)
		thread.releaseMutex(&slab_allocator.mutex)
		data = (cast([^]u8)ptr)[:slab.slot_size]
		if data == nil {
			err = .Out_Of_Memory
		}
	case .Free:
		old_slab := chooseSlabToFree(slab_allocator, old_ptr, old_size)
		thread.getMutex(&slab_allocator.mutex)
		slabFree(old_slab, old_ptr)
		thread.releaseMutex(&slab_allocator.mutex)
		data, err = nil, nil
	case .Free_All:
		thread.getMutex(&slab_allocator.mutex)
		slabFreeAll(slab_allocator._16_slab)
		slabFreeAll(slab_allocator._32_slab)
		slabFreeAll(slab_allocator._64_slab)
		slabFreeAll(slab_allocator._128_slab)
		slabFreeAll(slab_allocator._256_slab)
		slabFreeAll(slab_allocator._512_slab)
		slabFreeAll(slab_allocator._1024_slab)
		slabFreeAll(slab_allocator._2048_slab)
		slabFreeAll(slab_allocator._4096_slab)
		thread.releaseMutex(&slab_allocator.mutex)
		data, err = nil, nil
	case .Resize, .Resize_Non_Zeroed:
		old_slab := chooseSlabToFree(slab_allocator, old_ptr, old_size)
		slab := chooseSlabToAlloc(slab_allocator, size)
		thread.getMutex(&slab_allocator.mutex)
		data =
		(cast([^]u8)slabRealloc(old_slab, old_ptr, slab, size, mode == .Resize))[:slab.slot_size]
		thread.releaseMutex(&slab_allocator.mutex)
		if data == nil {
			err = .Out_Of_Memory
		}
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_ptr)
		if set != nil {
			set^ = {
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
		data, err = nil, .Mode_Not_Implemented
	}
	return
}
