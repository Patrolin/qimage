package alloc_utils
import "../mem"

// !TODO: put the data next to the header, so that we can avoid a pointer indirection
// !TODO: SwapBuffer with three past values?
DoubleBuffer :: [2]struct #align(mem.CACHE_LINE_SIZE) {
	lock:        mem.Lock,
	data:        []byte,
	next_offset: int,
}
#assert(size_of(DoubleBuffer) == 2 * mem.CACHE_LINE_SIZE)

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
	ptr := raw_data(buffer.data)
	((^[4]u64)(ptr))^ = (^[4]u64)(src)^
	buffer.next_offset = (next_offset + 4) & len(buffer.data)
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
	data = buffer.data
	mem.get_lock(&buffer.lock)
	return
}
