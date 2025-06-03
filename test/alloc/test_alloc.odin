package test_alloc
import "../../utils/alloc"
import "../../utils/math"
import "../../utils/os"
import "../../utils/test"
import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import win "core:sys/windows"
import "core:testing"
import "core:time"

// !TODO: get -no-crt -no-thread-local -default-to-nil-allocator -radlink to work

check_was_allocated :: proc(ptr: ^int, name: string, value: int, loc := #caller_location) {
	test.expectf(ptr != nil, "Failed was_allocated, %v: %v", name, ptr, loc = loc)
	test.expectf(ptr^ == 0, "Failed was_allocated - should start zeroed", loc = loc)
	ptr^ = value
	test.expectf(ptr^ == value, "Failed was_allocated", loc = loc)
}
check_still_allocated :: proc(ptr: ^int, name: string, value: int, loc := #caller_location) {
	test.expectf(ptr != nil && ptr^ == value, "Failed still_allocated, %v: %v at %v", name, ptr^, ptr, loc = loc)
}

@(test)
test_page_alloc :: proc(t: ^testing.T) {
	test.start_test(t)

	os.init()
	data := alloc.page_alloc(1 * math.BYTES)
	test.expectf(data != nil, "Failed to page_alloc(1 B), data: %v", data)
	data = alloc.page_alloc_aligned(64 * math.KIBI_BYTES, 64 * math.KIBI_BYTES)
	test.expectf(data != nil, "Failed to page_alloc_aligned(64 kiB, 64 kiB), data: %v", data)
	data_ptr := &data[0]
	low_bits := uintptr(data_ptr) & math.low_mask(uintptr(16))
	test.expectf(low_bits == 0, "Failed to page_alloc_aligned(64 kiB, 64 kiB), low_bits: %v", low_bits)

	test.end_test()
}

@(test)
test_half_fit_allocator :: proc(t: ^testing.T) {
	test.start_test(t)

	buffer := alloc.page_alloc(alloc.PAGE_SIZE)
	assert(uintptr(raw_data(buffer)) & uintptr(63) == 0)
	half_fit: alloc.HalfFitAllocator
	alloc.half_fit_allocator_init(&half_fit, buffer)
	context.allocator = runtime.Allocator {
		data      = &half_fit,
		procedure = alloc.half_fit_allocator_proc,
	}
	alloc.half_fit_check_blocks("1.", &half_fit)

	x_raw := new([2]int)
	assert(uintptr(rawptr(x_raw)) & 63 == 0)
	x := (^int)(x_raw)
	check_was_allocated(x, "x", 13)
	alloc.half_fit_check_blocks("2.", &half_fit)

	y_raw := new(int)
	assert(uintptr(rawptr(y_raw)) & 63 == 0)
	y := (^int)(y_raw)
	check_was_allocated(y, "y", 7)
	check_still_allocated(x, "x", 13)
	alloc.half_fit_check_blocks("3.", &half_fit)

	free(x)
	alloc.half_fit_check_blocks("4.", &half_fit)

	free(y)
	alloc.half_fit_check_blocks("5.", &half_fit)

	arr: [dynamic]int
	N :: 16
	for i in 0 ..< N {append(&arr, i)}
	alloc.half_fit_check_blocks("6.", &half_fit)

	for i in 0 ..< N {append(&arr, N + i)}
	alloc.half_fit_check_blocks("7.", &half_fit)
	for i in 0 ..< 2 * N {
		test.expectf(arr[i] == i, "Failed to resize array: %v", arr)
	}

	alloc.page_free(raw_data(buffer))
	test.end_test()
}

@(test)
test_default_context :: proc(t: ^testing.T) {
	test.start_test(t)
	debug_temp_allocator := context.temp_allocator

	os.init()
	context = alloc.init()
	temp_allocator_to_check := context.temp_allocator
	context.temp_allocator = debug_temp_allocator

	// allocator
	x := new(int)
	check_was_allocated(x, "x", 13)
	free(x)

	// temp_allocator
	if temp_allocator_to_check.procedure != nil {
		y := new(int, allocator = temp_allocator_to_check)
		check_was_allocated(y, "y", 7)
		free(y, allocator = temp_allocator_to_check)
	}

	// reserve on page fault
	ptr := ([^]byte)(win.VirtualAlloc(nil, 4096, win.MEM_RESERVE, win.PAGE_READWRITE))
	check_was_allocated((^int)(ptr), "ptr", 13)

	alloc.free_all_for_tests()
	test.end_test()
}

@(test)
test_pool_allocator :: proc(t: ^testing.T) {
	test.start_test(t)

	buffer := alloc.page_alloc(alloc.PAGE_SIZE)
	pool_64b := alloc.pool_allocator(buffer, 8)

	x := (^int)(alloc.pool_alloc(&pool_64b))
	check_was_allocated(x, "x", 13)

	y := (^int)(alloc.pool_alloc(&pool_64b))
	check_was_allocated(y, "y", 7)
	check_still_allocated(x, "x", 13)

	alloc.pool_free(&pool_64b, x)
	alloc.pool_free(&pool_64b, y)

	test.end_test()
}

@(test)
test_map :: proc(t: ^testing.T) {
	test.start_test(t)

	os.init()
	context = alloc.init()
	m: alloc.Map(string, int) = {}

	alloc.addKey(&m, "a")^ = 1
	alloc.addKey(&m, "b")^ = 2
	valueA, okA := alloc.getKey(&m, "a")
	test.expectf(okA && (valueA^ == 1), "m[\"a\"] = %v", valueA^)
	valueB, okB := alloc.getKey(&m, "b")
	test.expectf(okB && (valueB^ == 2), "m[\"b\"] = %v", valueB^)
	valueC, okC := alloc.getKey(&m, "c")
	test.expectf(!okC && (valueC^ == {}), "m[\"b\"] = %v", valueC^)

	alloc.removeKey(&m, "a")
	alloc.removeKey(&m, "b")
	alloc.removeKey(&m, "c")
	valueA, okA = alloc.getKey(&m, "a")
	test.expectf(!okA && (valueA^ == {}), "m[\"a\"] = %v", valueA^)
	valueB, okB = alloc.getKey(&m, "b")
	test.expectf(!okA && (valueB^ == {}), "m[\"b\"] = %v", valueB^)
	valueC, okC = alloc.getKey(&m, "c")
	test.expectf(!okA && (valueC^ == {}), "m[\"c\"] = %v", valueC^)

	alloc.delete_map_like(&m)

	alloc.free_all_for_tests()
	test.end_test()
}

@(test)
test_set :: proc(t: ^testing.T) {
	test.start_test(t)

	os.init()
	context = alloc.init()
	m: alloc.Set(string) = {}

	alloc.addKey(&m, "a")
	alloc.addKey(&m, "b")
	okA := alloc.getKey(&m, "a")
	test.expectf(okA, "m[\"a\"] = %v", okA)
	okB := alloc.getKey(&m, "b")
	test.expectf(okB, "m[\"b\"] = %v", okB)
	okC := alloc.getKey(&m, "c")
	test.expectf(!okC, "m[\"b\"] = %v", okC)

	alloc.removeKey(&m, "a")
	alloc.removeKey(&m, "b")
	alloc.removeKey(&m, "c")
	okA = alloc.getKey(&m, "a")
	test.expectf(!okA, "m[\"a\"] = %v", okA)
	okB = alloc.getKey(&m, "b")
	test.expectf(!okB, "m[\"b\"] = %v", okB)
	okC = alloc.getKey(&m, "c")
	test.expectf(!okC, "m[\"c\"] = %v", okC)
	alloc.delete_map_like(&m)

	alloc.free_all_for_tests()
	test.end_test()
}
