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
test_pool_alloc :: proc(t: ^testing.T) {
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
