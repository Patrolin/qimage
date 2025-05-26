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
	// TODO: make this a fake HalfFitBlockHeader, that is always filled?
	free_lists:         [HALF_FIT_FREE_LIST_COUNT]^HalfFitFreeList, // NOTE: we only store HalfFitFreeList.next_free
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

half_fit_allocator :: proc(block: []u8) -> HalfFitAllocator {
	half_fit := HalfFitAllocator {
		available_bitfield = 0,
		free_lists         = {},
	}
	_half_fit_add_free_block(&half_fit, nil, block)
	return half_fit
}
_half_fit_add_free_block :: proc(half_fit: ^HalfFitAllocator, prev_block: ^HalfFitBlockHeader, block: []u8) {
	data_size := len(block) - size_of(HalfFitBlockHeader)
	list_index := _half_fit_block_index(data_size)

	block_header := (^HalfFitBlockHeader)(&block[0])
	block_header^ = {
		prev_free  = (^HalfFitFreeList)(&half_fit.free_lists[list_index]),
		prev_block = prev_block,
		size       = data_size,
		is_used    = false,
	}

	half_fit.free_lists[list_index] = (^HalfFitFreeList)(block_header)
	half_fit.available_bitfield |= 1 << u32(list_index)
}
_half_fit_remove_free_block :: proc(block_header: ^HalfFitBlockHeader) {
	prev_free := block_header.prev_free // NOTE: either free_lists[list_index] or the start of a HalfFitBlockHeader
	next_free := block_header.next_free
	prev_free.next_free = next_free
	if next_free != nil {next_free.prev_free = prev_free}
}

half_fit_alloc :: proc(half_fit: ^HalfFitAllocator, data_size: int) -> rawptr {
	// TODO: alignment
	list_index, none_available := _half_fit_data_index(half_fit, data_size)
	if intrinsics.expect(none_available, false) {
		return nil // OutOfMemory
	}
	block_header := (^HalfFitBlockHeader)(half_fit.free_lists[list_index])
	ptr := math.ptr_add(block_header, size_of(HalfFitBlockHeader))
	// flag block as used
	block_header.is_used = true
	next_free := block_header.next_free
	half_fit.free_lists[list_index] = next_free
	if next_free != nil {next_free.prev_free = nil}
	// split if have enough space
	prev_block_size := block_header.size
	if intrinsics.expect(prev_block_size >= data_size + HALF_FIT_MIN_BLOCK_SIZE, true) {
		next_block := math.ptr_add(ptr, data_size)
		block_header.size = data_size

		_half_fit_add_free_block(half_fit, block_header, next_block[:prev_block_size - data_size])
	}
	// update available_bitfield
	available_bitfield_mask := half_fit.free_lists[list_index] == nil ? ~(i32(1) << list_index) : ~i32(0)
	half_fit.available_bitfield &= u32(available_bitfield_mask)
	// return
	return ptr
}
half_fit_free :: proc(old_ptr: rawptr) {
	block_header := (^HalfFitBlockHeader)(math.ptr_add(old_ptr, -size_of(HalfFitBlockHeader)))
	_half_fit_remove_free_block(block_header)
	// merge with next_block
	next_block := (^HalfFitBlockHeader)(math.ptr_add(block_header, size_of(HalfFitBlockHeader) + block_header.size))
	if !next_block.is_used {
		block_header.size += size_of(HalfFitBlockHeader) + next_block.size
	}
	// TODO: merge with prev_block, next_block
}
