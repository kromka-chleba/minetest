local function nearly_equal(a, b)
	return math.abs(a - b) < 1e-5
end

local function assert_v2_equal(a, b, msg)
	assert(nearly_equal(a.x, b.x) and nearly_equal(a.y, b.y),
		(msg or "vector2 mismatch") ..
		string.format(": got (%g, %g), expected (%g, %g)", a.x, a.y, b.x, b.y))
end

local function test_vector2_constructors()
	-- new()
	local v = vector2.new(1, 2)
	assert(v.x == 1 and v.y == 2, "new() failed")
	assert(vector2.check(v), "new() result has wrong metatable")

	-- zero()
	local z = vector2.zero()
	assert(z.x == 0 and z.y == 0, "zero() failed")
	assert(vector2.check(z), "zero() result has wrong metatable")

	-- copy()
	local c = vector2.copy(v)
	assert(c.x == v.x and c.y == v.y, "copy() values wrong")
	assert(vector2.check(c), "copy() result has wrong metatable")
	c.x = 99
	assert(v.x == 1, "copy() is not a deep copy")
end
unittests.register("test_vector2_constructors", test_vector2_constructors)

local function test_vector2_index()
	local v = vector2.new(24, 42)
	assert(v[1] == 24, "index [1] should be x")
	assert(v[2] == 42, "index [2] should be y")
	assert(v.x == 24, "index .x failed")
	assert(v.y == 42, "index .y failed")

	v[1] = 100
	assert(v.x == 100, "[1] = sets .x")
	v.x = 101
	assert(v[1] == 101, ".x = sets [1]")

	v[2] = 200
	assert(v.y == 200, "[2] = sets .y")
	v.y = 202
	assert(v[2] == 202, ".y = sets [2]")
end
unittests.register("test_vector2_index", test_vector2_index)

local function test_vector2_equals()
	assert(vector2.equals({x=0, y=0}, {x=0, y=0}), "equals plain tables")
	assert(vector2.equals({x=-1, y=0}, vector2.new(-1, 0)), "equals mixed")
	assert(not vector2.equals({x=1, y=2}, {x=1, y=3}), "equals different y")
	assert(vector2.new(1, 2) == vector2.new(1, 2), "== operator")
	assert(vector2.new(1, 2) ~= vector2.new(1, 3), "~= operator")
	local a = vector2.new(3, 4)
	assert(a:equals(a), "method :equals() self")
end
unittests.register("test_vector2_equals", test_vector2_equals)

local function test_vector2_arithmetic()
	local a = vector2.new(1, 2)
	local b = vector2.new(3, 4)

	-- add
	assert_v2_equal(vector2.add(a, b), vector2.new(4, 6), "add()")
	assert_v2_equal(a + b, vector2.new(4, 6), "+ operator")
	assert_v2_equal(vector2.add(a, 10), vector2.new(11, 12), "add() scalar")

	-- subtract
	assert_v2_equal(vector2.subtract(a, b), vector2.new(-2, -2), "subtract()")
	assert_v2_equal(a - b, vector2.new(-2, -2), "- operator")
	assert_v2_equal(vector2.subtract(b, 1), vector2.new(2, 3), "subtract() scalar")

	-- multiply
	assert_v2_equal(vector2.multiply(a, 3), vector2.new(3, 6), "multiply()")
	assert_v2_equal(a * 3, vector2.new(3, 6), "* operator (vec*scalar)")
	assert_v2_equal(3 * a, vector2.new(3, 6), "* operator (scalar*vec)")

	-- divide
	assert_v2_equal(vector2.divide(b, 2), vector2.new(1.5, 2), "divide()")
	assert_v2_equal(b / 2, vector2.new(1.5, 2), "/ operator")

	-- unary minus
	assert_v2_equal(-a, vector2.new(-1, -2), "unary minus")
end
unittests.register("test_vector2_arithmetic", test_vector2_arithmetic)

local function test_vector2_length_normalize()
	local a = vector2.new(3, 4)
	assert(nearly_equal(vector2.length(a), 5), "length() of (3,4) should be 5")
	assert(nearly_equal(a:length(), 5), ":length() method")
	assert(nearly_equal(vector2.length(vector2.zero()), 0), "length() of zero")

	local n = vector2.normalize(a)
	assert(nearly_equal(n.x, 0.6) and nearly_equal(n.y, 0.8), "normalize() values")
	assert(nearly_equal(vector2.length(n), 1), "normalize() result has unit length")

	local nz = vector2.normalize(vector2.zero())
	assert(nz.x == 0 and nz.y == 0, "normalize(zero) should be zero")
end
unittests.register("test_vector2_length_normalize", test_vector2_length_normalize)

local function test_vector2_distance_direction()
	local a = vector2.new(1, 0)
	local b = vector2.new(4, 4)
	assert(nearly_equal(vector2.distance(a, b), 5), "distance()")
	assert(nearly_equal(a:distance(b), 5), ":distance() method")
	assert(nearly_equal(vector2.distance(a, a), 0), "distance to self")

	local dir = vector2.direction(vector2.new(1, 0), vector2.new(1, 42))
	assert(nearly_equal(dir.x, 0) and nearly_equal(dir.y, 1), "direction() vertical")
	assert(nearly_equal(dir:length(), 1), "direction() is unit length")
end
unittests.register("test_vector2_distance_direction", test_vector2_distance_direction)

local function test_vector2_dot_angle()
	local a = vector2.new(-1, -2)
	local b = vector2.new(1, 2)
	assert(vector2.dot(a, b) == -5, "dot()")
	assert(vector2.zero():dot(b) == 0, "dot with zero")

	assert(nearly_equal(vector2.angle(a, b), math.pi), "angle() of opposite vectors")
	assert(nearly_equal(vector2.new(0, 1):angle(vector2.new(1, 0)), math.pi / 2),
		"angle() of perpendicular vectors")
end
unittests.register("test_vector2_dot_angle", test_vector2_dot_angle)

local function test_vector2_floor_round_ceil_sign_abs()
	local a = vector2.new(0.1, 0.9)
	assert_v2_equal(vector2.floor(a), vector2.new(0, 0), "floor()")
	assert_v2_equal(a:floor(), vector2.new(0, 0), ":floor() method")
	assert_v2_equal(vector2.round(a), vector2.new(0, 1), "round()")
	assert_v2_equal(a:round(), vector2.new(0, 1), ":round() method")
	assert_v2_equal(vector2.ceil(a), vector2.new(1, 1), "ceil()")
	assert_v2_equal(a:ceil(), vector2.new(1, 1), ":ceil() method")

	local s = vector2.new(-120.3, 231.5)
	assert_v2_equal(vector2.sign(s), vector2.new(-1, 1), "sign()")
	assert_v2_equal(vector2.sign(s, 200), vector2.new(0, 1), "sign() with tolerance")

	local n = vector2.new(-3.5, 7)
	assert_v2_equal(vector2.abs(n), vector2.new(3.5, 7), "abs()")
	assert_v2_equal(n:abs(), vector2.new(3.5, 7), ":abs() method")
end
unittests.register("test_vector2_floor_round_ceil_sign_abs", test_vector2_floor_round_ceil_sign_abs)

local function test_vector2_apply_combine()
	local a = vector2.new(0.1, 0.9)
	assert_v2_equal(vector2.apply(a, math.ceil), vector2.new(1, 1), "apply(ceil)")
	assert_v2_equal(a:apply(math.abs), vector2.new(0.1, 0.9), ":apply(abs)")

	local b = vector2.new(1, 4)
	local c = vector2.new(2, 3)
	assert_v2_equal(vector2.combine(b, c, math.max), vector2.new(2, 4), "combine(max)")
	assert_v2_equal(vector2.combine(b, c, math.min), vector2.new(1, 3), "combine(min)")
end
unittests.register("test_vector2_apply_combine", test_vector2_apply_combine)

local function test_vector2_offset_sort_in_area()
	assert_v2_equal(vector2.offset(vector2.new(1, 2), 40, 50), vector2.new(41, 52), "offset()")
	assert_v2_equal(vector2.new(1, 2):offset(40, 50), vector2.new(41, 52), ":offset() method")

	local a = vector2.new(1, 2)
	local b = vector2.new(0.5, 232)
	local lo, hi = vector2.sort(a, b)
	assert_v2_equal(lo, vector2.new(0.5, 2), "sort() lo")
	assert_v2_equal(hi, vector2.new(1, 232), "sort() hi")

	assert(vector2.in_area(vector2.zero(), vector2.new(-10, -10), vector2.new(10, 10)),
		"in_area() center")
	assert(vector2.in_area(vector2.new(-10, -10), vector2.new(-10, -10), vector2.new(10, 10)),
		"in_area() edge")
	assert(not vector2.in_area(vector2.new(-11, -10), vector2.new(-10, -10), vector2.new(10, 10)),
		"in_area() outside")
end
unittests.register("test_vector2_offset_sort_in_area", test_vector2_offset_sort_in_area)

local function test_vector2_from_to_angle_rotate()
	-- from_angle / to_angle
	assert_v2_equal(vector2.from_angle(0), vector2.new(1, 0), "from_angle(0)")
	assert_v2_equal(vector2.from_angle(math.pi / 2), vector2.new(0, 1), "from_angle(pi/2)")

	assert(nearly_equal(vector2.to_angle(vector2.new(1, 0)), 0), "to_angle() right")
	assert(nearly_equal(vector2.to_angle(vector2.new(0, 1)), math.pi / 2), "to_angle() up")

	local angle = math.pi / 3
	local v = vector2.from_angle(angle)
	assert(nearly_equal(vector2.to_angle(v), angle), "to_angle(from_angle()) roundtrip")

	-- rotate
	assert_v2_equal(vector2.rotate(vector2.new(1, 0), math.pi / 2), vector2.new(0, 1), "rotate(pi/2)")
	assert_v2_equal(vector2.new(1, 0):rotate(math.pi), vector2.new(-1, 0), ":rotate(pi)")

	local orig = vector2.new(3, 4)
	local rotated = vector2.rotate(orig, math.pi / 4)
	assert(nearly_equal(vector2.length(rotated), vector2.length(orig)),
		"rotate() preserves length")
end
unittests.register("test_vector2_from_to_angle_rotate", test_vector2_from_to_angle_rotate)

local function test_vector2_to_from_string()
	local v = vector2.new(1, 2)
	assert(vector2.to_string(v) == "(1, 2)", "to_string()")
	assert(tostring(v) == "(1, 2)", "tostring() uses metatable")
	assert(v:to_string() == "(1, 2)", ":to_string() method")

	local parsed, np = vector2.from_string("(1, 2)")
	assert(vector2.check(parsed), "from_string() has metatable")
	assert_v2_equal(parsed, v, "from_string() values")
	assert(np == 7, "from_string() next position")

	assert(vector2.from_string("nothing") == nil, "from_string() invalid returns nil")
end
unittests.register("test_vector2_to_from_string", test_vector2_to_from_string)

local function test_vector2_check()
	assert(not vector2.check(nil), "check(nil)")
	assert(not vector2.check(1), "check(number)")
	assert(not vector2.check({x=1, y=2}), "check(plain table)")
	local v = vector2.new(1, 2)
	assert(vector2.check(v), "check(vector2)")
	assert(v:check(), ":check() method")
end
unittests.register("test_vector2_check", test_vector2_check)

--
-- Engine API push/read test
--
-- This test verifies that the engine correctly pushes and reads 2D vectors
-- to and from Lua. It uses the spritediv property on player object properties,
-- which is a 2D vector in the engine (v2s16).
-- The test ensures that metatables are correctly set by vector2.check().
--
local function test_vector2_push_read(player)
	local old_props = player:get_properties()

	-- Set a vector2 value via engine API (spritediv is a v2s16 in the engine)
	player:set_properties({spritediv = vector2.new(5, 8)})
	local props = player:get_properties()
	local rv = props.spritediv
	assert(vector2.check(rv), "pushed vector2 has wrong metatable")
	assert(rv.x == 5 and rv.y == 8, "pushed vector2 values wrong")

	-- Plain table should also be accepted by the engine and returned as vector2
	player:set_properties({spritediv = {x = 3, y = 7}})
	props = player:get_properties()
	rv = props.spritediv
	assert(vector2.check(rv), "plain-table spritediv returned without metatable")
	assert(rv.x == 3 and rv.y == 7, "plain-table spritediv values wrong")

	player:set_properties({spritediv = old_props.spritediv})
end
unittests.register("test_vector2_push_read", test_vector2_push_read, {player=true})
