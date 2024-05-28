// odin run demo/perf/file_read_sync
package file_read_sync
import "core:fmt"
import core_os "core:os"
import "core:time"

prev_time: time.Time
startTiming :: proc() {
	prev_time = time.now()
}
endTiming :: proc() {
	current_time := time.now()
	fmt.printf("-- timing: %.3f s\n", f64(time.diff(prev_time, current_time)) / f64(time.Second))
	prev_time = current_time
}

main :: proc() {
	startTiming()
	file, errno := core_os.open("demo/perf/make_1gb_file/1gb_file.txt", core_os.O_RDONLY)
	endTiming()
	buffer := make([]u8, 1024 * 1024 * 1024)
	endTiming()
	core_os.read(file, buffer)
	endTiming()
}
