package lib_math
import "core:testing"

@(test)
test_ilog2 :: proc(t: ^testing.T) {
	testing.expect(t, ilog2_ceil_u64(0) == 0)
	testing.expect(t, ilog2_ceil_u64(1) == 0)
	testing.expect(t, ilog2_ceil_u64(2) == 1)
	testing.expect(t, ilog2_ceil_u64(3) == 2)
	testing.expect(t, ilog2_ceil_u64(4) == 2)
	testing.expect(t, ilog2_ceil_u64(7) == 3)
	testing.expect(t, ilog2_ceil_u64(4096) == 12)
}
