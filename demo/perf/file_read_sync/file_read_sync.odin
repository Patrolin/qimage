// odin run demo/perf/file_read_sync
package file_read_sync
import "../../../lib/math"
import "core:fmt"
import "core:os"
import "core:strings"

printTime :: proc(t1, t2: u64) {
	time := f64(t2 - t1) / 3e9
	fmt.printf("cycles: %v, time: %.5f s\n", t2 - t1, time)
}
main :: proc() {
	t1 := math.cycles()
	file, errno := os.open("1gb_file.txt", os.O_RDONLY)
	t2 := math.cycles()
	printTime(t1, t2)
	buffer := make([]u8, 1024 * 1024 * 1024)
	t3 := math.cycles()
	printTime(t2, t3)
	os.read(file, buffer)
	t4 := math.cycles()
	printTime(t3, t4)
}
