package mem_utils
import "../math"
import "base:intrinsics"
import "core:fmt"
import "core:mem"

// we will assume single threaded
ArenaAllocator :: struct {
	buffer: []byte,
	next:   int,
}
arena_alloc :: proc(arena_allocator: ^ArenaAllocator, size: int) -> (ptr: [^]byte) {
	ptr = math.ptr_add(raw_data(arena_allocator.buffer), arena_allocator.next)

	alignment_offset := math.align_forward(ptr, 64) // align to 64B, so we can do a faster copy when resizing
	ptr = math.ptr_add(ptr, alignment_offset)

	arena_allocator.next += size + alignment_offset
	return
}
arena_allocator :: proc(buffer: []byte) -> ArenaAllocator {
	return ArenaAllocator{buffer, 0}
}
arena_allocator_proc :: proc(
	allocator: rawptr,
	mode: mem.Allocator_Mode,
	size, _alignment: int,
	old_ptr: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {
	arena_allocator := (^ArenaAllocator)(allocator)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		ptr := arena_alloc(arena_allocator, size)
		data = ptr[:size]
		err = arena_allocator.next > len(arena_allocator.buffer) ? .Out_Of_Memory : .None
	case .Resize, .Resize_Non_Zeroed:
		// alloc
		ptr := arena_alloc(arena_allocator, size)
		data = ptr[:size]
		if (intrinsics.expect(arena_allocator.next > len(arena_allocator.buffer), false)) {
			err = .Out_Of_Memory
			break
		}
		// copy
		size_to_copy := min(size, old_size)
		copy_simd_64B(ptr, old_ptr, size_to_copy)
	case .Free_All:
		arena_allocator.next = 0
	}
	return
}
