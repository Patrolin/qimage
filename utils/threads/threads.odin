package threads_utils
import "../mem"
import "../os"
import "base:runtime"
import "core:fmt"

/* What I want out of a threading api:
	1) framerate independent inputs
	2) the CPU to not be waiting on the result of the GPU, and vice versa
	3) background loading of files

The plan:
	- 1 thread waiting on window/input events
	- 1 (2?) threads reading/writing files // how many threads do we need to max out the (read) bandwidth?
	- 1 simulate_game() thread // running at a fixed framerate
		- can launch more threads to help
	- 1 render_on_gpu() thread // interpolate between the last 2 simulated frames, vsynced to the monitor refresh rate
*/

// global variables
global_allocator_data: mem.HalfFitAllocator
thread_infos: [dynamic]ThreadInfo
semaphore: OsSemaphore
total_thread_count := 1

running_thread_count := 1
pending_async_files := 0 // TODO: delete this

// constants
VIRTUAL_MEMORY_TO_RESERVE :: 1 << 16

// procedures
/* NOTE: Odin doesn't like mixing if statements and `context = ...`, however I wasn't able to make a minimal repro case, so here we are.. */
init :: proc "contextless" () -> runtime.Context {
	context = os.init()
	assert(thread_infos == nil)

	mem.init_page_fault_handler()
	global_allocator_buffer := mem.page_alloc(VIRTUAL_MEMORY_TO_RESERVE, false)
	assert(global_allocator_buffer != nil)
	mem.half_fit_allocator_init(&global_allocator_data, global_allocator_buffer)
	context.allocator = runtime.Allocator{mem.half_fit_allocator_proc, &global_allocator_data}

	for thread_index in 0 ..< os.info.logical_core_count {
		temporary_allocator_buffer := mem.page_alloc(VIRTUAL_MEMORY_TO_RESERVE, false)
		assert(temporary_allocator_buffer != nil)
		append(&thread_infos, ThreadInfo{})
		thread_info := thread_infos[len(thread_infos) - 1]
		thread_info.temporary_allocator_data = mem.arena_allocator(temporary_allocator_buffer)
		thread_info.ctx = os.empty_context()
		thread_info.index = u32(thread_index)

		ctx := &thread_info.ctx
		ctx.allocator = runtime.Allocator{mem.half_fit_allocator_proc, &global_allocator_data}
		ctx.temp_allocator = runtime.Allocator{mem.arena_allocator_proc, &thread_info.temporary_allocator_data}
		ctx.user_index = thread_index
		append(&thread_infos, thread_info)
	}

	fmt.print("AYAYA.INIT\n")
	return thread_context(0)
}
free_all_for_tests :: proc() {
	delete(thread_infos)
}

thread_context :: proc "contextless" (user_index: int) -> runtime.Context {
	return thread_infos[user_index].ctx
}
