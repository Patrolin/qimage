package alloc
import "core:runtime"
import "heap_allocator"
import "page_allocator"

// odin errors with "D:\a\Odin\Odin\src\llvm_backend_proc.cpp(72): Panic: lib_heap_allocator :: proc() -> Allocator (was parapoly: 0 0)"
// if you don't rename this for some reason
lib_heap_allocator :: heap_allocator.heap_allocator

DefaultAllocators :: struct {
	allocator:      runtime.Allocator,
	temp_allocator: runtime.Allocator,
}

empty_context :: proc "contextless" () -> runtime.Context {
	ctx := runtime.default_context()
	ctx.allocator.procedure = nil
	ctx.temp_allocator.procedure = nil
	return ctx
}

@(private)
default_allocators := DefaultAllocators{}
default_context :: proc "contextless" () -> runtime.Context {
	ctx := empty_context()
	context = ctx
	if default_allocators.allocator.procedure == nil {
		//default_allocators.allocator = page_allocator._page_allocator()
		default_allocators.allocator = lib_heap_allocator()
		// TODO: fixed_arena_allocator()
		//default_allocators.temp_allocator = fixed_arena_allocator(4 * Megabyte)
	}
	ctx.allocator = default_allocators.allocator
	//ctx.temp_allocator = default_allocators.temp_allocator
	ctx.temp_allocator.procedure = runtime.default_temp_allocator_proc
	return ctx
}
