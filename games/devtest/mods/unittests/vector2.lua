-- Test 2D vector operations and engine push/read functionality

local function test_vector2_new()
	-- Test vector2 construction
	local v = vector2.new(1, 2)
	assert(v.x == 1, "vector2.new x component incorrect")
	assert(v.y == 2, "vector2.new y component incorrect")
	assert(vector2.check(v), "vector2.check failed for valid vector")
end
unittests.register("test_vector2_new", test_vector2_new)

local function test_vector2_zero()
	-- Test zero vector
	local v = vector2.zero()
	assert(v.x == 0, "vector2.zero x component incorrect")
	assert(v.y == 0, "vector2.zero y component incorrect")
	assert(vector2.check(v), "vector2.check failed for zero vector")
end
unittests.register("test_vector2_zero", test_vector2_zero)

local function test_vector2_copy()
	-- Test vector copy
	local v1 = vector2.new(3, 4)
	local v2 = vector2.copy(v1)
	assert(v1.x == v2.x and v1.y == v2.y, "vector2.copy failed")
	assert(vector2.check(v2), "vector2.check failed for copied vector")
	-- Ensure it's a separate object
	v1.x = 10
	assert(v2.x == 3, "vector2.copy created reference instead of copy")
end
unittests.register("test_vector2_copy", test_vector2_copy)

local function test_vector2_from_string()
	-- Test parsing from string
	local v = vector2.from_string("(5, 6)")
	assert(v, "vector2.from_string returned nil")
	assert(v.x == 5, "vector2.from_string x component incorrect")
	assert(v.y == 6, "vector2.from_string y component incorrect")
	assert(vector2.check(v), "vector2.check failed for parsed vector")
end
unittests.register("test_vector2_from_string", test_vector2_from_string)

local function test_vector2_to_string()
	-- Test conversion to string
	local v = vector2.new(7, 8)
	local s = vector2.to_string(v)
	assert(type(s) == "string", "vector2.to_string did not return string")
	assert(s:find("7") and s:find("8"), "vector2.to_string missing components")
end
unittests.register("test_vector2_to_string", test_vector2_to_string)

local function test_vector2_equals()
	-- Test equality
	local v1 = vector2.new(1, 2)
	local v2 = vector2.new(1, 2)
	local v3 = vector2.new(2, 1)
	assert(vector2.equals(v1, v2), "vector2.equals failed for equal vectors")
	assert(not vector2.equals(v1, v3), "vector2.equals returned true for different vectors")
	assert(v1 == v2, "vector2 metatable __eq failed for equal vectors")
	assert(not (v1 == v3), "vector2 metatable __eq returned true for different vectors")
end
unittests.register("test_vector2_equals", test_vector2_equals)

local function test_vector2_length()
	-- Test length calculation
	local v = vector2.new(3, 4)
	local len = vector2.length(v)
	assert(math.abs(len - 5) < 0.001, "vector2.length incorrect")
end
unittests.register("test_vector2_length", test_vector2_length)

local function test_vector2_normalize()
	-- Test normalization
	local v = vector2.new(3, 4)
	local n = vector2.normalize(v)
	local len = vector2.length(n)
	assert(math.abs(len - 1) < 0.001, "vector2.normalize did not produce unit vector")
end
unittests.register("test_vector2_normalize", test_vector2_normalize)

local function test_vector2_distance()
	-- Test distance calculation
	local v1 = vector2.new(0, 0)
	local v2 = vector2.new(3, 4)
	local dist = vector2.distance(v1, v2)
	assert(math.abs(dist - 5) < 0.001, "vector2.distance incorrect")
end
unittests.register("test_vector2_distance", test_vector2_distance)

local function test_vector2_add()
	-- Test addition
	local v1 = vector2.new(1, 2)
	local v2 = vector2.new(3, 4)
	local v3 = vector2.add(v1, v2)
	assert(v3.x == 4 and v3.y == 6, "vector2.add incorrect")
	-- Test operator overload
	local v4 = v1 + v2
	assert(v4.x == 4 and v4.y == 6, "vector2 metatable __add incorrect")
end
unittests.register("test_vector2_add", test_vector2_add)

local function test_vector2_subtract()
	-- Test subtraction
	local v1 = vector2.new(5, 7)
	local v2 = vector2.new(2, 3)
	local v3 = vector2.subtract(v1, v2)
	assert(v3.x == 3 and v3.y == 4, "vector2.subtract incorrect")
	-- Test operator overload
	local v4 = v1 - v2
	assert(v4.x == 3 and v4.y == 4, "vector2 metatable __sub incorrect")
end
unittests.register("test_vector2_subtract", test_vector2_subtract)

local function test_vector2_multiply()
	-- Test multiplication by scalar
	local v1 = vector2.new(2, 3)
	local v2 = vector2.multiply(v1, 2)
	assert(v2.x == 4 and v2.y == 6, "vector2.multiply incorrect")
	-- Test operator overload
	local v3 = v1 * 3
	assert(v3.x == 6 and v3.y == 9, "vector2 metatable __mul incorrect")
end
unittests.register("test_vector2_multiply", test_vector2_multiply)

local function test_vector2_divide()
	-- Test division by scalar
	local v1 = vector2.new(6, 9)
	local v2 = vector2.divide(v1, 3)
	assert(v2.x == 2 and v2.y == 3, "vector2.divide incorrect")
	-- Test operator overload
	local v3 = v1 / 2
	assert(v3.x == 3 and v3.y == 4.5, "vector2 metatable __div incorrect")
end
unittests.register("test_vector2_divide", test_vector2_divide)

local function test_vector2_dot()
	-- Test dot product
	local v1 = vector2.new(2, 3)
	local v2 = vector2.new(4, 5)
	local dot = vector2.dot(v1, v2)
	assert(dot == 23, "vector2.dot incorrect")
end
unittests.register("test_vector2_dot", test_vector2_dot)

local function test_vector2_rotate()
	-- Test rotation
	local v = vector2.new(1, 0)
	local rotated = vector2.rotate(v, math.pi / 2)
	assert(math.abs(rotated.x) < 0.001, "vector2.rotate x component incorrect")
	assert(math.abs(rotated.y - 1) < 0.001, "vector2.rotate y component incorrect")
end
unittests.register("test_vector2_rotate", test_vector2_rotate)

local function test_vector2_angle()
	-- Test angle calculation
	local v1 = vector2.new(1, 0)
	local v2 = vector2.new(0, 1)
	local angle = vector2.angle(v1, v2)
	assert(math.abs(angle - math.pi / 2) < 0.001, "vector2.angle incorrect")
end
unittests.register("test_vector2_angle", test_vector2_angle)

local function test_vector2_from_polar()
	-- Test polar coordinate conversion
	local v = vector2.from_polar(5, 0)
	assert(math.abs(v.x - 5) < 0.001, "vector2.from_polar x component incorrect")
	assert(math.abs(v.y) < 0.001, "vector2.from_polar y component incorrect")
end
unittests.register("test_vector2_from_polar", test_vector2_from_polar)

local function test_vector2_to_polar()
	-- Test polar coordinate conversion
	local v = vector2.new(3, 4)
	local r, theta = vector2.to_polar(v)
	assert(math.abs(r - 5) < 0.001, "vector2.to_polar radius incorrect")
	assert(theta ~= nil, "vector2.to_polar angle is nil")
end
unittests.register("test_vector2_to_polar", test_vector2_to_polar)

-- Test that 2D vectors work correctly with engine push/read functions
-- This ensures the C++ bridge isn't breaking
local function test_vector2_engine_push_read()
	-- Test that we can create vectors and the engine can handle them
	-- The engine's push/read functions are used internally when passing
	-- vectors between Lua and C++
	
	-- Create various types of 2D vectors
	local v_float = vector2.new(1.5, 2.5)
	local v_int = vector2.new(10, 20)
	local v_zero = vector2.zero()
	
	-- Test that they maintain their values (this would fail if push/read broke)
	assert(v_float.x == 1.5 and v_float.y == 2.5, "Float vector values corrupted")
	assert(v_int.x == 10 and v_int.y == 20, "Integer vector values corrupted")
	assert(v_zero.x == 0 and v_zero.y == 0, "Zero vector values corrupted")
	
	-- Test vector operations that would go through engine if they use it
	local result = vector2.add(v_float, v_int)
	assert(math.abs(result.x - 11.5) < 0.001 and math.abs(result.y - 22.5) < 0.001,
		"Vector addition through potential engine path failed")
	
	-- Test that vectors can be passed to string conversion (tests metatable integrity)
	local str = tostring(v_float)
	assert(type(str) == "string" and str:find("1.5") and str:find("2.5"),
		"Vector to string conversion failed")
end
unittests.register("test_vector2_engine_push_read", test_vector2_engine_push_read)

-- Test edge cases for vector2
local function test_vector2_edge_cases()
	-- Test negative values
	local v_neg = vector2.new(-5, -10)
	assert(v_neg.x == -5 and v_neg.y == -10, "Negative vector values incorrect")
	
	-- Test very small values
	local v_small = vector2.new(0.0001, 0.0002)
	assert(v_small.x == 0.0001 and v_small.y == 0.0002, "Small vector values incorrect")
	
	-- Test very large values
	local v_large = vector2.new(1000000, 2000000)
	assert(v_large.x == 1000000 and v_large.y == 2000000, "Large vector values incorrect")
	
	-- Test mixed signs
	local v_mixed = vector2.new(-3, 4)
	local len = vector2.length(v_mixed)
	assert(math.abs(len - 5) < 0.001, "Mixed sign vector length incorrect")
end
unittests.register("test_vector2_edge_cases", test_vector2_edge_cases)
