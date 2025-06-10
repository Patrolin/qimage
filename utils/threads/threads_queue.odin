package threads_utils
import "../math"
import "../mem"
import "base:intrinsics"

/* TODO: use this for both events and work queue
	- events also need to set `timestamp = time() + MIN_EVENT_DELAY`, so that on the game update thread: `time() >= event.timestamp`
*/
// constants
WaitFreeQueueItemType :: [2]u64

// types
WaitFreeQueueData :: [32]WaitFreeQueueItemType // NOTE: size_of(CircularBufferData) needs to be a power of two..
WaitFreeQueue :: struct {
	reader: WaitFreeQueueReader,
	writer: WaitFreeQueueWriter,
	data:   WaitFreeQueueData,
}
WaitFreeQueueReader :: struct #align(mem.CACHE_LINE_SIZE) {
	read_offset: int,
}
#assert(size_of(WaitFreeQueueReader) == mem.CACHE_LINE_SIZE)
WaitFreeQueueWriter :: struct #align(mem.CACHE_LINE_SIZE) {
	writing_offset, written_offset, readable_offset: int,
}
#assert(size_of(WaitFreeQueueWriter) == mem.CACHE_LINE_SIZE)

// procedures
@(private)
queue_append_raw :: proc(queue: ^WaitFreeQueue, value_ptr: rawptr) {
	// get the next slot
	next_offset := intrinsics.atomic_add(&queue.writer.writing_offset, size_of(WaitFreeQueueItemType))
	next_ptr := math.ptr_add(&queue.data, next_offset & size_of(WaitFreeQueueData))
	assert(next_offset - queue.reader.read_offset < size_of(WaitFreeQueueData), "Circular buffer out of space!")
	// write into it
	(^WaitFreeQueueItemType)(next_ptr)^ = (^WaitFreeQueueItemType)(value_ptr)^
	// mark it as written
	intrinsics.atomic_add(&queue.writer.written_offset, size_of(WaitFreeQueueItemType))
	// commit all pending writes
	readable_offset := queue.writer.readable_offset
	ok: bool
	written_offset := queue.writer.written_offset
	writing_offset := intrinsics.atomic_load(&queue.writer.writing_offset)
	for written_offset == writing_offset && written_offset - readable_offset > 0 {
		readable_offset, ok = intrinsics.atomic_compare_exchange_weak(&queue.writer.readable_offset, readable_offset, written_offset)
		if ok {return}
		written_offset = queue.writer.written_offset
		writing_offset = intrinsics.atomic_load(&queue.writer.writing_offset)
	}
}
queue_append :: #force_inline proc(queue: ^WaitFreeQueue, value: ^$T) {
	#assert(size_of(T) <= size_of(WaitFreeQueueItemType))
	queue_append_raw(queue, (^WaitFreeQueueItemType)(value))
}
@(private)
queue_read_raw :: proc(queue: ^WaitFreeQueue, value: ^WaitFreeQueueItemType) -> (ok: bool) {
	for {
		// read the next value
		offset_to_read := intrinsics.atomic_load(&queue.reader.read_offset)
		value_ptr := math.ptr_add(&queue.data, offset_to_read & size_of(WaitFreeQueueData))
		value^ = (^WaitFreeQueueItemType)(value_ptr)^
		// try to commit the read
		readable_offset := intrinsics.atomic_load(&queue.writer.readable_offset)
		if offset_to_read >= readable_offset {return false}
		_, ok = intrinsics.atomic_compare_exchange_weak(&queue.reader.read_offset, offset_to_read, offset_to_read + size_of(WaitFreeQueueData))
		if ok {return true}
	}
}
queue_read :: #force_inline proc(queue: ^WaitFreeQueue, value: ^$T) -> (ok: bool) {
	#assert(size_of(T) <= size_of(WaitFreeQueueItemType))
	return queue_read_raw(queue, (^WaitFreeQueueItemType)(value))
}
