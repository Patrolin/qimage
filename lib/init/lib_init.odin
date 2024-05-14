/*
lib_init
emptyContext :: proc "contextless" ()
defaultContext :: proc "contextless" ()
init :: proc "contextless" ()
lib_os_info
initOsInfo :: proc "contextless" ()
time :: proc()
lib_alloc_page
pageAlloc :: proc(size: math.bytes) -> []u8
pageFree :: proc(ptr: rawptr)
lib_alloc_partition
partitionAlloc :: proc(partition: ^Partition, chunk_size: math.bytes) -> []u8
partitionAlloc :: proc(partition: ^Partition, fraction: f64) -> []u8
lib_alloc_slab
bootstrapSlabCache :: proc(data: []u8, slot_size: u16)
slabAlloc :: proc(slab: ^SlabCache, size: int, zero: bool = true) -> rawptr
slabFree :: proc(slab: ^SlabCache, old_ptr: rawptr)
slabRealloc :: proc(old_slab: ^SlabCache, old_ptr: rawptr, slab: ^SlabCache, size: int, zero: bool = true) -> rawptr
slabFreeAll :: proc(slab: ^SlabCache)
slabAllocator :: proc() -> mem.Allocator
lib_threads
initThreads :: proc()
addWorkItem :: proc(queue: ^WorkQueue, work: WorkItem)
joinQueue :: proc(queue: ^WorkQueue)
lib_threads_xx
createThread :: proc(stack_size: uint, thread_proc: proc "stdcall" (data: rawptr) -> u32, param: rawptr)
createSemaphore :: proc(max_count: i32) -> OsSemaphore
incrementSemaphore :: proc(semaphore: OsSemaphore)
waitForSemaphore :: proc(semaphore: OsSemaphore)
waitForThreadsToSleep :: proc()
*/
package lib_init
import "../math"
import "core:fmt"
import "core:intrinsics"
import "core:runtime"
import "core:testing"
import "core:time"

DefaultAllocators :: struct {
	allocator: runtime.Allocator,
}
emptyContext :: proc "contextless" () -> runtime.Context {
	ctx := runtime.default_context()
	return {assertion_failure_proc = ctx.assertion_failure_proc, logger = ctx.logger}
}
defaultContext :: proc "contextless" () -> runtime.Context {
	@(static)
	default_allocators := DefaultAllocators{}
	context = emptyContext()
	if default_allocators.allocator.procedure == nil {
		default_allocators.allocator = slabAllocator()
	}
	context.allocator = default_allocators.allocator
	context.temp_allocator = slabAllocator()
	return context
}
init :: proc "contextless" () -> runtime.Context {
	initOsInfo()
	context = defaultContext()
	initThreads()
	return context
}

// odin test lib/init
@(test)
testPageAlloc :: proc(t: ^testing.T) {
	initOsInfo()
	data := pageAlloc(math.bytes(1))
	testing.expectf(t, data != nil, "Failed to pageAlloc 1 byte, data: %v", data)
	data = pageAlloc(math.kibiBytes(64))
	testing.expectf(t, data != nil, "Failed to pageAlloc 64 kiB, data: %v", data)
}

@(test)
testPartitionAlloc :: proc(t: ^testing.T) {
	initOsInfo()
	partition := Partition {
		data = pageAlloc(math.kibiBytes(64)),
	}
	testing.expectf(
		t,
		partition.data != nil,
		"Failed to pageAlloc 64 kiB, data: %v",
		partition.data,
	)
	part1 := partitionAlloc(&partition, math.bytes(64))
	testing.expectf(t, len(part1) == 64, "Failed to partitionAlloc 64 B, part1: %v", part1)
	part2 := partitionAlloc(&partition, 0.5)
	testing.expectf(
		t,
		len(part2) == int(math.kibiBytes(32)),
		"Failed to partitionAlloc 50%, part2: %v",
		part2,
	)
}

@(test)
testSlabAlloc :: proc(t: ^testing.T) {
	initOsInfo()
	slab_data := pageAlloc(math.kibiBytes(64))
	slab := bootstrapSlabCache(slab_data, 64)
	slab2_data := pageAlloc(math.kibiBytes(64))
	slab2 := bootstrapSlabCache(slab, slab2_data, 8)
	x := cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, x != nil, "Failed to allocate, x: %v", x)
	x^ = 13
	testing.expect(t, x^ == 13, "Failed to allocate")
	slabFree(slab, x)
	y := cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, y == x, "Failed to free, x: %v, y: %v", x, y)
	z := cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, z != y, "Failed to allocate, y: %v, z: %v", y, z)
	slabFreeAll(slab)
	y = cast(^u8)slabAlloc(slab, 1)
	testing.expectf(t, y == x, "Failed to free all, x: %v, y: %v", x, y)
	y = cast(^u8)slabRealloc(slab, x, slab2, 1)
	testing.expectf(t, (y != x) && (y != z), "Failed to realloc, x: %v, y: %v, z: %v", x, y, z)
}

@(test)
testDefaultContext :: proc(t: ^testing.T) {
	initOsInfo()
	context = defaultContext()
	x := new(int)
	testing.expectf(t, x != nil, "Failed to allocate, x: %v", x)
	x^ = 13
	testing.expect(t, x^ == 13, "Failed to allocate")
	free(x)
}

@(test)
testWorkQueue :: proc(t: ^testing.T) {
	initOsInfo()
	context = defaultContext()
	thread_infos := initThreads()
	total_count := 3
	checksum := total_count
	for i in 0 ..< total_count {
		addWorkItem(&work_queue, {procedure = checkWorkQueue, data = &checksum})
	}
	joinQueue(&work_queue)
	got_checksum := intrinsics.atomic_load(&checksum)
	testing.expectf(t, got_checksum == 0, "checksum should be 0, got: %v", got_checksum)
	time.sleep(time.Millisecond)
}
checkWorkQueue :: proc(data: rawptr) {
	//fmt.printfln("thread %v: checkWorkQueue", context.user_index)
	data := (^int)(data)
	intrinsics.atomic_add(data, -1)
}
