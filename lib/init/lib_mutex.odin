package lib_init
import "core:intrinsics"

Mutex :: distinct int
getMutexWeak :: proc(mutex: ^Mutex) -> bool {
	mutex_value_got := intrinsics.atomic_compare_exchange_weak(mutex, 0, 1)
	return mutex_value_got == 0
}
getMutexStrong :: proc(mutex: ^Mutex) {
	for !getMutexWeak(mutex) {}
}
releaseMutex :: proc(mutex: ^Mutex) {
	mutex^ = 0
}
