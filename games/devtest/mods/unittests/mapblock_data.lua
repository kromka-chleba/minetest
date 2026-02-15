-- Tests for core.get_node_id_mapping()

local function test_get_node_id_mapping_nil(_, pos)
	-- Test that get_node_id_mapping returns nil for non-existent block
	-- Use a position far away that's unlikely to be generated
	local far_blockpos = {x=10000, y=10000, z=10000}
	local mapping = core.get_node_id_mapping(far_blockpos)
	assert(mapping == nil, "get_node_id_mapping should return nil for non-existent/ungenerated block")
end
unittests.register("test_get_node_id_mapping_nil", test_get_node_id_mapping_nil, {map=true})

local function test_get_node_id_mapping_exists(_, pos)
	-- Get the mapblock position for the provided test position
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	-- The test position should be in an existing block (loaded or on disk)
	local mapping = core.get_node_id_mapping(blockpos)
	assert(mapping ~= nil, "get_node_id_mapping should return mapping for existing block")
	assert(type(mapping) == "table", "get_node_id_mapping should return a table")
end
unittests.register("test_get_node_id_mapping_exists", test_get_node_id_mapping_exists, {map=true})

local function test_get_node_id_mapping_content(_, pos)
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
	
	local mapping = core.get_node_id_mapping(blockpos)
	assert(mapping ~= nil, "Block should exist")
	
	-- Check that mapping contains at least some entries
	local count = 0
	local has_air = false
	local has_stone = false
	
	for id, name in pairs(mapping) do
		count = count + 1
		assert(type(id) == "number", "mapping keys should be numbers")
		assert(type(name) == "string", "mapping values should be strings")
		
		if name == "air" then
			has_air = true
		elseif name == "basenodes:stone" then
			has_stone = true
		end
	end
	
	assert(count > 0, "mapping should contain at least one entry")
	assert(has_air, "mapping should contain 'air'")
	assert(has_stone, "mapping should contain 'basenodes:stone'")
end
unittests.register("test_get_node_id_mapping_content", test_get_node_id_mapping_content, {map=true})

local function test_get_node_id_mapping_only_present_nodes(_, pos)
	-- This test verifies that the mapping contains ONLY nodes that are
	-- actually present in the mapblock, not all possible registered nodes
	
	-- Create a block with only a few specific node types
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	-- Fill a small area with specific nodes
	for i = 0, 2 do
		for j = 0, 2 do
			for k = 0, 2 do
				local p = {x=pos.x+i, y=pos.y+j, z=pos.z+k}
				if i == 0 and j == 0 and k == 0 then
					core.set_node(p, {name="air"})
				elseif i == 1 and j == 0 and k == 0 then
					core.set_node(p, {name="basenodes:stone"})
				else
					core.set_node(p, {name="ignore"})
				end
			end
		end
	end
	
	local mapping = core.get_node_id_mapping(blockpos)
	assert(mapping ~= nil, "Block should exist")
	
	-- Count how many different node types are in the mapping
	local mapping_count = 0
	local has_unexpected = false
	local unexpected_nodes = {}
	
	for id, name in pairs(mapping) do
		mapping_count = mapping_count + 1
		-- Only air, stone, and possibly ignore should be present
		-- (ignore might be from other parts of the block we didn't set)
		if name ~= "air" and name ~= "basenodes:stone" and name ~= "ignore" then
			has_unexpected = true
			table.insert(unexpected_nodes, name)
		end
	end
	
	-- The mapping should be relatively small - definitely not hundreds of entries
	-- which would indicate all registered nodes are included
	assert(mapping_count < 50, 
		"mapping should only contain nodes present in block, not all registered nodes. Found " .. 
		mapping_count .. " entries")
	
	-- If we found unexpected nodes (other than the ones we set or background nodes),
	-- that might indicate the mapping includes too much
	if has_unexpected and #unexpected_nodes > 10 then
		assert(false, "Found many unexpected nodes in mapping: " .. table.concat(unexpected_nodes, ", "))
	end
end
unittests.register("test_get_node_id_mapping_only_present_nodes", test_get_node_id_mapping_only_present_nodes, {map=true})

