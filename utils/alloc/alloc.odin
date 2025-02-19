package lib_alloc
import "../math"
import "../os"
import "base:runtime"
import "core:fmt"

CACHE_SIZE :: 64
PAGE_SIZE :: 4 * math.KIBI_BYTES
HUGE_PAGE_SIZE :: 2 * math.MEBI_BYTES
thread_id_to_context := map[int]runtime.Context{}

emptyContext :: os.emptyContext
defaultContext :: proc "contextless" (user_index: int) -> runtime.Context {
	if !(user_index in thread_id_to_context) {
		new_defaultContext(user_index) // NOTE: Odin doesn't like setting context inside of an if
	}
	return thread_id_to_context[user_index]
}
@(private)
new_defaultContext :: proc "contextless" (user_index: int) -> runtime.Context {
	context = emptyContext()
	context.allocator =
		0 in thread_id_to_context ? thread_id_to_context[0].allocator : slabAllocator()
	context.temp_allocator = slabAllocator()
	thread_id_to_context[user_index] = context
	return context
}

makeBig :: proc($T: typeid/[]$V, count: int) -> T {
	total_size := size_of(T) * count
	if (total_size <= MAX_SLAB_SIZE) {
		return make(T, count)
	} else {
		data := page_alloc_aligned(math.Size(total_size))
		t_data: [^]V = raw_data(data)
		return t_data[:count]
	}
}
freeBig :: proc($T: typeid/[]$V, ptr: T) {
	total_size := size_of(T) * count
	if (total_size <= MAX_SLAB_SIZE) {
		return free(ptr)
	} else {
		page_free(ptr)
	}
}
@(private)
_make_fake_dynamic_array :: proc($V: typeid, array: ^[dynamic]V, buffer: []V) {
	raw_array: ^runtime.Raw_Dynamic_Array = (^runtime.Raw_Dynamic_Array)(array)
	raw_array.data = &buffer[0]
	raw_array.len = 0
	raw_array.cap = len(buffer)
}
