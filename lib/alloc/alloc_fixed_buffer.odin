package alloc
FixedBuffer :: struct($T: typeid, $N: int) {
	slice:   []T,
	using _: struct #raw_union {
		buffer: [N]T,
		first:  T,
	},
}
fixedBufferAppend :: proc(fixedBuffer: ^FixedBuffer($T, $N), new_data: T) {
	new_size := len(fixed_buffer.slice) + 1
	assert(new_size <= N)
	fixed_buffer.buffer[new_size - 1] = new_data
	fixed_buffer.slice = fixed_buffer.buffer[:new_size]
}
fixedBufferAppendOrReplace :: proc(fixed_buffer: ^FixedBuffer($T, $N), new_data: T) {
	new_size := len(fixed_buffer.slice) + 1
	if new_size > N {
		new_size = len(fixed_buffer.slice)
	}
	fixed_buffer.buffer[new_size - 1] = new_data
	fixed_buffer.slice = fixed_buffer.buffer[:new_size]
}
