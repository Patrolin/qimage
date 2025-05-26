package lib_alloc
import "../math"
import "../os"
import "base:runtime"
import "core:fmt"

CACHE_LINE_SIZE_EXPONENT :: 6
PAGE_SIZE_EXPONENT :: 12
HUGE_PAGE_SIZE_EXPONENT :: 21
thread_id_to_context := map[int]runtime.Context{}

emptyContext :: os.emptyContext
defaultContext :: proc "contextless" (user_index: int) -> runtime.Context {
	if !(user_index in thread_id_to_context) {
		make_defaultContext(user_index) // NOTE: Odin doesn't like setting context inside of an if
	}
	return thread_id_to_context[user_index]
}
@(private)
make_defaultContext :: proc "contextless" (user_index: int) -> runtime.Context {
	context = emptyContext()
	// TODO: reimplement when anyAllocator() is implemented
	//context.allocator = 0 in thread_id_to_context ? thread_id_to_context[0].allocator : slabAllocator()
	//context.temp_allocator = slabAllocator()
	thread_id_to_context[user_index] = context
	return context
}

@(private)
_make_fake_dynamic_array :: proc($V: typeid, array: ^[dynamic]V, buffer: []V) {
	raw_array: ^runtime.Raw_Dynamic_Array = (^runtime.Raw_Dynamic_Array)(array)
	raw_array.data = &buffer[0]
	raw_array.len = 0
	raw_array.cap = len(buffer)
}
