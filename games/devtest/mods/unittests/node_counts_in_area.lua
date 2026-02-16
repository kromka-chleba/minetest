-- Tests for core.get_node_counts_in_area()

-- Helper function to clear nodes in an area
local function clear_area_to_air(minp, maxp)
	local vm = core.get_voxel_manip(minp, maxp)
	local data = vm:get_data()
	
	for index = 1, #data do
		data[index] = core.CONTENT_AIR
	end
	
	vm:set_data(data)
	vm:write_to_map()
end

-- Test 1: Count all nodes in an arbitrary area (not mapblock-aligned)
local function test_get_node_counts_arbitrary_area(_, pos)
	-- Use a non-mapblock-aligned area like 10x15x20
	local minp = {x=pos.x, y=pos.y, z=pos.z}
	local maxp = {x=pos.x+9, y=pos.y+14, z=pos.z+19}
	
	-- Clear the area
	clear_area_to_air(minp, maxp)
	
	-- Get counts for all nodes
	local counts = core.get_node_counts_in_area(minp, maxp)
	assert(counts ~= nil, "get_node_counts_in_area should return counts")
	assert(type(counts) == "table", "get_node_counts_in_area should return a table")
	
	-- Expected volume: 10 * 15 * 20 = 3000 nodes
	local air_id = core.get_content_id("air")
	assert(counts[air_id] == 3000, "Should have 3000 air nodes in 10x15x20 area")
end
unittests.register("test_get_node_counts_arbitrary_area", test_get_node_counts_arbitrary_area, {map=true})

-- Test 2: Count specific nodes with filtering
local function test_get_node_counts_with_filter(_, pos)
	local minp = {x=pos.x, y=pos.y, z=pos.z}
	local maxp = {x=pos.x+15, y=pos.y+15, z=pos.z+15}
	
	-- Clear the area
	clear_area_to_air(minp, maxp)
	
	-- Add some specific nodes
	core.set_node({x=pos.x+5, y=pos.y+5, z=pos.z+5}, {name="basenodes:stone"})
	core.set_node({x=pos.x+6, y=pos.y+5, z=pos.z+5}, {name="basenodes:stone"})
	core.set_node({x=pos.x+7, y=pos.y+5, z=pos.z+5}, {name="basenodes:dirt"})
	core.set_node({x=pos.x+8, y=pos.y+5, z=pos.z+5}, {name="basenodes:dirt"})
	core.set_node({x=pos.x+9, y=pos.y+5, z=pos.z+5}, {name="basenodes:dirt"})
	
	-- Count only stone and dirt, filtering out air
	local counts = core.get_node_counts_in_area(minp, maxp, {"basenodes:stone", "basenodes:dirt"})
	assert(counts ~= nil, "Should return counts")
	
	local stone_id = core.get_content_id("basenodes:stone")
	local dirt_id = core.get_content_id("basenodes:dirt")
	
	assert(counts[stone_id] == 2, "Should have 2 stone nodes")
	assert(counts[dirt_id] == 3, "Should have 3 dirt nodes")
	
	-- Air should not be in the filtered results
	local air_id = core.get_content_id("air")
	assert(counts[air_id] == nil, "Air should not be counted when filtering")
end
unittests.register("test_get_node_counts_with_filter", test_get_node_counts_with_filter, {map=true})

-- Test 3: Count with single node filter (string parameter)
local function test_get_node_counts_single_filter(_, pos)
	local minp = {x=pos.x, y=pos.y, z=pos.z}
	local maxp = {x=pos.x+7, y=pos.y+7, z=pos.z+7}
	
	-- Clear the area
	clear_area_to_air(minp, maxp)
	
	-- Add several stone nodes
	core.set_node({x=pos.x+1, y=pos.y+1, z=pos.z+1}, {name="basenodes:stone"})
	core.set_node({x=pos.x+2, y=pos.y+2, z=pos.z+2}, {name="basenodes:stone"})
	core.set_node({x=pos.x+3, y=pos.y+3, z=pos.z+3}, {name="basenodes:stone"})
	core.set_node({x=pos.x+4, y=pos.y+4, z=pos.z+4}, {name="basenodes:dirt"})
	
	-- Count only stone (string parameter, not table)
	local counts = core.get_node_counts_in_area(minp, maxp, "basenodes:stone")
	assert(counts ~= nil, "Should return counts")
	
	local stone_id = core.get_content_id("basenodes:stone")
	assert(counts[stone_id] == 3, "Should have 3 stone nodes")
	
	-- Dirt and air should not be counted
	local dirt_id = core.get_content_id("basenodes:dirt")
	local air_id = core.get_content_id("air")
	assert(counts[dirt_id] == nil, "Dirt should not be counted")
	assert(counts[air_id] == nil, "Air should not be counted")
end
unittests.register("test_get_node_counts_single_filter", test_get_node_counts_single_filter, {map=true})

-- Test 4: Compare with find_nodes_in_area for correctness
local function test_get_node_counts_vs_find_nodes(_, pos)
	local minp = {x=pos.x, y=pos.y, z=pos.z}
	local maxp = {x=pos.x+10, y=pos.y+10, z=pos.z+10}
	
	-- Clear the area
	clear_area_to_air(minp, maxp)
	
	-- Add a mix of nodes
	core.set_node({x=pos.x+1, y=pos.y+1, z=pos.z+1}, {name="basenodes:stone"})
	core.set_node({x=pos.x+2, y=pos.y+2, z=pos.z+2}, {name="basenodes:stone"})
	core.set_node({x=pos.x+3, y=pos.y+3, z=pos.z+3}, {name="basenodes:dirt"})
	
	-- Get counts using new API
	local counts = core.get_node_counts_in_area(minp, maxp, {"basenodes:stone", "basenodes:dirt"})
	
	-- Get positions using find_nodes_in_area and count them manually
	local positions, position_counts = core.find_nodes_in_area(minp, maxp, {"basenodes:stone", "basenodes:dirt"})
	
	-- Compare the counts
	assert(counts ~= nil and position_counts ~= nil, "Both should return results")
	
	-- position_counts is a table with node names as keys
	local stone_count_from_find = position_counts["basenodes:stone"] or 0
	local dirt_count_from_find = position_counts["basenodes:dirt"] or 0
	
	local stone_id = core.get_content_id("basenodes:stone")
	local dirt_id = core.get_content_id("basenodes:dirt")
	
	assert(counts[stone_id] == stone_count_from_find, 
		"Stone count should match between APIs: " .. tostring(counts[stone_id]) .. " vs " .. tostring(stone_count_from_find))
	assert(counts[dirt_id] == dirt_count_from_find,
		"Dirt count should match between APIs: " .. tostring(counts[dirt_id]) .. " vs " .. tostring(dirt_count_from_find))
end
unittests.register("test_get_node_counts_vs_find_nodes", test_get_node_counts_vs_find_nodes, {map=true})

-- Test 5: Area spanning multiple mapblocks
local function test_get_node_counts_multi_mapblock(_, pos)
	-- Create an area that spans multiple mapblocks (e.g., 32x32x32)
	local minp = {x=pos.x, y=pos.y, z=pos.z}
	local maxp = {x=pos.x+31, y=pos.y+31, z=pos.z+31}
	
	-- Clear the area
	clear_area_to_air(minp, maxp)
	
	-- Add some nodes distributed across the area
	core.set_node({x=pos.x+5, y=pos.y+5, z=pos.z+5}, {name="basenodes:stone"})
	core.set_node({x=pos.x+20, y=pos.y+20, z=pos.z+20}, {name="basenodes:stone"})
	core.set_node({x=pos.x+30, y=pos.y+30, z=pos.z+30}, {name="basenodes:stone"})
	
	-- Count all nodes
	local counts = core.get_node_counts_in_area(minp, maxp)
	assert(counts ~= nil, "Should return counts")
	
	local stone_id = core.get_content_id("basenodes:stone")
	local air_id = core.get_content_id("air")
	
	-- Expected: 32*32*32 = 32768 total nodes, 3 stone, rest air
	assert(counts[stone_id] == 3, "Should have 3 stone nodes")
	assert(counts[air_id] == 32768 - 3, "Should have 32765 air nodes")
end
unittests.register("test_get_node_counts_multi_mapblock", test_get_node_counts_multi_mapblock, {map=true})
