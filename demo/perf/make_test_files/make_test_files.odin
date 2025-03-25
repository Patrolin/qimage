// odin run demo/perf/make_1gb_file
package make_1gb_file
import "../utils"
import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {
	// a 1 GB file
	file, errno := os.open(
		utils.sbprint_file_path("%v/1gb_file.txt", utils.TEST_FILE_PATH),
		os.O_CREATE,
	)
	assert(errno == nil)
	string_to_write := strings.repeat("aaaabbb\n", 512)
	assert(len(string_to_write) == 4096)
	REPEAT_COUNT := 1024 * 1024 * 1024 / 4096
	for i in 0 ..< REPEAT_COUNT {
		os.write(file, transmute([]u8)string_to_write)
	}
	// 1024 4KB files
	for i in 0 ..< utils.SMALL_TEST_FILE_COUNT {
		file_path := utils.sbprint_file_path("%v/small_file_%v.txt", utils.TEST_FILE_PATH, i)
		file, errno := os.open(file_path, os.O_CREATE)
		assert(errno == nil)
		os.write(file, transmute([]u8)string_to_write)
	}
}
