package perf_utils
import "core:fmt"
import "core:strings"

TEST_FILE_PATH :: "demo/perf/make_test_files/files"
//SMALL_TEST_FILE_COUNT :: 8
SMALL_TEST_FILE_COUNT :: 1024
sbprint_file_path :: proc(format: string, args: ..any) -> string {
	sb := strings.builder_make()
	fmt.sbprintf(&sb, format, ..args)
	file_path := strings.to_string(sb)
	return file_path
}
