package perf_utils
import "../../../utils/thread"
import "base:intrinsics"
import "core:fmt"
import "core:strings"
import "core:time"

TimingLog :: struct {
	start_time: i64,
	items:      [dynamic]TimingLogItem,
	mutex:      thread.Mutex,
}
TimingLogItem :: struct {
	msg:  string,
	time: i64,
	type: TimingLogItemType,
}
TimingLogItemType :: enum u32 {
	Group,
	Log,
	Time,
}

make_log :: proc() -> (log: TimingLog) {
	log.start_time = intrinsics.read_cycle_counter()
	return
}
log_group :: #force_inline proc(log: ^TimingLog, msg: string) {
	append(&log.items, TimingLogItem{msg, 0, .Group})
}
log_groupf :: #force_inline proc(log: ^TimingLog, format: string, args: ..any) {
	sb := strings.builder_make()
	fmt.sbprintf(&sb, format, ..args)
	append(&log.items, TimingLogItem{strings.to_string(sb), 0, TimingLogItemType.Group})
}
log :: #force_inline proc(log: ^TimingLog, msg: string) {
	append(&log.items, TimingLogItem{msg, 0, .Log})
}
logf :: #force_inline proc(log: ^TimingLog, format: string, args: ..any) {
	sb := strings.builder_make()
	fmt.sbprintf(&sb, format, ..args)
	append(&log.items, TimingLogItem{strings.to_string(sb), 0, .Log})
}
log_time :: #force_inline proc(log: ^TimingLog, msg: string) {
	thread.getMutex(&log.mutex)
	append(&log.items, TimingLogItem{msg, intrinsics.read_cycle_counter(), .Time})
	thread.releaseMutex(&log.mutex)
}
log_timef :: #force_inline proc(log: ^TimingLog, format: string, args: ..any) {
	thread.getMutex(&log.mutex)
	sb := strings.builder_make()
	fmt.sbprintf(&sb, format, ..args)
	append(&log.items, TimingLogItem{strings.to_string(sb), intrinsics.read_cycle_counter(), .Time})
	thread.releaseMutex(&log.mutex)
}

print_timing_log :: proc(log: TimingLog) {
	prev_time := log.start_time
	for item in log.items {
		switch item.type {
		case .Group, .Log:
			fmt.printfln("  %v", item.msg)
		case .Time:
			d_cycles := item.time - prev_time
			d_nanoseconds := f64(d_cycles) * (f64(1e9) / f64(4e9))
			fmt.printfln("- %v, %v", item.msg, time.Duration(d_nanoseconds))
			prev_time = item.time
		}
	}
}
