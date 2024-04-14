package lib_threads

// TODO: front/background queues w/ 1 background thread
WorkQueue :: struct {
	items: [32]WorkItem,
	// mutex here?
}
WorkItem :: struct {
	//function: ...,
	data: rawptr,
}
// TODO: OsSemaphore
