package pageAllocator
import "core:mem"

_page_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_ptr: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data = page_alloc(uint(size))
		err = (data == nil) ? .Out_Of_Memory : nil
	case .Free:
		page_free(old_ptr)
		data, err = nil, nil
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize:
		data = page_resize(uint(size), old_ptr, uint(old_size))
		err = (data == nil) ? .Out_Of_Memory : nil
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_ptr)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Query_Features}
		}
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	assert((uintptr(&data[0]) & 15) == 0)
	return
}
_page_allocator :: proc() -> mem.Allocator {
	return mem.Allocator{procedure = _page_allocator_proc, data = nil}
}
