package lib_alloc
import "../os"
import "core:runtime"

DefaultAllocators :: struct {
	allocator:      runtime.Allocator,
	temp_allocator: runtime.Allocator,
}

emptyContext :: proc "contextless" () -> runtime.Context {
	ctx := runtime.default_context()
	ctx.allocator.procedure = nil
	ctx.temp_allocator.procedure = nil
	return ctx
}

defaultContext :: proc "contextless" () -> runtime.Context {
	@(static)
	default_allocators := DefaultAllocators{}
	ctx := emptyContext()
	context = ctx
	os.initInfo() // NOTE: we pretend we have a context, since it's not actually used...
	if default_allocators.allocator.procedure == nil {
		default_allocators.allocator = slabAllocator()
	}
	ctx.allocator = default_allocators.allocator
	//ctx.temp_allocator = default_allocators.temp_allocator
	ctx.temp_allocator.procedure = runtime.default_temp_allocator_proc
	ctx.temp_allocator.data = &runtime.global_default_temp_allocator_data // NOTE: get temp_allocator for current thread
	return ctx
}
