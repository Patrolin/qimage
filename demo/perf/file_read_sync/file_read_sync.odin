// odin run demo/perf/file_read_sync
package file_read_sync
import "../utils"
import "core:fmt"
import core_os "core:os"
import win "core:sys/windows"
import "core:time"

main :: proc() {
	// setup
	win.SetConsoleOutputCP(win.CODEPAGE(win.CP_UTF8))
	timings: utils.Timings
	utils.start_timing(&timings)
	// read file
	file, errno := core_os.open("demo/perf/make_1gb_file/1gb_file.txt", core_os.O_RDONLY)
	utils.end_timing(&timings, "open file")
	buffer := make([]u8, 1024 * 1024 * 1024)
	utils.end_timing(&timings, "buffer := make([]u8, 1GB)")
	core_os.read(file, buffer)
	utils.end_timing(&timings, "read file")

	utils.print_timings(timings)
}
