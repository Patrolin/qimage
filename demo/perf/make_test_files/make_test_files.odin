// odin run demo/perf/make_1gb_file
package make_1gb_file
import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {
	file, errno := os.open("demo/perf/make_test_files/1gb_file.txt", os.O_CREATE)
	assert(errno == nil)
	string_to_write := strings.repeat("aaaabbb\n", 512)
	assert(len(string_to_write) == 4096)
	REPEAT_COUNT := 1024 * 1024 * 1024 / 4096
	for i in 0 ..< REPEAT_COUNT {
		os.write(file, transmute([]u8)string_to_write)
	}
	SMALL_FILE_COUNT :: 8
	for i in 0 ..< SMALL_FILE_COUNT {
		sb := strings.builder_make()
		fmt.sbprintf(&sb, "demo/perf/make_test_files/small_file_%v.txt", i)
		file_path := strings.to_string(sb)
		file, errno := os.open(file_path, os.O_CREATE)
		assert(errno == nil)
		os.write(file, transmute([]u8)string_to_write)
	}
}
