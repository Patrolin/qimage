package lib_alloc
import "../math"
import "../os"
import "base:runtime"
import "core:fmt"

CACHE_LINE_SIZE :: 1 << 6
PAGE_SIZE :: 1 << 12
HUGE_PAGE_SIZE :: 1 << 21
thread_id_to_context := map[int]runtime.Context{}

emptyContext :: os.emptyContext
defaultContext :: proc "contextless" (user_index: int) -> runtime.Context {
	if !(user_index in thread_id_to_context) {
		make_defaultContext(user_index) // NOTE: Odin doesn't like setting context inside of an if
	}
	return thread_id_to_context[user_index]
}
global_allocator: HalfFitAllocator
@(private)
make_defaultContext :: proc "contextless" (user_index: int) -> runtime.Context {
	ctx := emptyContext()
	ctx.allocator = runtime.Allocator{half_fit_allocator_proc, &global_allocator}
	context = ctx
	if (!(0 in thread_id_to_context)) {
		buffer := page_alloc(1 << 16) // TODO: grow on page fault
		half_fit_allocator_init(&global_allocator, buffer)
	}
	//context.temp_allocator = arenaAllocator()
	thread_id_to_context[user_index] = ctx
	return context
}

@(private)
_make_fake_dynamic_array :: proc($V: typeid, array: ^[dynamic]V, buffer: []V) {
	raw_array: ^runtime.Raw_Dynamic_Array = (^runtime.Raw_Dynamic_Array)(array)
	raw_array.data = &buffer[0]
	raw_array.len = 0
	raw_array.cap = len(buffer)
}
