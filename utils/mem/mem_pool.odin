package mem_utils
import "../math"
import "base:intrinsics"

/* TODO: this is only useful if you allocate a tree and then free parts of it, does this ever happen in good code? */

// types
PoolAllocator :: struct {
	lock:            Lock,
	next_free_slot:  ^FreePoolSlot,
	next_empty_slot: ^FreePoolSlot,
	slot_size:       int,
}
#assert(size_of(PoolAllocator) <= 64)
pool_allocator :: proc(buffer: []byte, slot_size: int) -> PoolAllocator {
	assert(slot_size >= size_of(^FreePoolSlot))
	return PoolAllocator{false, nil, (^FreePoolSlot)(raw_data(buffer)), slot_size}
}

FreePoolSlot :: struct {
	next_free_slot: ^FreePoolSlot,
}
#assert(size_of(FreePoolSlot) <= 8)

// procedures
pool_alloc :: proc(pool: ^PoolAllocator) -> (new: [^]byte) {
	get_lock(&pool.lock)
	defer release_lock(&pool.lock)
	// find free slot
	next_free_slot := pool.next_free_slot
	next_empty_slot := pool.next_empty_slot
	have_free_slot := next_free_slot != nil
	slot := have_free_slot ? next_free_slot : next_empty_slot
	// update pool
	pool.next_free_slot = have_free_slot ? slot.next_free_slot : next_free_slot
	pool.next_empty_slot = (^FreePoolSlot)(math.ptr_add(next_empty_slot, have_free_slot ? 0 : pool.slot_size))
	return ([^]byte)(slot)
}
pool_free :: proc(pool: ^PoolAllocator, old_ptr: rawptr) {
	get_lock(&pool.lock)
	defer release_lock(&pool.lock)
	// TODO: guard against double free?
	old_slot := (^FreePoolSlot)(old_ptr)
	old_slot.next_free_slot = pool.next_free_slot
	pool.next_free_slot = old_slot
}
