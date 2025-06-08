package test_alloc
import "../../../utils/alloc"
import "../../../utils/math"
import "../../../utils/mem"
import "../../../utils/os"
import "../../../utils/test"
import "../../../utils/threads"
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
	context = threads.init()

	// allocator
	x := new(int)
	fmt.print("ayaya.new\n")
	test.expect_was_allocated(x, "x", 13)
	fmt.print("ayaya.new.expect\n")
	free(x)
	fmt.print("ayaya.free\n")

	// temp_allocator
	arena := (^mem.ArenaAllocator)(context.temp_allocator.data)
	fmt.printfln("context.temp_allocator.data: %v", len(arena.buffer))
	y := new(int, allocator = context.temp_allocator)
	test.expect_was_allocated(y, "y", 7)
	free(y, allocator = context.temp_allocator)

	// reserve on page fault
	ptr := ([^]byte)(win.VirtualAlloc(nil, 4096, win.MEM_RESERVE, win.PAGE_READWRITE))
	test.expect_was_allocated((^int)(ptr), "ptr", 13)

	threads.free_all_for_tests()
	test.end_test()
}

@(test)
test_map :: proc(t: ^testing.T) {
	test.start_test(t)

	context = threads.init()
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

	threads.free_all_for_tests()
	test.end_test()
}

@(test)
test_set :: proc(t: ^testing.T) {
	test.start_test(t)

	context = threads.init()
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

	threads.free_all_for_tests()
	test.end_test()
}
