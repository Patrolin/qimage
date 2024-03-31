package lib_alloc
import "core:fmt"
import "core:mem"

failAllocatorProc :: proc(
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
	fmt.printf("fail_loc = %v\n", loc)
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed:
		assert(false)
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_ptr)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Query_Features}
		}
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return
}
failAllocator :: proc() -> mem.Allocator {
	return mem.Allocator{procedure = failAllocatorProc, data = nil}
}
