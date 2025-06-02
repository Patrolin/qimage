package alloc_utils
import "../math"
import "../os"
import "base:runtime"
import "core:fmt"
import "core:simd"
import win "core:sys/windows"

CACHE_LINE_SIZE :: 1 << 6
PAGE_SIZE :: 1 << 12
HUGE_PAGE_SIZE :: 1 << 21

_global_allocator: HalfFitAllocator
_thread_index_to_context: [dynamic]runtime.Context

// NOTE: Odin doesn't like mixing if statements and `context = ...`, however I wasn't able to make a minimal repro case, so here we are..
init :: proc() -> runtime.Context {
	assert(len(_thread_index_to_context) == 0)
	for thread_index in 0 ..< os.info.logical_core_count {
		ctx := empty_context()
		if thread_index == 0 {
			buffer := page_alloc(1 << 16, false)
			half_fit_allocator_init(&_global_allocator, buffer)
		}
		ctx.allocator = runtime.Allocator{half_fit_allocator_proc, &_global_allocator}
		ctx.temp_allocator = runtime.default_context().temp_allocator
		append(&_thread_index_to_context, ctx)
	}
	return thread_context(0)
}
free_all_for_tests :: proc() {
	delete(_thread_index_to_context)
}

empty_context :: os.empty_context
thread_context :: proc "contextless" (user_index: int) -> runtime.Context {
	return _thread_index_to_context[user_index]
}

zero_simd_64B :: proc(dest, dest_end: uintptr) {
	zero := (#simd[64]byte)(0)
	dest := dest
	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = zero
		dest += 64
	}
}
copy_simd_64B :: proc(dest, dest_end, src: uintptr) {
	dest := dest
	src := src
	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = (^#simd[64]byte)(src)^
		dest += 64
		src += 64
	}
}
