package lib_os
import "../math"
import "core:fmt"

Partition :: struct {
	data: []u8,
	used: int,
}
@(private)
partitionAlloc_bytes :: proc(partition: ^Partition, chunk_size: math.bytes) -> []u8 {
	start := partition.used
	end := start + int(chunk_size)
	chunk := partition.data[start:end]
	partition.used = end
	return chunk
}
@(private)
partitionAlloc_fraction :: proc(partition: ^Partition, fraction: f64) -> []u8 {
	chunk_size := math.roundToInt(f64(len(partition.data)) * fraction)
	return partitionAlloc(partition, math.bytes(chunk_size))
}
partitionAlloc :: proc {
	partitionAlloc_bytes,
	partitionAlloc_fraction,
}
