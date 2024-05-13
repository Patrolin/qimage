package lib_init
import "../math"
import "core:fmt"
import "core:intrinsics"
import "core:runtime"
import "core:testing"

// pageAlloc :: proc(size: math.bytes) -> []u8 {
// pageFree :: proc(ptr: win.LPVOID) {

// initOsInfo()
// time() -> f64

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
	ctx := emptyContext()
	context = ctx
	if default_allocators.allocator.procedure == nil {
		default_allocators.allocator = slabAllocator() // TODO: mutex this allocator
	}
	ctx.allocator = default_allocators.allocator
	ctx.temp_allocator.procedure = runtime.default_temp_allocator_proc // TODO: custom allocator here
	ctx.temp_allocator.data = &runtime.global_default_temp_allocator_data // NOTE: get temp_allocator for current thread
	return ctx
}

OsInfo :: struct {
	timer_resolution:         f64,
	min_page_size:            int,
	min_page_size_mask:       int,
	min_large_page_size:      int,
	min_large_page_size_mask: int,
	logical_core_count:       int,
}
os_info: OsInfo

init :: proc() -> runtime.Context {
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
	initThreads()
	checksum: int = 3
	for i := 0; i < checksum; i += 1 {
		addWorkItem(&work_queue, {procedure = checkWorkQueue, data = &checksum})
	}
	joinFrontQueue(&work_queue)
	got_checksum := intrinsics.atomic_load(&checksum)
	fmt.printfln("got_checksum: %v", got_checksum)
	testing.expectf(t, got_checksum == 0, "checksum should be 0, got: %v", got_checksum)
}
checkWorkQueue :: proc(data: rawptr) {
	data := (^int)(data)
	intrinsics.atomic_add(data, -1)
	fmt.printfln("hello, %v", context.user_index)
}
