package lib_alloc
import "../math"
import "core:fmt"

Partition :: struct {
	data: []u8,
	used: int,
}
@(private)
partitionBy_bytes :: proc(partition: ^Partition, chunk_size: math.bytes) -> []u8 {
	start := partition.used
	end := start + int(chunk_size)
	chunk := partition.data[start:end]
	partition.used = end
	return chunk
}
@(private)
partitionBy_fraction :: proc(partition: ^Partition, fraction: f64, floor_to: int = 0) -> []u8 {
	chunk_size := len(partition.data) - partition.used
	if fraction != 0 {
		chunk_size = math.roundToInt(f64(len(partition.data)) * fraction)
	}
	if floor_to != 0 {
		chunk_size = math.floorTo(chunk_size, floor_to)
	}
	return partitionBy_bytes(partition, math.bytes(chunk_size))
}
partitionBy :: proc {
	partitionBy_bytes,
	partitionBy_fraction,
}
