package lib_alloc
import "../math"
import "../os"
import "core:mem"
import win "core:sys/windows"

when ODIN_OS == .Windows {
	pageAlloc :: proc(size: math.Size) -> []u8 {
		size := int(size)
		page_mask := os.info.page_size - 1
		size = (size + page_mask) & ~page_mask
		// NOTE: VirtualAlloc() always initializes to zero
		ptr := win.VirtualAlloc(
			nil,
			uint(size),
			win.MEM_RESERVE | win.MEM_COMMIT,
			win.PAGE_READWRITE,
		)
		return (cast([^]u8)ptr)[:size]
	}
	pageFree :: proc(ptr: rawptr) -> b32 {
		return b32(win.VirtualFree(ptr, 0, win.MEM_RELEASE))
	}
}

@(private)
pageAllocatorProc :: proc(
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
		data, err = pageAlloc(math.Size(size)), nil
	case .Free:
		error := pageFree(old_ptr)
		data, err = nil, error ? .Invalid_Argument : .None
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_ptr)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Query_Features}
		}
	case:
		data, err = nil, .Mode_Not_Implemented
	}
	return
}
pageAllocator :: proc() -> mem.Allocator {
	return mem.Allocator{procedure = pageAllocatorProc, data = nil}
}
