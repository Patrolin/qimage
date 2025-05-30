package lib_alloc
import "core:mem"

AnyAllocator :: struct {
	pool_allocators: [8]PoolAllocator,
}
any_allocator_data :: proc() {}
any_allocator :: proc() -> mem.Allocator {
	return mem.Allocator{procedure = any_allocator_proc, data = nil}
}

@(private)
any_allocator_proc :: proc(
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
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data, err = nil, .Mode_Not_Implemented
	//data, err = alloc_page(math.Size(size)), nil
	case .Free:
		data, err = nil, .Mode_Not_Implemented
	//free_error := page_free(old_ptr)
	//data, err = nil, free_error ? .Invalid_Argument : .None
	case .Resize, .Resize_Non_Zeroed:
		data, err = nil, .Mode_Not_Implemented
	//data = alloc_page(math.Size(size))
	//mem.copy(&data[0], old_ptr, min(size, old_size))
	//free_error := page_free(old_ptr)
	//err = free_error ? .Invalid_Argument : .None
	case:
		data, err = nil, .Mode_Not_Implemented
	}
	return
}
