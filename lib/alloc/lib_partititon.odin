package lib_alloc
import "../math"
import "core:fmt"

Partition :: struct {
	data: []u8,
	used: int,
}
partitionAlloc_bytes :: proc(partition: ^Partition, chunk_size: bytes) -> []u8 {
	start := partition.used
	end := start + int(chunk_size)
	chunk := partition.data[start:end]
	partition.used = end
	return chunk
}
partitionAlloc_f64 :: proc(partition: ^Partition, fraction: f64) -> []u8 {
	chunk_size := math.roundToInt_f64(f64(len(partition.data)) * fraction)
	return partitionAlloc(partition, bytes(chunk_size))
}
partitionAlloc :: proc {
	partitionAlloc_bytes,
	partitionAlloc_f64,
}
