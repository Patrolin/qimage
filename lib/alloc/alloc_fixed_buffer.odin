package alloc

FixedBuffer :: struct($T: typeid, $N: int) {
	used:   int,
	buffer: [N]T,
}
fixedBufferSlice :: proc(fixedBuffer: ^FixedBuffer($T, $N)) -> []T {
	return fixedBuffer.buffer[:used]
}
fixedBufferLast :: proc(fixedBuffer: ^FixedBuffer($T, $N)) -> T {
	return fixedBuffer.buffer[fixedBuffer.used - 1]
}
fixedBufferAppend :: proc(fixedBuffer: ^FixedBuffer($T, $N), new_data: T) {
	new_size := fixed_buffer.used + 1
	assert(new_size <= N)
	fixed_buffer.buffer[new_size - 1] = new_data
	fixed_buffer.used = new_size
}
fixedBufferAppendOrReplace :: proc(fixed_buffer: ^FixedBuffer($T, $N), new_data: T) {
	new_size := fixed_buffer.used + 1
	if new_size > N {
		new_size = fixed_buffer.used
	}
	fixed_buffer.buffer[new_size - 1] = new_data
	fixed_buffer.used = new_size
}
