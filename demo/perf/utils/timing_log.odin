package perf_utils
import "base:intrinsics"
import "core:fmt"
import "core:strings"
import "core:time"

TimingLog :: struct {
	start_time: i64,
	items:      [dynamic]TimingLogItem,
}
TimingLogItem :: struct {
	msg:  string,
	time: i64,
}

make_log :: proc() -> (log: TimingLog) {
	log.start_time = intrinsics.read_cycle_counter()
	return
}
log_time :: #force_inline proc(log: ^TimingLog, msg: string) {
	append(&log.items, TimingLogItem{msg, intrinsics.read_cycle_counter()})
}
logf :: #force_inline proc(log: ^TimingLog, format: string, args: ..any) {
	sb := strings.builder_make()
	fmt.sbprintf(&sb, format, ..args)
	append(&log.items, TimingLogItem{strings.to_string(sb), -1})
}

print_timing_log :: proc(log: TimingLog) {
	prev_time := log.start_time
	for item in log.items {
		if item.time == -1 {
			fmt.printfln("  %v", item.msg)
		}
	}
	for item in log.items {
		if item.time != -1 {
			d_cycles := item.time - prev_time
			d_nanoseconds := f64(d_cycles) * (f64(1e9) / f64(4e9))
			fmt.printfln("- %v, %v", item.msg, time.Duration(d_nanoseconds))
			prev_time = item.time
		}
	}
}
