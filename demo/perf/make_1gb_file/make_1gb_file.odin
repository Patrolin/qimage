// odin run demo/perf/make_1gb_file
package make_1gb_file
import "core:fmt"
import core_os "core:os"
import "core:strings"

main :: proc() {
	file, errno := core_os.open("demo/perf/make_1gb_file/1gb_file.txt", core_os.O_CREATE)
	string_to_write := strings.repeat("aaaabbb\n", 512)
	assert(len(string_to_write) == 4096)
	REPEAT_COUNT := 1024 * 1024 * 1024 / 4096
	for i in 0 ..< REPEAT_COUNT {
		core_os.write(file, transmute([]u8)string_to_write)
	}
}
