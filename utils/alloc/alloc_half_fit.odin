package lib_alloc
import "../math"
import "core:fmt"

HALF_FIT_FREE_LIST_COUNT :: 32
HALF_FIT_MIN_BLOCK_SIZE :: size_of(HalfFitBlockHeader) + 8
HALF_FIT_INDEX_OFFSET :: 3
HalfFitAllocator :: struct {
	// TODO: mutex
	available_bitfield: u32,
	free_lists:         [HALF_FIT_FREE_LIST_COUNT]^HalfFitBlockHeader,
}
HalfFitBlockHeader :: struct {
	next_block: ^HalfFitBlockHeader,
	size:       int,
}
#assert(size_of(HalfFitBlockHeader) == 16)

half_fit_allocator :: proc(block: []u8) -> HalfFitAllocator {
	half_fit := HalfFitAllocator {
		available_bitfield = 0,
		free_lists         = {},
	}
	half_fit_add_block(&half_fit, block)
	return half_fit
}
half_fit_add_block :: proc(half_fit: ^HalfFitAllocator, block: []u8) {
	size := len(block) - size_of(HalfFitBlockHeader)
	list_index := half_fit_list_index_floor(size)
	// update free list
	block_header := (^HalfFitBlockHeader)(&block[0])
	block_header^ = {
		next_block = half_fit.free_lists[list_index],
		size       = size,
	}
	half_fit.free_lists[list_index] = block_header
	// update available_bitfield
	half_fit.available_bitfield |= 1 << u32(list_index)
}
half_fit_list_index_floor :: proc(size: int) -> int {
	return max(0, int(math.log2_floor(uint(size))) - HALF_FIT_INDEX_OFFSET)
}
half_fit_list_index_ceil :: proc(size: int) -> int {
	return max(0, int(math.log2_ceil(uint(size))) - HALF_FIT_INDEX_OFFSET)
}

half_fit_alloc :: proc(half_fit: ^HalfFitAllocator, size: int) -> rawptr {
	// TODO: alignment
	// TODO: check for OOM
	size_index := half_fit_list_index_ceil(size)
	size_mask := ~i32(0) >> u32(size_index)
	list_index := math.log2_floor(half_fit.available_bitfield & u32(size_mask))
	block_header := (^HalfFitBlockHeader)(half_fit.free_lists[list_index])
	ptr := math.ptr_add(block_header, size_of(HalfFitBlockHeader))
	// update free list
	half_fit.free_lists[list_index] = block_header.next_block
	// split if have enough space
	prev_block_size := block_header.size
	if prev_block_size >= size + HALF_FIT_MIN_BLOCK_SIZE {
		block_header.size = size
		next_block := math.ptr_add(ptr, size)
		half_fit_add_block(half_fit, next_block[:prev_block_size - size])
	}
	// update available_bitfield
	available_bitfield_mask :=
		half_fit.free_lists[list_index] == nil ? ~(i32(1) << list_index) : ~i32(0)
	half_fit.available_bitfield &= u32(available_bitfield_mask)
	// return
	return ptr
}
half_fit_free :: proc(old_ptr: rawptr) {
	// TODO
}
