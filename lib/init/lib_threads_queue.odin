package lib_init

WorkQueues :: struct {
	front:      WorkQueue,
	background: WorkQueue,
}
work_queues := WorkQueues{}

WorkQueue :: struct {
	semaphore: OsSemaphore,
	items:     [32]WorkItem, // TODO: circular buffer?
	// mutex if MPMC?
}
WorkItem :: struct {
	function: proc(_: rawptr),
	data:     rawptr,
}

submitAndGetNextWorkItem :: proc(queue: ^WorkQueue, submit: ^WorkItem) -> ^WorkItem {
	return nil // TODO: submitAndGetNextWorkItem
}
joinFrontQueue :: proc() {
	// TODO: joinFrontQueue
}
