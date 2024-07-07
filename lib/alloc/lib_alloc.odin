package lib_alloc
import "../math"
import "../os"
import "base:runtime"

emptyContext :: os.emptyContext
defaultContext :: proc "contextless" (usePrivateTempAllocator: bool = false) -> runtime.Context {
	DefaultAllocators :: struct {
		allocator:      runtime.Allocator,
		temp_allocator: runtime.Allocator,
	}
	@(static)
	default_allocators := DefaultAllocators{}
	context = emptyContext()
	if default_allocators.allocator.procedure == nil {
		default_allocators.allocator = slabAllocator()
		default_allocators.temp_allocator = slabAllocator()
	}
	context.allocator = default_allocators.allocator
	context.temp_allocator =
		usePrivateTempAllocator ? slabAllocator() : default_allocators.temp_allocator
	return context
}

makeBig :: proc($T: typeid/[]$V, count: int) -> T {
	total_size := size_of(T) * count
	if (total_size <= MAX_SLAB_SIZE) {
		return make(T, count)
	} else {
		data := pageAlloc(math.bytes(total_size))
		t_data: [^]V = raw_data(data)
		return t_data[:count]
	}
}
freeBig :: proc($T: typeid/[]$V, ptr: T) {
	total_size := size_of(T) * count
	if (total_size <= MAX_SLAB_SIZE) {
		return free(ptr)
	} else {
		pageFree(ptr)
	}
}
