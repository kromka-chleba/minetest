-- Tests for core.get_node_content_counts()

-- Helper function to clear all nodes in a mapblock to air using voxel manipulator
local function clear_mapblock_to_air(blockpos)
	-- Convert blockpos to world coordinates
	-- A mapblock is 16x16x16, so multiply by 16 to get world position
	local minp = {
		x = blockpos.x * 16,
		y = blockpos.y * 16,
		z = blockpos.z * 16
	}
	local maxp = {
		x = minp.x + 15,
		y = minp.y + 15,
		z = minp.z + 15
	}
	
	-- Get voxel manipulator and load the area
	local vm = core.get_voxel_manip(minp, maxp)
	local data = vm:get_data()
	local emin, emax = vm:get_emerged_area()
	local va = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	
	-- Set all nodes in the mapblock to air
	for index in va:iterp(minp, maxp) do
		data[index] = core.CONTENT_AIR
	end
	
	-- Write the changes back to the map
	vm:set_data(data)
	vm:write_to_map()
end

-- Test 1: Check getting counts for not loaded or unexistent mapblock
local function test_get_node_content_counts_unloaded(_, pos)
	local far_blockpos = {x=10000, y=10000, z=10000}
	local counts = core.get_node_content_counts(far_blockpos)
	assert(counts == nil, "get_node_content_counts should return nil for non-existent/ungenerated block")
end
unittests.register("test_get_node_content_counts_unloaded", test_get_node_content_counts_unloaded, {map=true})

-- Test 2: Load a block, get node counts, set some nodes, verify counts changed
local function test_get_node_content_counts_changes(_, pos)
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	-- Clear the mapblock to air to ensure clean environment
	clear_mapblock_to_air(blockpos)
	
	-- Get initial counts for the loaded block
	local counts_before = core.get_node_content_counts(blockpos)
	assert(counts_before ~= nil, "get_node_content_counts should return counts for loaded block")
	assert(type(counts_before) == "table", "get_node_content_counts should return a table")
	
	-- Set some nodes to specific types
	local pos1 = {x=pos.x, y=pos.y, z=pos.z}
	local pos2 = {x=pos.x+1, y=pos.y, z=pos.z}
	core.set_node(pos1, {name="air"})
	core.set_node(pos2, {name="basenodes:stone"})
	
	-- Get counts after setting nodes
	local counts_after = core.get_node_content_counts(blockpos)
	assert(counts_after ~= nil, "Block should still be loaded")
	
	-- Verify counts changed
	local stone_id = core.get_content_id("basenodes:stone")
	assert(counts_after[stone_id] ~= nil, "Stone should be present in the block")
	assert(counts_after[stone_id] > 0, "Stone count should be positive")
end
unittests.register("test_get_node_content_counts_changes", test_get_node_content_counts_changes, {map=true})

-- Test 3: Iterate over all registered nodes, add them to mapblock, verify counts
local function test_get_node_content_counts_all_nodes(_, pos)
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	-- Clear the mapblock to air to ensure clean environment
	clear_mapblock_to_air(blockpos)
	
	-- Collect all registered node names and their content IDs
	local node_names = {}
	local expected_ids = {}
	for name, _ in pairs(core.registered_nodes) do
		table.insert(node_names, name)
		local id = core.get_content_id(name)
		expected_ids[id] = true
	end
	
	-- Place at least one of each node type in the mapblock
	-- A mapblock is 16x16x16, so we have 4096 positions available
	local positions_used = {}
	local idx = 0
	for x = 0, 15 do
		for y = 0, 15 do
			for z = 0, 15 do
				if idx >= #node_names then
					break
				end
				local node_pos = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
				core.set_node(node_pos, {name=node_names[idx+1]})
				table.insert(positions_used, node_pos)
				idx = idx + 1
			end
			if idx >= #node_names then
				break
			end
		end
		if idx >= #node_names then
			break
		end
	end
	
	-- Get counts and verify all node IDs are present
	local counts_with_all = core.get_node_content_counts(blockpos)
	assert(counts_with_all ~= nil, "Block should be loaded")
	
	-- Verify all expected node IDs are in the counts
	for id, _ in pairs(expected_ids) do
		assert(counts_with_all[id] ~= nil, 
			"Node ID " .. id .. " (" .. core.get_name_from_content_id(id) .. ") should be in counts")
	end
	
	local num_keys_before = 0
	for _ in pairs(counts_with_all) do
		num_keys_before = num_keys_before + 1
	end
	
	-- Set all changed nodes back to air
	for _, node_pos in ipairs(positions_used) do
		core.set_node(node_pos, {name="air"})
	end
	
	-- Get counts again and verify the number of unique content IDs decreased
	local counts_after_air = core.get_node_content_counts(blockpos)
	assert(counts_after_air ~= nil, "Block should still be loaded")
	
	local num_keys_after = 0
	for _ in pairs(counts_after_air) do
		num_keys_after = num_keys_after + 1
	end
	
	assert(num_keys_after < num_keys_before,
		"Number of unique content IDs should decrease after setting nodes to air. " ..
		"Before: " .. num_keys_before .. ", After: " .. num_keys_after)
end
unittests.register("test_get_node_content_counts_all_nodes", test_get_node_content_counts_all_nodes, {map=true})

