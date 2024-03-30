package alloc
import win "../windows"
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
	if default_allocators.allocator.procedure == nil {
		default_allocators.allocator = heapAllocator()
	}
	ctx.allocator = default_allocators.allocator
	//ctx.temp_allocator = default_allocators.temp_allocator
	ctx.temp_allocator.procedure = runtime.default_temp_allocator_proc
	ctx.temp_allocator.data = &runtime.global_default_temp_allocator_data // NOTE: get temp_allocator for current thread
	when ODIN_OS == .Windows {
		win.initWindowsInfo()
	}
	return ctx
}
