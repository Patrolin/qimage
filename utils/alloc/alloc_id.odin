package lib_alloc
import "base:intrinsics"

/* TODO: if you were making a game you would need something like this:
// lib
IdToPointer :: struct($T: typeid) {
	m:       map[int]T,
	next_id: int,
}
new_id :: proc($T: typeid, id_to_pointer: ^IdToPointer(T)) -> (int, ^T) {
	next_id := intrinsics.atomic_add(&id_to_pointer.next_id, 1)
	id_to_pointer.m[next_id] = {}
	return next_id, &id_to_pointer.m[next_id]
}*/
