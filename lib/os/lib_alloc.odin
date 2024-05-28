package lib_os
import "../math"

makeBig :: proc($T: typeid/[]$V, count: int) -> T {
	total_size := size_of(T) * count
	if (total_size <= MAX_SLAB_SIZE) {
		return make(T, count)
	} else {
		data := pageAlloc(math.bytes(total_size))
		t_data: [^]V = raw_data(data)
		return t_data[:count]
	}
}
