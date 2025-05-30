package lib_alloc
import "../math"
import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:testing"

// utils
HALF_FIT_FREE_LIST_COUNT :: 31
HALF_FIT_MIN_BLOCK_DATA_SIZE_EXPONENT :: 5
HALF_FIT_MIN_BLOCK_DATA_SIZE :: 1 << HALF_FIT_MIN_BLOCK_DATA_SIZE_EXPONENT
HALF_FIT_MIN_BLOCK_SIZE :: size_of(HalfFitBlockHeader) + HALF_FIT_MIN_BLOCK_DATA_SIZE

/*
	NOTE: Not strictly necessary, but this way each allocation is on a different cache line.
	Therefore different threads won't be fighting over the same cache line.
	-> dynamic arrays should then start at 32B and grow to `2*len + 32B`
	   this kind of implies we should be using buckets of size `(1 << n) - 32` instead?
	Alternatively, we could have some kind of scheme to decide whether the HeaderBlock is before or after?
*/
#assert(HALF_FIT_MIN_BLOCK_SIZE == 64)

HalfFitAllocator :: struct {
	// TODO: mutex
	available_bitfield: u32,
	free_lists:         [HALF_FIT_FREE_LIST_COUNT]HalfFitFreeList,
}
#assert(size_of(HalfFitAllocator) <= 16 * 32)
HalfFitFreeList :: struct {
	next_free: ^HalfFitFreeList,
	prev_free: ^HalfFitFreeList,
}
HalfFitBlockHeader :: struct {
	// used by free blocks
	using _:        HalfFitFreeList,
	// shared
	prev_block:     ^HalfFitBlockHeader,
	/* {is_used: u1, is_last: u1, size: u62} */
	size_and_flags: uint `fmt:"#X"`,
}
#assert(size_of(HalfFitBlockHeader) == 32)
#assert(align_of(HalfFitBlockHeader) == 8)

_half_fit_block_index :: proc(size: uint) -> int {
	return int(math.log2_floor(size)) - HALF_FIT_MIN_BLOCK_DATA_SIZE_EXPONENT
}
_half_fit_data_index :: proc(half_fit: ^HalfFitAllocator, data_size: uint) -> (list_index: u32, none_available: bool) {
	size_index := int(math.log2_ceil(data_size)) - HALF_FIT_MIN_BLOCK_DATA_SIZE_EXPONENT
	size_mask := ~i32(0) >> u32(size_index)
	available_mask := half_fit.available_bitfield & u32(size_mask)
	return math.log2_floor(available_mask), available_mask == 0
}
_half_fit_split_size_and_flags :: proc(size_and_flags: uint) -> (is_used: bool, is_last: bool, size: uint) {
	is_used = (size_and_flags >> 63) != 0
	is_last = ((size_and_flags >> 62) & 1) != 0
	size = (size_and_flags << 2) >> 2
	return
}
_half_fit_merge_size_and_flags :: proc(is_used: bool, is_last: bool, size: uint) -> uint {
	return (uint(is_used) << 63) | (uint(is_last) << 62) | ((size << 2) >> 2)
}

half_fit_allocator_init :: proc(half_fit: ^HalfFitAllocator, buffer: []u8) {
	half_fit.available_bitfield = 0
	for i in 0 ..< HALF_FIT_FREE_LIST_COUNT {
		free_list := &half_fit.free_lists[i]
		free_list^ = {
			next_free = free_list,
			prev_free = free_list,
		}
	}
	assert(len(buffer) >= HALF_FIT_MIN_BLOCK_SIZE)
	_half_fit_create_new_block(half_fit, nil, true, buffer)
}
_half_fit_create_new_block :: proc(half_fit: ^HalfFitAllocator, prev_block: ^HalfFitBlockHeader, is_last: bool, block: []u8) {
	block_header := (^HalfFitBlockHeader)(&block[0])
	block_header.prev_block = prev_block
	block_header.size_and_flags = _half_fit_merge_size_and_flags(false, is_last, len(block) - size_of(HalfFitBlockHeader))
	_half_fit_mark_block_as_free(half_fit, block_header)
}
_half_fit_mark_block_as_free :: proc(half_fit: ^HalfFitAllocator, block_header: ^HalfFitBlockHeader) {
	size := (block_header.size_and_flags << 2) >> 2
	list_index := _half_fit_block_index(size)
	fmt.printfln("size: %v, list_index: %v", size, list_index)
	free_list := &half_fit.free_lists[list_index]

	next_free := free_list.next_free
	free_list.next_free = (^HalfFitFreeList)(block_header)
	block_header.prev_free = free_list
	block_header.next_free = next_free
	next_free.prev_free = (^HalfFitFreeList)(block_header)

	block_header.size_and_flags &= ~uint(0) >> 1

	half_fit.available_bitfield |= 1 << u32(list_index)
}
_half_fit_unlink_free_block :: proc(block_header: ^HalfFitBlockHeader) {
	prev_free := block_header.prev_free
	next_free := block_header.next_free
	prev_free.next_free = next_free
	next_free.prev_free = prev_free
}

half_fit_alloc :: proc(half_fit: ^HalfFitAllocator, data_size: int) -> (ptr: rawptr, err: runtime.Allocator_Error) {
	// get next free block
	data_size := max(HALF_FIT_MIN_BLOCK_DATA_SIZE, data_size)
	list_index, none_available := _half_fit_data_index(half_fit, transmute(uint)data_size)
	free_list := &half_fit.free_lists[list_index]
	block_header := (^HalfFitBlockHeader)(free_list.next_free)
	if intrinsics.expect((^HalfFitFreeList)(block_header) == free_list, false) {
		err = .Out_Of_Memory
		return
	}
	ptr = math.ptr_add(block_header, size_of(HalfFitBlockHeader))
	// mark first free block as used
	next_free := block_header.next_free
	free_list.next_free = next_free
	next_free.prev_free = free_list
	available_bitfield_mask := next_free == free_list ? ~(i32(1) << list_index) : ~i32(0)
	half_fit.available_bitfield &= u32(available_bitfield_mask)
	// split if have enough space
	_, is_last, prev_size := _half_fit_split_size_and_flags(block_header.size_and_flags)
	if intrinsics.expect(transmute(int)prev_size >= data_size + HALF_FIT_MIN_BLOCK_SIZE, true) {
		next_block := math.ptr_add(ptr, data_size)
		block_header.size_and_flags = transmute(uint)data_size
		_half_fit_create_new_block(half_fit, block_header, is_last, next_block[:transmute(int)prev_size - data_size])
	}
	// mark first free block as used.cont
	block_header.size_and_flags |= uint(1) << 63
	// return
	return
}
half_fit_free :: proc(half_fit: ^HalfFitAllocator, old_ptr: rawptr, loc := #caller_location) {
	block_header := (^HalfFitBlockHeader)(math.ptr_add(old_ptr, -size_of(HalfFitBlockHeader)))
	// merge with next_block
	is_used, is_last, size := _half_fit_split_size_and_flags(block_header.size_and_flags)
	assert(is_used, "Cannot free an unused block", loc = loc)
	next_block := (^HalfFitBlockHeader)(math.ptr_add(block_header, size_of(HalfFitBlockHeader) + transmute(int)size))
	next_is_used, next_is_last, next_size := _half_fit_split_size_and_flags(next_block.size_and_flags)
	if intrinsics.expect(!next_is_used, true) {
		fmt.printfln("merge with next_block:")
		_half_fit_print_block(block_header)
		_half_fit_print_block(next_block)
		_half_fit_unlink_free_block(next_block)
		is_last = next_is_last
		size += size_of(HalfFitBlockHeader) + next_size
		block_header.size_and_flags = _half_fit_merge_size_and_flags(false, is_last, size)
	}
	// merge with prev_block
	prev_block := block_header.prev_block
	if intrinsics.expect(prev_block != nil, true) {
		fmt.printfln("merge with prev_block:")
		_half_fit_print_block(prev_block)
		_half_fit_print_block(block_header)
		prev_is_used, prev_is_last, prev_size := _half_fit_split_size_and_flags(prev_block.size_and_flags)
		if intrinsics.expect(!prev_is_used, true) {
			_half_fit_unlink_free_block(prev_block)
			size += size_of(HalfFitBlockHeader) + prev_size
			prev_block.size_and_flags = _half_fit_merge_size_and_flags(false, is_last, size)
			block_header = prev_block
		}
	}
	// fix up next_block.prev_block
	if intrinsics.expect(!is_last, true) {
		next_block = (^HalfFitBlockHeader)(math.ptr_add(block_header, size_of(HalfFitBlockHeader) + transmute(int)size))
		next_block.prev_block = block_header
	}
	// mark block as free
	_half_fit_mark_block_as_free(half_fit, block_header)
}

// debug
half_fit_check_blocks :: proc(t: ^testing.T, prefix: string, half_fit: ^HalfFitAllocator, buffer: []u8, loc := #caller_location) {
	fmt.println(prefix)
	sum_of_block_sizes := uint(0)
	offset := 0
	for offset < len(buffer) {
		block_header := (^HalfFitBlockHeader)(&buffer[offset])
		_half_fit_print_block(block_header)
		is_used, is_last, size := _half_fit_split_size_and_flags(block_header.size_and_flags)
		sum_of_block_sizes += size_of(HalfFitBlockHeader) + size
		if is_last {break}
		offset += size_of(HalfFitBlockHeader) + transmute(int)size
	}
	_half_fit_print_free_lists(half_fit)
	fmt.print("\n", flush = true)
	testing.expectf(t, sum_of_block_sizes == len(buffer), "got: %v, expected: %v", sum_of_block_sizes, len(buffer), loc = loc)
	return
}
_half_fit_print_block :: proc(block_header: ^HalfFitBlockHeader) {
	is_used, is_last, size := _half_fit_split_size_and_flags(block_header.size_and_flags)
	// TODO: fix is_used, (fix next_free, prev_free)(?)
	if is_used {
		fmt.printfln("- %p: {{prev_block=%p, is_used=%v, is_last=%v, size=%v}}", block_header, block_header.prev_block, is_used, is_last, size)
	} else {
		fmt.printfln(
			"- %p: {{next_free=%p, prev_free=%p, prev_block=%p, is_used=%v, is_last=%v, size=%v}}",
			block_header,
			block_header.next_free,
			block_header.prev_free,
			block_header.prev_block,
			is_used,
			is_last,
			size,
		)
	}
}
_half_fit_print_free_lists :: proc(half_fit: ^HalfFitAllocator) {
	fmt.printfln("free_lists:")
	for i in 0 ..< len(half_fit.free_lists) {
		free_list := &half_fit.free_lists[i]
		next_free := free_list.next_free
		if next_free != free_list {
			fmt.printfln("  %v: %v", i, free_list)
		}
	}
}

// odin wrapper
half_fit_allocator_proc :: proc(
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
	fmt.printfln("alignment: %v", _alignment)
	half_fit := (^HalfFitAllocator)(allocator_data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		ptr: rawptr
		ptr, err = half_fit_alloc(half_fit, size)
		data = ([^]byte)(ptr)[:size]
	case .Free:
		half_fit_free(half_fit, old_ptr, loc)
	case:
		data, err = nil, .Mode_Not_Implemented
	}
	return
}
