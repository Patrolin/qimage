package lib_alloc
import "../math"
import "../thread"
import "core:fmt"
import "core:mem"
import "core:strings"

SlabHeader :: struct {
	used_slots: u16,
	slot_size:  u16,
}
SlabSlot :: struct {
	next: ^SlabSlot, // 8 B
}
@(private)
SLAB_COUNT :: 10
SlabAllocator :: struct {
	headers:    map[uintptr]SlabHeader, // 32 B
	mutex:      thread.TicketMutex, // 8 B
	free_slots: [10]uintptr, // 80 B
}
#assert(size_of(SlabAllocator) == 120)
slabAllocator :: proc() -> mem.Allocator {
	header_allocator := pageAllocator()
	_slab_allocator := SlabAllocator {
		headers = make_map(map[uintptr]SlabHeader, allocator = header_allocator),
	}
	slab_index, slot_size := chooseSlabToAlloc(size_of(SlabAllocator))
	slab_allocator_ptr := slab_alloc(&_slab_allocator, slab_index, slot_size)
	slab_allocator := (^SlabAllocator)(slab_allocator_ptr)
	slab_allocator^ = _slab_allocator
	return mem.Allocator{procedure = slabAllocatorProc, data = rawptr(slab_allocator)}
}

@(private)
slab_alloc :: proc(allocator: ^SlabAllocator, slot_index: u16, slot_size: u16) -> (ptr: uintptr) {
	ptr = allocator.free_slots[slot_index]
	if ptr == 0 {
		// no free slots
		ptr = uintptr(&pageAlloc(PAGE_SIZE)[0])
		assert(ptr & uintptr(math.lowMask(PAGE_SIZE)) == 0)
		allocator.headers[ptr] = SlabHeader {
			used_slots = 1,
			slot_size  = slot_size,
		}
		allocator.free_slots[slot_index] = ptr + 1
	} else {
		data := ptr & uintptr(math.highMask(PAGE_SIZE))
		header := &allocator.headers[uintptr(ptr) & uintptr(math.lowMask(PAGE_SIZE))]
		offset := uintptr(ptr) & uintptr(math.lowMask(PAGE_SIZE))
		if offset == 1 {
			// fill unused slots
			wanted_offset := uint(header.used_slots) * uint(header.slot_size)
			ptr = ptr - 1 + uintptr(wanted_offset)
			next_offset := ptr - data
			header.used_slots += 1
			if wanted_offset + uint(header.slot_size) > uint(PAGE_SIZE) {
				allocator.free_slots[slot_index] = 0
			}
		} else {
			// reuse old slot
			slot := (^SlabSlot)(ptr)
			allocator.free_slots[slot_index] = uintptr(slot.next)
		}
	}
	return
}
@(private)
slab_free :: proc(allocator: ^SlabAllocator, slot_index: u16, old_ptr: rawptr) {
	data := uintptr(old_ptr) & uintptr(math.highMask(PAGE_SIZE))
	header := &allocator.headers[data]
	fmt.assertf(
		data in allocator.headers,
		"Cannot free ptr outside of any slab: %v",
		uintptr(old_ptr),
	)
	slot := (^SlabSlot)(old_ptr)
	slot.next = (^SlabSlot)(allocator.free_slots[slot_index])
	allocator.free_slots[slot_index] = uintptr(old_ptr)
}
@(private)
chooseSlabToAlloc :: proc(size: int, loc := #caller_location) -> (slab_index, slot_size: u16) {
	group := math.ilog2Ceil(uint(size))
	switch group {
	case:
		slab_index = 0
		slot_size = 16
	case 5:
		slab_index = 1
		slot_size = 32
	case 6:
		slab_index = 2
		slot_size = 64
	case 7:
		slab_index = 3
		slot_size = 128
	case 8:
		slab_index = 4
		slot_size = 256
	case 9:
		slab_index = 5
		slot_size = 512
	case 10:
		slab_index = 6
		slot_size = 1024
	case 11:
		slab_index = 7
		slot_size = 2048
	}
	if size > int(slot_size) {
		buffer: [64]u8
		fake_dynamic_array: [dynamic]u8
		_make_fake_dynamic_array(u8, &fake_dynamic_array, buffer[:])
		sb := strings.Builder{([dynamic]u8)(fake_dynamic_array)}
		strings.write_bytes(&sb, transmute([]u8)string("Allocation size too big, size: "))
		strings.write_int(&sb, size)
		strings.write_bytes(&sb, transmute([]u8)string(" slot_size: "))
		strings.write_int(&sb, int(slot_size))
		assert(false, strings.to_string(sb), loc = loc)
	}
	return
}
@(private)
chooseSlabToFree :: proc(
	allocator: ^SlabAllocator,
	old_ptr: rawptr,
	loc := #caller_location,
) -> (
	slab_index, slot_size: u16,
) {
	data := uintptr(old_ptr) & uintptr(math.highMask(PAGE_SIZE))
	header := &allocator.headers[data]
	fmt.assertf(
		data in allocator.headers,
		"Cannot free ptr outside of any slab: %v, old_ptr: %v, allocator: %v",
		uintptr(data),
		uintptr(old_ptr),
		allocator,
	)
	return chooseSlabToAlloc(int(header.slot_size), loc = loc)
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
		slab_index, slot_size := chooseSlabToAlloc(size, loc = loc)
		thread.getMutex(&slab_allocator.mutex)
		ptr := slab_alloc(slab_allocator, slab_index, slot_size) // TODO: , mode == .Alloc
		thread.releaseMutex(&slab_allocator.mutex)
		data = (cast([^]u8)ptr)[:slot_size]
		if data == nil {
			err = .Out_Of_Memory
		}
	case .Free:
		slab_index, slot_size := chooseSlabToFree(slab_allocator, old_ptr, loc = loc)
		thread.getMutex(&slab_allocator.mutex)
		slab_free(slab_allocator, slab_index, old_ptr)
		thread.releaseMutex(&slab_allocator.mutex)
		data, err = nil, nil
	case .Free_All:
		thread.getMutex(&slab_allocator.mutex)
		assert(false, "Not yet implemented")
		/*
		slabFreeAll(slab_allocator._16_slab)
		slabFreeAll(slab_allocator._32_slab)
		slabFreeAll(slab_allocator._64_slab)
		slabFreeAll(slab_allocator._128_slab)
		slabFreeAll(slab_allocator._256_slab)
		slabFreeAll(slab_allocator._512_slab)
		slabFreeAll(slab_allocator._1024_slab)
		slabFreeAll(slab_allocator._2048_slab)
		slabFreeAll(slab_allocator._4096_slab)
		*/
		thread.releaseMutex(&slab_allocator.mutex)
		data, err = nil, nil
	case .Resize, .Resize_Non_Zeroed:
		assert(false, "Not yet implemented")
	/*
		slab_index, slot_size := chooseSlabToFree(slab_allocator, old_ptr, loc = loc)
		slab := chooseSlabToAlloc(slab_allocator, size, loc = loc)
		thread.getMutex(&slab_allocator.mutex)
		data =
		(cast([^]u8)slabRealloc(old_slab, old_ptr, slab, size, mode == .Resize))[:slab.slot_size]
		thread.releaseMutex(&slab_allocator.mutex)
		if data == nil {
			err = .Out_Of_Memory
		}
		*/
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
