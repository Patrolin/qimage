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
	log := utils.make_log()
	// read file
	file, errno := core_os.open("demo/perf/make_test_files/1gb_file.txt", core_os.O_RDONLY)
	utils.log_time(&log, "open file")
	buffer := make([]u8, 1024 * 1024 * 1024)
	utils.log_time(&log, "buffer := make([]u8, 1GB)")
	core_os.read(file, buffer)
	utils.log_time(&log, "read file")
	// print log
	utils.print_timing_log(log)
}
