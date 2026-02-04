--[[
	Example demonstrating core.generate_caves() with custom parameters.
	
	This mod shows how to use core.generate_caves() to generate custom caves
	using the params table that allows overriding default cave generation
	parameters.
	
	The params table supports the following fields:
	- np_cave1: NoiseParams table for the first 3D noise defining tunnels
	- np_cave2: NoiseParams table for the second 3D noise defining tunnels
	- cave_width: Average width of tunnels in nodes (larger = wider, >= 10.0 disables)
	- large_cave_depth: Y coordinate of upper limit of large caves
	- small_cave_depth: Y coordinate of upper limit of small caves
	- small_cave_num_min: Minimum number of small caves per mapchunk
	- small_cave_num_max: Maximum number of small caves per mapchunk
	- large_cave_num_min: Minimum number of large caves per mapchunk
	- large_cave_num_max: Maximum number of large caves per mapchunk
	- large_cave_flooded: Proportion of large caves containing liquid (0.0-1.0)
]]

-- Register essential mapgen aliases if not already set
core.register_alias("mapgen_stone", "basenodes:stone")
core.register_alias("mapgen_water_source", "basenodes:water_source")
core.register_alias("mapgen_lava_source", "basenodes:lava_source")

-- Example 1: Generate caves with custom noise parameters
local function example_custom_noise_caves(vm, minp, maxp)
	-- Custom noise parameters for more varied cave tunnels
	local custom_params = {
		-- First noise pattern: larger scale tunnels
		np_cave1 = {
			offset = 0,
			scale = 12,
			spread = {x = 100, y = 100, z = 100},
			seed = 52534,
			octaves = 3,
			persist = 0.5,
			lacunarity = 2.0
		},
		-- Second noise pattern: intersecting with the first
		np_cave2 = {
			offset = 0,
			scale = 12,
			spread = {x = 90, y = 90, z = 90},
			seed = 10325,
			octaves = 3,
			persist = 0.5,
			lacunarity = 2.0
		},
		-- Wider tunnels: 12 nodes wide (larger value = wider)
		cave_width = 12,
		-- Large caves up to y = -20 (instead of default -33)
		large_cave_depth = -20,
		-- No small caves in this example
		small_cave_num_min = 0,
		small_cave_num_max = 0,
		-- 2-4 large caves per chunk
		large_cave_num_min = 2,
		large_cave_num_max = 4,
		-- 30% of large caves will be flooded
		large_cave_flooded = 0.3,
	}
	
	core.generate_caves(vm, minp, maxp, custom_params)
end

-- Example 2: Generate only small randomwalk caves (no noise-based caves)
local function example_small_caves_only(vm, minp, maxp)
	local params = {
		-- Disable noise-based caves by setting cave_width >= 10.0
		cave_width = 10.0,
		-- Limit small caves to y <= 10 (near surface)
		small_cave_depth = 10,
		-- Generate 3-5 small randomwalk caves per chunk
		small_cave_num_min = 3,
		small_cave_num_max = 5,
		-- No large caves
		large_cave_num_min = 0,
		large_cave_num_max = 0,
	}
	
	core.generate_caves(vm, minp, maxp, params)
end

-- Example 3: Generate mostly flooded caves
local function example_flooded_caves(vm, minp, maxp)
	local params = {
		-- Default noise parameters (omitted, will use mapgen defaults)
		-- Normal tunnel width: 8 nodes (default)
		cave_width = 8,
		-- Large caves up to y = -50 (deeper)
		large_cave_depth = -50,
		-- Few small caves
		small_cave_num_min = 0,
		small_cave_num_max = 1,
		-- More large caves
		large_cave_num_min = 1,
		large_cave_num_max = 3,
		-- 80% of large caves will be flooded with water/lava
		large_cave_flooded = 0.8,
	}
	
	core.generate_caves(vm, minp, maxp, params)
end

-- Example 4: Very tight/narrow cave network
local function example_narrow_caves(vm, minp, maxp)
	local params = {
		-- Very narrow tunnels: 4 nodes wide
		cave_width = 4,
		-- Standard depth for large caves
		large_cave_depth = -33,
		-- Limit small caves to deeper areas (y <= -10)
		small_cave_depth = -10,
		-- Many small caves
		small_cave_num_min = 2,
		small_cave_num_max = 4,
		-- Standard large caves
		large_cave_num_min = 0,
		large_cave_num_max = 2,
		-- Half flooded
		large_cave_flooded = 0.5,
	}
	
	core.generate_caves(vm, minp, maxp, params)
end

-- Main mapgen callback
-- NOTE: This is just an example. In a real mod, you would choose ONE of the
-- example functions above based on your needs, not run all of them.
core.register_on_generated(function(minp, maxp, blockseed)
	-- Get the voxel manipulator
	local vm, emin, emax = core.get_mapgen_object("voxelmanip")
	if not vm then
		return
	end
	
	-- Generate biomes first (required before generate_caves)
	-- This initializes the biomemap needed by cave generation
	core.generate_biomes(vm, emin, emax)
	
	-- Choose which example to use based on Y coordinate
	-- In a real mod, you'd typically use just one approach consistently
	if maxp.y < -100 then
		-- Deep underground: use flooded caves
		example_flooded_caves(vm, emin, emax)
	elseif maxp.y < -50 then
		-- Mid-depth: use custom noise caves
		example_custom_noise_caves(vm, emin, emax)
	elseif maxp.y < 0 then
		-- Shallow underground: use small caves only
		example_small_caves_only(vm, emin, emax)
	else
		-- Near surface: use narrow cave network
		example_narrow_caves(vm, emin, emax)
	end
	
	-- Write the voxel data back to the map
	vm:calc_lighting()
	vm:write_to_map()
	vm:update_liquids()
end)

--[[
	Additional notes:
	
	1. core.generate_biomes() must be called before core.generate_caves()
	   because cave generation reads the biomemap for biome-aware liquid placement.
	
	2. The params table is optional. If omitted, the function uses the current
	   mapgen's cave parameters, or sensible defaults for mapgens without
	   cave parameters (like singlenode).
	
	3. You can override only some parameters. Unspecified parameters will use
	   the mapgen's defaults.
	
	4. cave_width is specified in nodes. Larger values create wider tunnels.
	   The default is 8 nodes. Setting cave_width >= 10.0 completely disables
	   noise-based caves, leaving only randomwalk caves (small and large).
	
	5. The large_cave_flooded value is a probability (0.0 to 1.0). Each large
	   cave is randomly chosen to be flooded based on this value.
	
	6. large_cave_depth and small_cave_depth set the upper Y limit for their
	   respective cave types. Caves only generate at or below these levels.
	   By default, small_cave_depth is 31000 (no limit) and large_cave_depth
	   is -33.
	
	7. Cave generation parameters are per-mapchunk, not global.
]]
	
	5. The large_cave_flooded value is a probability (0.0 to 1.0). Each large
	   cave is randomly chosen to be flooded based on this value.
	
	6. Cave generation parameters are per-mapchunk, not global.
]]
