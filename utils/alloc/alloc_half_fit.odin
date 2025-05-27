package lib_alloc
import "../math"
import "base:intrinsics"
import "core:fmt"

// utils
HALF_FIT_FREE_LIST_COUNT :: 32
HALF_FIT_MIN_BLOCK_SIZE :: size_of(HalfFitBlockHeader) + 8
HALF_FIT_INDEX_OFFSET :: 3
HalfFitAllocator :: struct {
	// TODO: mutex
	available_bitfield: u32,
	free_lists:         [HALF_FIT_FREE_LIST_COUNT]HalfFitFreeList,
}
HalfFitFreeList :: struct {
	next_free: ^HalfFitFreeList,
	prev_free: ^HalfFitFreeList,
}
HalfFitBlockHeader :: struct {
	next_free:  ^HalfFitFreeList,
	prev_free:  ^HalfFitFreeList,
	prev_block: ^HalfFitBlockHeader,
	size:       int,
	is_used:    bool,
}
#assert(size_of(HalfFitBlockHeader) == 40)
#assert(align_of(HalfFitBlockHeader) == 8)

_half_fit_block_index :: proc(size: int) -> int {
	return max(0, int(math.log2_floor(uint(size))) - HALF_FIT_INDEX_OFFSET)
}
_half_fit_data_index :: proc(half_fit: ^HalfFitAllocator, data_size: int) -> (list_index: u32, none_available: bool) {
	size_index := max(0, int(math.log2_ceil(uint(data_size))) - HALF_FIT_INDEX_OFFSET)
	size_mask := ~i32(0) >> u32(size_index)
	available_mask := half_fit.available_bitfield & u32(size_mask)
	return math.log2_floor(available_mask), available_mask == 0
}
half_fit_print_free_list :: proc(prefix: string, half_fit: ^HalfFitAllocator, list_index: int) {
	free_list := &half_fit.free_lists[list_index]
	fmt.printfln("%vfree_lists[%v] at %p:", prefix, list_index, free_list)
	for curr := free_list.next_free; curr != free_list; curr = curr.next_free {
		fmt.printfln("- %v at %p", (^HalfFitBlockHeader)(curr), curr)
	}
}

half_fit_allocator_init :: proc(half_fit: ^HalfFitAllocator, block: []u8) {
	half_fit.available_bitfield = 0
	for i in 0 ..< HALF_FIT_FREE_LIST_COUNT {
		free_list := &half_fit.free_lists[i]
		free_list^ = {
			next_free = free_list,
			prev_free = free_list,
		}
	}
	_half_fit_create_new_block(half_fit, nil, block)
}
_half_fit_create_new_block :: proc(half_fit: ^HalfFitAllocator, prev_block: ^HalfFitBlockHeader, block: []u8) {
	block_header := (^HalfFitBlockHeader)(&block[0])
	block_header.prev_block = prev_block
	block_header.size = len(block) - size_of(HalfFitBlockHeader)
	block_header.is_used = false
	_half_fit_mark_block_as_free(half_fit, block_header)
}
_half_fit_mark_block_as_free :: proc(half_fit: ^HalfFitAllocator, block_header: ^HalfFitBlockHeader) {
	list_index := _half_fit_block_index(block_header.size)
	free_list := &half_fit.free_lists[list_index]

	next_free := free_list.next_free
	free_list.next_free = (^HalfFitFreeList)(block_header)
	block_header.prev_free = free_list
	block_header.next_free = next_free
	next_free.prev_free = (^HalfFitFreeList)(block_header)

	half_fit.available_bitfield |= 1 << u32(list_index)
}
_half_fit_merge_with_next_block :: proc(block_header: ^HalfFitBlockHeader, next_block: ^HalfFitBlockHeader) {
	fmt.printfln("_half_fit_merge_with_next_block.1:\n  %v\n  %v", block_header, next_block)
	prev_free := next_block.prev_free
	next_free := next_block.next_free
	prev_free.next_free = next_free
	next_free.prev_free = prev_free

	block_header.size += size_of(HalfFitBlockHeader) + next_block.size
	fmt.printfln("_half_fit_merge_with_next_block.2:\n  %v", block_header)
}

half_fit_alloc :: proc(half_fit: ^HalfFitAllocator, data_size: int) -> rawptr {
	// TODO: alignment
	// get `free_list.next_free`
	list_index, none_available := _half_fit_data_index(half_fit, data_size)
	free_list := &half_fit.free_lists[list_index]
	block_header := (^HalfFitBlockHeader)(free_list.next_free)
	if (^HalfFitFreeList)(block_header) == free_list {
		return nil // OutOfMemory
	}
	ptr := math.ptr_add(block_header, size_of(HalfFitBlockHeader))
	// mark first free block as used
	block_header.is_used = true
	next_free := block_header.next_free
	free_list.next_free = next_free // TODO: these make multiple people point to free_list, have nil instead?
	next_free.prev_free = free_list
	available_bitfield_mask := next_free == free_list ? ~(i32(1) << list_index) : ~i32(0)
	half_fit.available_bitfield &= u32(available_bitfield_mask)
	// split if have enough space
	prev_block_size := block_header.size
	if intrinsics.expect(prev_block_size >= data_size + HALF_FIT_MIN_BLOCK_SIZE, true) {
		next_block := math.ptr_add(ptr, data_size)
		block_header.size = data_size

		_half_fit_create_new_block(half_fit, block_header, next_block[:prev_block_size - data_size])
	}
	// return
	return ptr
}
half_fit_free :: proc(half_fit: ^HalfFitAllocator, old_ptr: rawptr) {
	block_header := (^HalfFitBlockHeader)(math.ptr_add(old_ptr, -size_of(HalfFitBlockHeader)))
	// merge with next_block
	next_block := (^HalfFitBlockHeader)(math.ptr_add(block_header, size_of(HalfFitBlockHeader) + block_header.size))
	if !next_block.is_used {
		_half_fit_merge_with_next_block(block_header, next_block)
	}
	// merge with prev_block
	prev_block := block_header.prev_block
	if prev_block != nil && !prev_block.is_used {
		_half_fit_merge_with_next_block(prev_block, block_header)
		block_header = prev_block
	}
	// mark block as free
	_half_fit_mark_block_as_free(half_fit, block_header)
}
