-- Tests for core.get_mapblock_data()

local function test_get_mapblock_data_nil(_, pos)
	-- Test that get_mapblock_data returns nil for non-existent block
	-- Use a position far away that's unlikely to be generated
	local far_blockpos = {x=10000, y=10000, z=10000}
	local data = core.get_mapblock_data(far_blockpos)
	assert(data == nil, "get_mapblock_data should return nil for non-existent/ungenerated block")
end
unittests.register("test_get_mapblock_data_nil", test_get_mapblock_data_nil, {map=true})

local function test_get_mapblock_data_exists(_, pos)
	-- Get the mapblock position for the provided test position
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	-- The test position should be in an existing block (loaded or on disk)
	local data = core.get_mapblock_data(blockpos)
	assert(data ~= nil, "get_mapblock_data should return data for existing block")
	assert(type(data) == "table", "get_mapblock_data should return a table")
end
unittests.register("test_get_mapblock_data_exists", test_get_mapblock_data_exists, {map=true})

local function test_get_mapblock_data_fields(_, pos)
	-- Get the mapblock position for the provided test position
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	local data = core.get_mapblock_data(blockpos)
	assert(data ~= nil, "Block should exist")
	
	-- Check that all expected fields are present
	assert(data.pos ~= nil, "data.pos should exist")
	assert(type(data.pos) == "table", "data.pos should be a table")
	assert(data.pos.x == blockpos.x, "data.pos.x should match input")
	assert(data.pos.y == blockpos.y, "data.pos.y should match input")
	assert(data.pos.z == blockpos.z, "data.pos.z should match input")
	
	assert(data.node_mapping ~= nil, "data.node_mapping should exist")
	assert(type(data.node_mapping) == "table", "data.node_mapping should be a table")
	
	assert(data.timestamp ~= nil, "data.timestamp should exist")
	assert(type(data.timestamp) == "number", "data.timestamp should be a number")
	
	assert(data.is_underground ~= nil, "data.is_underground should exist")
	assert(type(data.is_underground) == "boolean", "data.is_underground should be a boolean")
end
unittests.register("test_get_mapblock_data_fields", test_get_mapblock_data_fields, {map=true})

local function test_get_mapblock_data_node_mapping(_, pos)
	-- Get the mapblock position for the provided test position
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	-- Place some known nodes at the test position
	core.set_node(pos, {name="air"})
	local pos2 = {x=pos.x+1, y=pos.y, z=pos.z}
	core.set_node(pos2, {name="basenodes:stone"})
	
	local data = core.get_mapblock_data(blockpos)
	assert(data ~= nil, "Block should exist")
	assert(data.node_mapping ~= nil, "node_mapping should exist")
	
	-- Check that node_mapping contains at least some entries
	local count = 0
	local has_air = false
	local has_stone = false
	
	for id, name in pairs(data.node_mapping) do
		count = count + 1
		assert(type(id) == "number", "node_mapping keys should be numbers")
		assert(type(name) == "string", "node_mapping values should be strings")
		
		if name == "air" then
			has_air = true
		elseif name == "basenodes:stone" then
			has_stone = true
		end
	end
	
	assert(count > 0, "node_mapping should contain at least one entry")
	assert(has_air, "node_mapping should contain 'air'")
	assert(has_stone, "node_mapping should contain 'basenodes:stone'")
end
unittests.register("test_get_mapblock_data_node_mapping", test_get_mapblock_data_node_mapping, {map=true})
