package alloc_utils
import "../math"
import "../mem"
import "../os"
import "base:runtime"
import "core:fmt"
import "core:simd"
import win "core:sys/windows"

// allocators
VIRTUAL_MEMORY_TO_RESERVE :: 1 << 16
_global_allocator: mem.HalfFitAllocator
_temporary_allocators: [dynamic]mem.ArenaAllocator
_thread_index_to_context: [dynamic]runtime.Context // NOTE: read-only after the first time

// NOTE: Odin doesn't like mixing if statements and `context = ...`, however I wasn't able to make a minimal repro case, so here we are..
init :: proc() -> runtime.Context {
	assert(len(_thread_index_to_context) == 0)
	os.init()

	mem.init_page_fault_handler()
	mem.half_fit_allocator_init(&_global_allocator, mem.page_alloc(VIRTUAL_MEMORY_TO_RESERVE, false))
	context.allocator = runtime.Allocator{mem.half_fit_allocator_proc, &_global_allocator}

	for thread_index in 0 ..< os.info.logical_core_count {
		ctx := empty_context()
		ctx.allocator = runtime.Allocator{mem.half_fit_allocator_proc, &_global_allocator}

		append(&_temporary_allocators, mem.arena_allocator(mem.page_alloc(VIRTUAL_MEMORY_TO_RESERVE, false)))
		ctx.temp_allocator = runtime.Allocator{mem.arena_allocator_proc, &_temporary_allocators[thread_index]}

		append(&_thread_index_to_context, ctx)
	}

	return thread_context(0)
}
free_all_for_tests :: proc() {
	delete(_temporary_allocators)
	delete(_thread_index_to_context)
}

empty_context :: os.empty_context
thread_context :: proc "contextless" (user_index: int) -> runtime.Context {
	return _thread_index_to_context[user_index] // NOTE: we are copying the context here
}
