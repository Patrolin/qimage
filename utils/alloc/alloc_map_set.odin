package alloc_utils
import math_utils "../math"
import "base:runtime"

// TODO: rethink this with half fit allocator in mind

// SlotArray
@(private)
SlotUsed :: enum u8 {
	Free    = 0, // NOTE: ZII
	Used    = 1,
	Removed = 2,
}
@(private)
MapLikeSlot :: struct($Key, $Value: typeid) {
	key:   Key,
	value: Value,
	hash:  int, // NOTE: hash is checked before string key
	used:  SlotUsed,
}
@(private)
SlotArray :: struct($Key, $Value: typeid) {
	slots:         [^]MapLikeSlot(Key, Value),
	added_slots:   u32,
	removed_slots: u32,
	capacity:      u32,
}
@(private)
getFreeOrCurrentSlot :: proc(slots: [^]MapLikeSlot($Key, $Value), capacity: int, key: Key, hash: int) -> ^MapLikeSlot(Key, Value) {
	hash_step := hash | 1 // NOTE: len(slots) must be a power of two
	slot: ^MapLikeSlot(Key, Value) = nil
	for i := hash % capacity;; i += hash_step {
		slot = &slots[i]
		if slot.used == .Free || (slot.hash == hash && slot.key == key) {break}
	}
	return slot
}
MIN_CAPACITY :: 8
MAX_ADDED_PERCENT :: 75
MAX_REMOVED_PERCENT :: 50
@(private)
resize_slotArray :: proc(m: ^SlotArray($Key, $Value), new_capacity: u32) {
	slots := m.slots
	new_added_slots: u32 = 0
	new_slots := make([^]MapLikeSlot(Key, Value), new_capacity)
	if slots != nil {
		for i in 0 ..< m.capacity {
			slot := slots[i]
			if (slot.used == .Used) {
				new_slot := getFreeOrCurrentSlot(new_slots, int(new_capacity), slot.key, slot.hash)
				new_slot^ = slot
				new_added_slots += 1
			}
		}
	}
	m.slots = new_slots
	m.added_slots = new_added_slots // ?TODO: mutex
	m.capacity = new_capacity
	free(slots)
}
reserve_slotArray :: proc(m: ^SlotArray($Key, $Value)) {
	if (m.added_slots + 1) * 100 >= MAX_ADDED_PERCENT * m.capacity { 	// NOTE: handle zero capacity
		new_capacity := m.capacity * 2
		if new_capacity == 0 {new_capacity = MIN_CAPACITY}
		resize_slotArray(m, new_capacity)
	}
}
shrink_slotArray :: proc(m: ^SlotArray($Key, $Value)) {
	capacity := m.capacity
	if m.removed_slots * 100 >= MAX_REMOVED_PERCENT * capacity && capacity > MIN_CAPACITY {
		resize_slotArray(m, capacity / 2)
	}
}

// Map
Map :: struct($Key, $Value: typeid) {
	using _: SlotArray(Key, Value),
}
addKey_map :: proc(m: ^$M/Map($Key, $Value), key: Key) -> ^Value {
	reserve_slotArray(cast(^SlotArray(Key, Value))m)
	hash0 := hash(key)
	new_slot := getFreeOrCurrentSlot(m.slots, int(m.capacity), key, hash0)
	if new_slot.used == .Free {m.added_slots += 1}
	if new_slot.used == .Removed {m.removed_slots -= 1}
	new_slot.key = key
	new_slot.hash = hash0
	new_slot.used = .Used
	return &new_slot.value
}
getKey_map :: proc(m: ^$M/Map($Key, $Value), key: Key) -> (value: ^Value, ok: bool) {
	slot := getFreeOrCurrentSlot(m.slots, int(m.capacity), key, hash(key))
	return &slot.value, slot.used == .Used
}
removeKey_map :: proc(m: ^$M/Map($Key, $Value), key: Key) {
	slot := getFreeOrCurrentSlot(m.slots, int(m.capacity), key, hash(key))
	if slot.used == .Used {
		m.removed_slots += 1
		slot.used = .Removed
		slot.value = {}
	}
	if m.removed_slots * 100 > MAX_REMOVED_PERCENT * m.capacity {
		shrink_slotArray(cast(^SlotArray(Key, Value))m)
	}
}
addKey :: proc {
	addKey_map,
	addKey_set,
}
getKey :: proc {
	getKey_map,
	getKey_set,
}
removeKey :: proc {
	removeKey_map,
	removeKey_set,
}
delete_map_like_map :: proc(m: ^Map($Key, $Value), allocator := context.allocator, loc := #caller_location) {
	runtime.mem_free_with_size(m.slots, int(m.capacity) * size_of(MapLikeSlot(Key, Value)), allocator, loc)
	m.slots = nil
	m.added_slots = 0
	m.removed_slots = 0
	m.capacity = MIN_CAPACITY
}
delete_map_like :: proc {
	delete_map_like_map,
	delete_map_like_set,
}

// Set
void :: struct {
}
#assert(size_of(void) == 0)
Set :: struct($Key: typeid) {
	using _: SlotArray(Key, void),
}
addKey_set :: proc(m: ^$M/Set($Key), key: Key) {
	reserve_slotArray(cast(^SlotArray(Key, void))m)
	hash0 := hash(key)
	new_slot := getFreeOrCurrentSlot(m.slots, int(m.capacity), key, hash0)
	if new_slot.used == .Free {m.added_slots += 1}
	if new_slot.used == .Removed {m.removed_slots -= 1}
	new_slot.key = key
	new_slot.hash = hash0
	new_slot.used = .Used
}
getKey_set :: proc(m: ^$M/Set($Key), key: Key) -> bool {
	slot := getFreeOrCurrentSlot(m.slots, int(m.capacity), key, hash(key))
	return slot.used == .Used
}
removeKey_set :: proc(m: ^$M/Set($Key), key: Key) {
	slot := getFreeOrCurrentSlot(m.slots, int(m.capacity), key, hash(key))
	if slot.used == .Used {
		m.removed_slots += 1
		slot.used = .Removed
		slot.value = {}
	}
	if m.removed_slots * 100 > MAX_REMOVED_PERCENT * m.capacity {
		shrink_slotArray(cast(^SlotArray(Key, void))m)
	}
}
delete_map_like_set :: proc(m: ^Set($Key), allocator := context.allocator, loc := #caller_location) {
	runtime.mem_free_with_size(m.slots, int(m.capacity) * size_of(MapLikeSlot(Key, void)), allocator, loc)
	m.slots = nil
	m.added_slots = 0
	m.removed_slots = 0
	m.capacity = MIN_CAPACITY
}

// TODO: better hash, custom hash?
worstHash :: proc(key: $Key) -> int {
	return 0
}
hash :: worstHash
