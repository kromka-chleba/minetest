-- Tests for the engine's ability to push and read 2D vectors
-- This ensures the C++ <-> Lua bridge for vector2 is working correctly

local function test_vector2_push_read()
	-- Test that vector2 values can be created and read back correctly
	-- This exercises the engine's push_v2f and read_v2f functions
	
	-- Test basic vector2 creation and field access
	local v1 = vector2.new(1.5, 2.5)
	assert(v1.x == 1.5, "vector2 x coordinate incorrect")
	assert(v1.y == 2.5, "vector2 y coordinate incorrect")
	
	-- Test with negative values
	local v2 = vector2.new(-10.3, -20.7)
	assert(v2.x == -10.3, "vector2 negative x coordinate incorrect")
	assert(v2.y == -20.7, "vector2 negative y coordinate incorrect")
	
	-- Test with zero
	local v3 = vector2.zero()
	assert(v3.x == 0, "vector2.zero() x coordinate incorrect")
	assert(v3.y == 0, "vector2.zero() y coordinate incorrect")
	
	-- Test with integer values (which could exercise push_v2s32)
	local v4 = vector2.new(100, 200)
	assert(v4.x == 100, "vector2 integer x coordinate incorrect")
	assert(v4.y == 200, "vector2 integer y coordinate incorrect")
	
	-- Test copy functionality (exercises push/read)
	local v5 = vector2.copy(v1)
	assert(v5.x == v1.x, "vector2.copy() x coordinate mismatch")
	assert(v5.y == v1.y, "vector2.copy() y coordinate mismatch")
	
	-- Test that operations preserve values correctly
	local v6 = vector2.new(3, 4)
	local v7 = vector2.add(v6, vector2.new(1, 1))
	assert(v7.x == 4, "vector2.add() x coordinate incorrect")
	assert(v7.y == 5, "vector2.add() y coordinate incorrect")
	
	-- Test metatable preservation (ensures proper push behavior)
	assert(vector2.check(v1), "vector2.check() failed for valid vector")
	assert(vector2.check(v2), "vector2.check() failed for negative vector")
	assert(vector2.check(v3), "vector2.check() failed for zero vector")
	assert(vector2.check(v4), "vector2.check() failed for integer vector")
end
unittests.register("test_vector2_push_read", test_vector2_push_read)

-- Test vector2 operations that may involve C++ conversions
local function test_vector2_operations()
	-- Test operations that may involve engine push/read cycles
	
	local v1 = vector2.new(3, 4)
	local len = vector2.length(v1)
	assert(len == 5, "vector2.length() incorrect")
	
	-- Test normalize (involves division which could expose precision issues)
	local v2 = vector2.normalize(v1)
	assert(math.abs(v2.x - 0.6) < 0.0001, "vector2.normalize() x incorrect")
	assert(math.abs(v2.y - 0.8) < 0.0001, "vector2.normalize() y incorrect")
	
	-- Test multiply/divide (exercises floating point handling)
	local v3 = vector2.multiply(v1, 2.5)
	assert(v3.x == 7.5, "vector2.multiply() x incorrect")
	assert(v3.y == 10, "vector2.multiply() y incorrect")
	
	local v4 = vector2.divide(v1, 2)
	assert(v4.x == 1.5, "vector2.divide() x incorrect")
	assert(v4.y == 2, "vector2.divide() y incorrect")
	
	-- Test floor/round/ceil (exercises type conversions)
	local v5 = vector2.new(3.7, -2.3)
	local v6 = vector2.floor(v5)
	assert(v6.x == 3, "vector2.floor() x incorrect")
	assert(v6.y == -3, "vector2.floor() y incorrect")
	
	local v7 = vector2.ceil(v5)
	assert(v7.x == 4, "vector2.ceil() x incorrect")
	assert(v7.y == -2, "vector2.ceil() y incorrect")
	
	local v8 = vector2.round(v5)
	assert(v8.x == 4, "vector2.round() x incorrect")
	assert(v8.y == -2, "vector2.round() y incorrect")
end
unittests.register("test_vector2_operations", test_vector2_operations)

-- Test edge cases and special values
local function test_vector2_edge_cases()
	-- Test very large values
	local v1 = vector2.new(1e6, 1e6)
	assert(v1.x == 1e6, "vector2 large value x incorrect")
	assert(v1.y == 1e6, "vector2 large value y incorrect")
	
	-- Test very small values
	local v2 = vector2.new(1e-6, 1e-6)
	assert(math.abs(v2.x - 1e-6) < 1e-9, "vector2 small value x incorrect")
	assert(math.abs(v2.y - 1e-6) < 1e-9, "vector2 small value y incorrect")
	
	-- Test mixed positive/negative
	local v3 = vector2.new(-5.5, 7.3)
	assert(v3.x == -5.5, "vector2 mixed sign x incorrect")
	assert(v3.y == 7.3, "vector2 mixed sign y incorrect")
	
	-- Test equality comparison (exercises read operations)
	local v4 = vector2.new(1.0, 2.0)
	local v5 = vector2.new(1.0, 2.0)
	assert(vector2.equals(v4, v5), "vector2.equals() failed for equal vectors")
	
	local v6 = vector2.new(1.0, 2.1)
	assert(not vector2.equals(v4, v6), "vector2.equals() failed for unequal vectors")
end
unittests.register("test_vector2_edge_cases", test_vector2_edge_cases)
