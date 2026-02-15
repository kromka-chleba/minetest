-- Tests for core.get_node_content_counts()

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

