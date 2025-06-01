package alloc_utils
import "../math"
import "base:intrinsics"

// TODO: buddy + pool
PoolAllocator :: struct {
	// TODO: mutex here
	next_free_slot:  rawptr,
	next_empty_slot: rawptr,
	slot_size:       u16,
}
PoolChunkHeader :: struct {
	used_slot_count: u16,
}
PoolSlot :: struct {
	next_free_slot: rawptr,
}

pool_allocator :: proc(slot_size: u16) -> PoolAllocator {
	assert(slot_size >= size_of(PoolChunkHeader))
	return PoolAllocator{nil, nil, slot_size}
}
pool_get_header :: proc(ptr: rawptr) -> ^PoolChunkHeader {
	return (^PoolChunkHeader)(uintptr(ptr) & math.high_mask(uintptr(PAGE_SIZE)))
}
pool_alloc :: proc(pool: ^PoolAllocator) -> (new: [^]byte) {
	chunk_header: ^PoolChunkHeader
	// find free slot
	if intrinsics.expect(pool.next_free_slot != nil, true) {
		new = ([^]byte)(pool.next_free_slot)
		slot := (^PoolSlot)(new)
		pool.next_free_slot = slot.next_free_slot
		chunk_header = pool_get_header(new)
	} else if intrinsics.expect(pool.next_empty_slot != nil, true) {
		new = ([^]byte)(pool.next_empty_slot)
		chunk_header = pool_get_header(new)
		next_slot := &new[pool.slot_size]
		next_chunk_header := pool_get_header(next_slot)
		if intrinsics.expect(next_chunk_header == chunk_header, true) {
			pool.next_empty_slot = next_slot
		} else {
			pool.next_empty_slot = nil
		}
	} else {
		new_page := page_alloc(PAGE_SIZE)
		new = ([^]byte)(&new_page[pool.slot_size]) // NOTE: new_page[0] holds the PoolChunkHeader
		pool.next_empty_slot = &new_page[pool.slot_size]
		chunk_header = pool_get_header(new)
	}
	// update chunk header
	chunk_header.used_slot_count += 1
	return
}
pool_free :: proc(pool: ^PoolAllocator, old_ptr: rawptr) {
	// TODO: guard against double free?
	// free slot
	old_slot := (^PoolSlot)(old_ptr)
	old_slot.next_free_slot = pool.next_free_slot
	pool.next_free_slot = old_ptr
	// update chunk header
	chunk_header := pool_get_header(old_ptr)
	chunk_header.used_slot_count += 1
}
