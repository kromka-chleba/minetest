-- Tests for core.get_node_content_counts()

local function test_get_node_content_counts_nil(_, pos)
	local far_blockpos = {x=10000, y=10000, z=10000}
	local counts = core.get_node_content_counts(far_blockpos)
	assert(counts == nil, "get_node_content_counts should return nil for non-existent/ungenerated block")
end
unittests.register("test_get_node_content_counts_nil", test_get_node_content_counts_nil, {map=true})

local function test_get_node_content_counts_exists(_, pos)
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	local counts = core.get_node_content_counts(blockpos)
	assert(counts ~= nil, "get_node_content_counts should return counts for existing block")
	assert(type(counts) == "table", "get_node_content_counts should return a table")
end
unittests.register("test_get_node_content_counts_exists", test_get_node_content_counts_exists, {map=true})

local function test_get_node_content_counts_content(_, pos)
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
	core.set_node(pos, {name="air"})
	local pos2 = {x=pos.x+1, y=pos.y, z=pos.z}
	core.set_node(pos2, {name="basenodes:stone"})
	
	local counts = core.get_node_content_counts(blockpos)
	assert(counts ~= nil, "Block should exist")
	
	local total_count = 0
	for id, count in pairs(counts) do
		total_count = total_count + 1
		assert(type(id) == "number", "count keys should be numbers")
		assert(type(count) == "number", "count values should be numbers")
		assert(count > 0, "counts should be positive")
	end
	
	assert(total_count > 0, "counts should contain at least one entry")
end
unittests.register("test_get_node_content_counts_content", test_get_node_content_counts_content, {map=true})

local function test_get_node_content_counts_only_present_nodes(_, pos)
	local blockpos = {
		x = math.floor(pos.x / 16),
		y = math.floor(pos.y / 16),
		z = math.floor(pos.z / 16)
	}
	
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
	
	local counts = core.get_node_content_counts(blockpos)
	assert(counts ~= nil, "Block should exist")
	
	local unique_count = 0
	for id, count in pairs(counts) do
		unique_count = unique_count + 1
	end
	
	assert(unique_count < 50,
		"counts should only contain nodes present in block, not all registered nodes. Found " ..
		unique_count .. " entries")
end
unittests.register("test_get_node_content_counts_only_present_nodes", test_get_node_content_counts_only_present_nodes, {map=true})

