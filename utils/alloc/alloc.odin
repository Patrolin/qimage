package alloc_utils
import "../math"
import "../os"
import "base:runtime"
import "core:fmt"
import "core:simd"

CACHE_LINE_SIZE :: 1 << 6
PAGE_SIZE :: 1 << 12
HUGE_PAGE_SIZE :: 1 << 21

global_allocator: HalfFitAllocator
thread_index_to_context: [dynamic]runtime.Context

// NOTE: Odin doesn't like mixing if statements and `context = ...`, however I wasn't able to make a minimal repro case, so here we are..
init_thread_contexts :: proc() {
	assert(len(thread_index_to_context) == 0)
	for thread_index in 0 ..< os.info.logical_core_count {
		ctx := emptyContext()
		if thread_index == 0 {
			buffer := page_alloc(1 << 16) // TODO: grow on page fault
			half_fit_allocator_init(&global_allocator, buffer)
		}
		ctx.allocator = runtime.Allocator{half_fit_allocator_proc, &global_allocator}
		ctx.temp_allocator = runtime.default_context().temp_allocator
		append(&thread_index_to_context, ctx)
	}
}

emptyContext :: os.emptyContext
defaultContext :: proc "contextless" (user_index: int) -> runtime.Context {
	return thread_index_to_context[user_index]
}

// TODO: remove this
@(private)
_make_fake_dynamic_array :: proc($V: typeid, array: ^[dynamic]V, buffer: []V) {
	raw_array: ^runtime.Raw_Dynamic_Array = (^runtime.Raw_Dynamic_Array)(array)
	raw_array.data = &buffer[0]
	raw_array.len = 0
	raw_array.cap = len(buffer)
}

zero_simd_64B :: proc(dest, dest_end: uintptr) {
	zero := (#simd[8]u64)(0)
	dest := dest
	for dest < dest_end {
		(^#simd[8]u64)(dest)^ = zero
		dest += 64
	}
}
copy_simd_64B :: proc(dest, dest_end, src: uintptr) {
	dest := dest
	src := src
	for dest < dest_end {
		(^#simd[8]u64)(dest)^ = (^#simd[8]u64)(src)^
		dest += 64
		src += 64
	}
}
