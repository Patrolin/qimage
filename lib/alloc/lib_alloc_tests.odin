package lib_alloc
import "../math"
import "../os"
import "base:intrinsics"
import "core:fmt"
import "core:testing"

@(test)
tests_defaultContext :: proc(t: ^testing.T) {
	os.initInfo()
	context = defaultContext()
	x := new(int)
	testing.expectf(t, x != nil, "Failed to allocate, x: %v", x)
	x^ = 13
	testing.expect(t, x^ == 13, "Failed to allocate")
	free(x)
}
@(test)
tests_pageAlloc :: proc(t: ^testing.T) {
	os.initInfo()
	data := pageAlloc(math.bytes(1))
	testing.expectf(t, data != nil, "Failed to pageAlloc 1 byte, data: %v", data)
	data = pageAlloc(math.kibiBytes(64))
	testing.expectf(t, data != nil, "Failed to pageAlloc 64 kiB, data: %v", data)
}
@(test)
tests_partitionAlloc :: proc(t: ^testing.T) {
	os.initInfo()
	partition := Partition {
		data = pageAlloc(math.kibiBytes(64)),
	}
	testing.expectf(
		t,
		partition.data != nil,
		"Failed to pageAlloc 64 kiB, data: %v",
		partition.data,
	)
	part1 := partitionBy(&partition, math.bytes(64))
	testing.expectf(t, len(part1) == 64, "Failed to partitionAlloc 64 B, part1: %v", part1)
	part2 := partitionBy(&partition, 0.5)
	testing.expectf(
		t,
		len(part2) == int(math.kibiBytes(32)),
		"Failed to partitionAlloc 50%, part2: %v",
		part2,
	)
}
@(test)
tests_slabAlloc :: proc(t: ^testing.T) {
	os.initInfo()
	slab_data := pageAlloc(math.kibiBytes(64))
	slab := slabCache(slab_data, 64)
	slab2_data := pageAlloc(math.kibiBytes(64))
	slab2 := slabCache(slab, slab2_data, 8)
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
tests_map :: proc(t: ^testing.T) {
	os.initInfo()
	context = defaultContext()
	m: Map(string, int) = {}
	addKey(&m, "a")^ = 1
	addKey(&m, "b")^ = 2
	valueA, okA := getKey(&m, "a")
	testing.expectf(t, okA && (valueA^ == 1), "m[\"a\"] = %v", valueA^)
	valueB, okB := getKey(&m, "b")
	testing.expectf(t, okB && (valueB^ == 2), "m[\"b\"] = %v", valueB^)
	valueC, okC := getKey(&m, "c")
	testing.expectf(t, !okC && (valueC^ == {}), "m[\"b\"] = %v", valueC^)
	removeKey(&m, "a")
	removeKey(&m, "b")
	removeKey(&m, "c")
	valueA, okA = getKey(&m, "a")
	testing.expectf(t, !okA && (valueA^ == {}), "m[\"a\"] = %v", valueA^)
	delete_map_like(&m)
}
@(test)
tests_set :: proc(t: ^testing.T) {
	os.initInfo()
	context = defaultContext()
	m: Set(string) = {}
	addKey(&m, "a")
	addKey(&m, "b")
	okA := getKey(&m, "a")
	testing.expectf(t, okA, "m[\"a\"] = %v", okA)
	okB := getKey(&m, "b")
	testing.expectf(t, okB, "m[\"b\"] = %v", okB)
	okC := getKey(&m, "c")
	testing.expectf(t, !okC, "m[\"b\"] = %v", okC)
	removeKey(&m, "a")
	removeKey(&m, "b")
	removeKey(&m, "c")
	okA = getKey(&m, "a")
	testing.expectf(t, !okA, "m[\"a\"] = %v", okA)
	fmt.printfln("free(m.slots)")
	free(m.slots)
}
// TODO!: get -no-crt -default-to-nil-allocator to work
