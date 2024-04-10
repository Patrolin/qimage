package lib_alloc
import "../os"
import "core:fmt"
import "core:runtime"
import "core:testing"

bytes :: distinct int
kibiBytes :: proc(v: int) -> bytes {return bytes(1024 * v)}
mebiBytes :: proc(v: int) -> bytes {return bytes(1024 * 1024 * v)}
gibiBytes :: proc(v: int) -> bytes {return bytes(1024 * 1024 * 1024 * v)}

DefaultAllocators :: struct {
	allocator: runtime.Allocator,
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
	os.initInfo() // NOTE: we pretend we have allocators, since they're not used...
	if default_allocators.allocator.procedure == nil {
		default_allocators.allocator = slabAllocator()
	}
	ctx.allocator = default_allocators.allocator
	ctx.temp_allocator.procedure = runtime.default_temp_allocator_proc
	ctx.temp_allocator.data = &runtime.global_default_temp_allocator_data // NOTE: get temp_allocator for current thread
	return ctx
}

@(test)
testPageAlloc :: proc(t: ^testing.T) {
	os.initInfo()
	data := pageAlloc(bytes(1))
	testing.expectf(t, data != nil, "Failed to pageAlloc 1 byte, data: %v", data)
	data = pageAlloc(kibiBytes(64))
	testing.expectf(t, data != nil, "Failed to pageAlloc 64 kiB, data: %v", data)
}

@(test)
testPartitionAlloc :: proc(t: ^testing.T) {
	os.initInfo()
	partition := Partition {
		data = pageAlloc(kibiBytes(64)),
	}
	testing.expectf(
		t,
		partition.data != nil,
		"Failed to pageAlloc 64 kiB, data: %v",
		partition.data,
	)
	part1 := partitionAlloc(&partition, bytes(64))
	testing.expectf(t, len(part1) == 64, "Failed to partitionAlloc 64 B, part1: %v", part1)
	part2 := partitionAlloc(&partition, 0.5)
	testing.expectf(
		t,
		len(part2) == int(kibiBytes(32)),
		"Failed to partitionAlloc 50%, part2: %v",
		part2,
	)
}

@(test)
testSlabAlloc :: proc(t: ^testing.T) {
	os.initInfo()
	slab_data := pageAlloc(kibiBytes(64))
	slab := bootstrapSlabCache(slab_data, 64)
	slab2_data := pageAlloc(kibiBytes(64))
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
	context = defaultContext()
	x := new(int)
	testing.expectf(t, x != nil, "Failed to allocate, x: %v", x)
	x^ = 13
	testing.expect(t, x^ == 13, "Failed to allocate")
	free(x)
}
