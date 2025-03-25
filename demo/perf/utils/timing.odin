package perf_utils
import "base:intrinsics"
import "core:fmt"
import "core:time"

Timings :: struct {
	start:   i64,
	timings: [dynamic]Timing,
}
Timing :: struct {
	msg:  string,
	time: i64,
}
start_timing :: #force_inline proc(timings: ^Timings) {
	timings.start = intrinsics.read_cycle_counter()
}
end_timing :: #force_inline proc(timings: ^Timings, msg: string) {
	append(&timings.timings, Timing{msg, intrinsics.read_cycle_counter()})
}
cycles_to_nanoseconds :: proc(cycles: i64) -> f64 {
	return f64(cycles) * (f64(1e9) / f64(4e9))
}
print_timings :: proc(timings: Timings) {
	prev_time := timings.start
	for timing in timings.timings {
		d_cycles := timing.time - prev_time
		fmt.printfln("- %v, %v", timing.msg, time.Duration(cycles_to_nanoseconds(d_cycles)))
		prev_time = timing.time
	}
}
