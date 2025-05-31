package lib_alloc
import "../math"
import "../os"
import "../test"
import "base:intrinsics"
import "core:fmt"
import "core:testing"
import "core:time"

check_was_allocated :: proc(t: ^testing.T, ptr: ^int, name: string, value: int, loc := #caller_location) {
	testing.expectf(t, ptr != nil, "Failed was_allocated, %v: %v", name, ptr, loc = loc)
	ptr^ = value
	testing.expect(t, ptr^ == value, "Failed was_allocated", loc = loc)
}
check_still_allocated :: proc(t: ^testing.T, ptr: ^int, name: string, value: int, loc := #caller_location) {
	testing.expectf(t, ptr != nil && ptr^ == value, "Failed still_allocated, %v: %v at %v", name, ptr^, ptr, loc = loc)
}

@(test)
tests_defaultContext :: proc(t: ^testing.T) {
	test.start_test(t)

	debug_temp_allocator := context.temp_allocator
	os.initInfo()
	context = defaultContext(0)
	temp_allocator_to_check := context.temp_allocator
	context.temp_allocator = debug_temp_allocator

	// allocator
	x := new(int)
	check_was_allocated(t, x, "x", 13)
	free(x)

	// temp_allocator
	if temp_allocator_to_check.procedure != nil {
		y := new(int, allocator = temp_allocator_to_check)
		check_was_allocated(t, y, "y", 7)
		free(y, allocator = temp_allocator_to_check)
	}

	test.end_test()
}

@(test)
tests_pageAlloc :: proc(t: ^testing.T) {
	os.initInfo()
	data := page_alloc(1 * math.BYTES)
	testing.expectf(t, data != nil, "Failed to page_alloc 1 byte, data: %v", data)
	data = page_alloc_aligned(64 * math.KIBI_BYTES)
	testing.expectf(t, data != nil, "Failed to page_alloc_aligned 64 kiB, data: %v", data)
	data_ptr := &data[0]
	low_bits := uintptr(data_ptr) & math.low_mask(uintptr(16))
	testing.expectf(t, low_bits == 0, "Failed to page_alloc_aligned 64 kiB, low_bits: %v", low_bits)
}

@(test)
tests_half_fit_allocator :: proc(t: ^testing.T) {
	test.start_test(t)

	buffer := make([]u8, 1000)
	half_fit: HalfFitAllocator
	half_fit_allocator_init(&half_fit, buffer)
	a := _half_fit_merge_size_and_flags(false, true, 10)
	is_used, is_last, size := _half_fit_split_size_and_flags(a)
	half_fit_check_blocks(t, "1.", &half_fit, buffer)

	x_raw, _ := half_fit_alloc(&half_fit, size_of(int))
	x := (^int)(x_raw)
	check_was_allocated(t, x, "x", 13)
	half_fit_check_blocks(t, "2.", &half_fit, buffer)

	y_raw, _ := half_fit_alloc(&half_fit, size_of(int))
	y := (^int)(y_raw)
	check_was_allocated(t, y, "y", 7)
	check_still_allocated(t, x, "x", 13)
	half_fit_check_blocks(t, "3.", &half_fit, buffer)

	half_fit_free(&half_fit, x)
	half_fit_check_blocks(t, "4.", &half_fit, buffer)

	half_fit_free(&half_fit, y)
	half_fit_check_blocks(t, "5.", &half_fit, buffer)
	free(&buffer[0])

	test.end_test()
}

@(test)
tests_pool_allocator :: proc(t: ^testing.T) {
	pool_64b := pool_allocator(8)
	x := (^int)(pool_alloc(&pool_64b))
	check_was_allocated(t, x, "x", 13)
	y := (^int)(pool_alloc(&pool_64b))
	check_was_allocated(t, y, "y", 7)
	check_still_allocated(t, x, "x", 13)
	pool_free(&pool_64b, x)
	pool_free(&pool_64b, y)
}
/*
@(test)
tests_anyAllocator :: proc(t: ^testing.T) {
	os.initInfo()
	context.allocator = slabAllocator()
	allocator := (^SlabAllocator)(context.allocator.data)
	x := new(u8)
	get_slab_header :: proc(allocator: ^SlabAllocator, slab_index: u16) -> SlabHeader {
		free_ptr := allocator.free_slots[slab_index]
		return allocator.headers[free_ptr]
	}
	testing.expectf(
		t,
		x != nil,
		"Failed to allocate, x: %v\nallocator: %v\nheader: %v",
		x,
		allocator,
		get_slab_header(allocator, 0),
	)
	x^ = 13
	testing.expectf(
		t,
		x^ == 13,
		"Failed to allocate\nallocator: %v\nheader: %v",
		allocator,
		get_slab_header(allocator, 0),
	)
	free(x)
	y := new(u8)
	testing.expectf(
		t,
		y == x,
		"Failed to free, x: %v, y: %v\nallocator: %v\nheader: %v",
		x,
		y,
		allocator,
		get_slab_header(allocator, 0),
	)
	z := new(u8)
	testing.expectf(
		t,
		z != y,
		"Failed to allocate, y: %v, z: %v\nallocator: %v\nheader: %v",
		y,
		z,
		allocator,
		get_slab_header(allocator, 0),
	)
	/*
	free_all()
	y = new(x)
	testing.expectf(t, y == x, "Failed to free_all, x: %v, y: %v", x, y)
	*/
}
*/
@(test)
tests_map :: proc(t: ^testing.T) {
	os.initInfo()
	context = defaultContext(0)
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
	context = defaultContext(0)
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
	delete_map_like(&m)
}
// TODO!: get -no-crt -default-to-nil-allocator to work
