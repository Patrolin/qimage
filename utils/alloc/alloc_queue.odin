package alloc_utils
import "../math"
import "../mem"
import "base:intrinsics"

/* !!!TODO: do a circular buffer instead, and use it for both events and work queue */

// constants
QUEUE_MAX_ITEM_SIZE :: 4

// types
WaitFreeQueue :: struct {
	writer_state: WaitFreeQueueWriterState,
	reader_state: WaitFreeQueueReaderState,
	data:         [256 - size_of(WaitFreeQueueWriterState) - size_of(WaitFreeQueueReaderState)]byte,
}
#assert(size_of(WaitFreeQueue) == 256)
/* only written to by writer */
WaitFreeQueueWriterState :: struct #align(mem.CACHE_LINE_SIZE) {
	written_count: int,
}
/* only written to by reader */
WaitFreeQueueReaderState :: struct #align(mem.CACHE_LINE_SIZE) {
	next:       ^WaitFreeQueue,
	read_count: int,
}

// procedures
_append_queue_raw :: proc(queue: ^WaitFreeQueue, item: rawptr) {
	// get most recent queue
	queue := queue
	missed_item_count := 0
	missed_item: [QUEUE_MAX_ITEM_SIZE]byte
	for next := queue.reader_state.next; next != nil; next = queue.reader_state.next {
		if queue.writer_state.written_count > queue.reader_state.read_count {
			missed_item_count = queue.writer_state.written_count - queue.reader_state.read_count
			missed_item = (^[QUEUE_MAX_ITEM_SIZE]byte)(&queue.data[queue.reader_state.read_count])^
			assert(missed_item_count == 1)
		}
		free(queue)
		queue = next
	}
	// add items
	if missed_item_count != 0 {
		ptr := (^[QUEUE_MAX_ITEM_SIZE]byte)(&queue.data)
		ptr^ = missed_item
		intrinsics.atomic_add(&queue.writer_state.written_count, 1)
	}
	ptr := (^[QUEUE_MAX_ITEM_SIZE]byte)(&queue.data[queue.writer_state.written_count * QUEUE_MAX_ITEM_SIZE])
	ptr^ = (^[QUEUE_MAX_ITEM_SIZE]byte)(item)^
	intrinsics.atomic_add(&queue.writer_state.written_count, 1)
}
append_queue :: #force_inline proc(queue: ^WaitFreeQueue, item: ^$T) where size_of(T) <= 4 {
	_append_queue_raw(queue, item)
}
read_queue :: proc(queue: ^WaitFreeQueue, $T: typeid) where size_of(T) <= 4 {
	// close the current queue and open a new one
	read_count := queue.writer_state.written_count
	queue.reader_state.read_count = read_count
	intrinsics.atomic_store(&queue.reader_state.next, new(WaitFreeQueue))
	//
}


/*
	!TODO: put the data next to the header, so that we can avoid a pointer indirection
	!TODO: SwapBuffer with three past values?
*/

// types
DoubleBuffer :: [2]struct #align(mem.CACHE_LINE_SIZE) {
	lock:        mem.Lock,
	next_offset: int,
	data:        [1024]byte,
}
#assert(size_of(DoubleBuffer) <= mem.PAGE_SIZE)

// procedures
double_buffer_append :: proc(double_buffer: ^DoubleBuffer, buffer_index: int, src: rawptr) -> (next_buffer_index: int) {
	// get one of the buffers
	next_buffer_index = buffer_index
	buffer := &double_buffer[buffer_index]
	got_lock := mem.get_lock_or_error(&buffer.lock)
	if !got_lock {
		next_buffer_index = 1 - buffer_index
		buffer = &double_buffer[next_buffer_index]
	}
	// append
	next_offset := buffer.next_offset
	assert(next_offset < len(buffer.data))
	ptr := math.ptr_add(&buffer.data, next_offset)
	((^[4]u64)(ptr))^ = (^[4]u64)(src)^
	buffer.next_offset = next_offset + 4
	// return
	if got_lock {mem.release_lock(&buffer.lock)}
	return
}
double_buffer_get :: proc(double_buffer: ^DoubleBuffer, buffer_index: int) -> (data: []byte, next_buffer_index: int) {
	// unlock the other buffer
	next_buffer_index = 1 - buffer_index
	other_buffer := &double_buffer[next_buffer_index]
	other_buffer.next_offset = 0
	mem.release_lock(&other_buffer.lock)
	// lock and return the current buffer
	buffer := &double_buffer[buffer_index]
	mem.get_lock(&buffer.lock)
	data = buffer.data[:buffer.next_offset]
	return
}
