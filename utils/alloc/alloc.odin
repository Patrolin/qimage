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

// allocators
VMEM_TO_RESERVE :: 1 << 16
_global_allocator: HalfFitAllocator
_temporary_allocators: [dynamic]ArenaAllocator
_thread_index_to_context: [dynamic]runtime.Context

// NOTE: Odin doesn't like mixing if statements and `context = ...`, however I wasn't able to make a minimal repro case, so here we are..
init :: proc() -> runtime.Context {
	assert(len(_thread_index_to_context) == 0)

	init_page_fault_handler()
	half_fit_allocator_init(&_global_allocator, page_alloc(VMEM_TO_RESERVE, false))
	context.allocator = runtime.Allocator{half_fit_allocator_proc, &_global_allocator}

	for thread_index in 0 ..< os.info.logical_core_count {
		ctx := empty_context()
		ctx.allocator = runtime.Allocator{half_fit_allocator_proc, &_global_allocator}

		append(&_temporary_allocators, arena_allocator(page_alloc(VMEM_TO_RESERVE, false)))
		ctx.temp_allocator = runtime.Allocator{arena_allocator_proc, &_temporary_allocators[thread_index]}

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
