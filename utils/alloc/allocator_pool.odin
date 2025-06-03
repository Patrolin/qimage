package alloc_utils
import "../math"
import "../threads"
import "base:intrinsics"

PoolAllocator :: struct {
	lock:            threads.Lock,
	next_free_slot:  ^FreePoolSlot,
	next_empty_slot: ^FreePoolSlot,
	slot_size:       int,
}
#assert(size_of(PoolAllocator) <= 64)
FreePoolSlot :: struct {
	next_free_slot: ^FreePoolSlot,
}
#assert(size_of(FreePoolSlot) <= 8)

pool_allocator :: proc(buffer: []byte, slot_size: int) -> PoolAllocator {
	assert(slot_size >= size_of(^FreePoolSlot))
	return PoolAllocator{false, nil, (^FreePoolSlot)(raw_data(buffer)), slot_size}
}
pool_alloc :: proc(pool: ^PoolAllocator) -> (new: [^]byte) {
	threads.get_lock(&pool.lock)
	defer threads.release_lock(&pool.lock)
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
	threads.get_lock(&pool.lock)
	defer threads.release_lock(&pool.lock)
	// TODO: guard against double free?
	old_slot := (^FreePoolSlot)(old_ptr)
	old_slot.next_free_slot = pool.next_free_slot
	pool.next_free_slot = old_slot
}
