--[[
Example code for core.get_node_counts_in_area()

This function counts specific node types in a given area.
Useful for analyzing terrain, checking build progress, or resource scanning.

Syntax: core.get_node_counts_in_area(minp, maxp, nodenames)
  minp      - Minimum position {x, y, z}
  maxp      - Maximum position {x, y, z}
  nodenames - Node name string or table of node name strings
Returns: Table with node names as keys and counts as values
]]

-- Example 1: Count a single node type
-- Use case: Check how much stone is in a mining area
local function example_single_node()
	local minp = {x = 0, y = 0, z = 0}
	local maxp = {x = 10, y = 10, z = 10}
	
	-- Count only stone nodes
	local counts = core.get_node_counts_in_area(minp, maxp, "default:stone")
	
	print("Stone count: " .. (counts["default:stone"] or 0))
end

-- Example 2: Count multiple node types
-- Use case: Analyze composition of a terrain area
local function example_multiple_nodes()
	local minp = {x = 0, y = -10, z = 0}
	local maxp = {x = 20, y = 10, z = 20}
	
	-- Count several different node types
	local node_list = {
		"default:stone",
		"default:dirt",
		"default:sand",
		"air"
	}
	
	local counts = core.get_node_counts_in_area(minp, maxp, node_list)
	
	-- Display results
	print("Node composition in area:")
	for node_name, count in pairs(counts) do
		print("  " .. node_name .. ": " .. count)
	end
end

-- Example 3: Ore detection and analysis
-- Use case: Scan an area for valuable ores
local function example_ore_detection(center_pos, radius)
	local minp = {
		x = center_pos.x - radius,
		y = center_pos.y - radius,
		z = center_pos.z - radius
	}
	local maxp = {
		x = center_pos.x + radius,
		y = center_pos.y + radius,
		z = center_pos.z + radius
	}
	
	-- Search for ore nodes
	local ore_types = {
		"default:stone_with_coal",
		"default:stone_with_iron",
		"default:stone_with_copper",
		"default:stone_with_gold",
		"default:stone_with_diamond"
	}
	
	local counts = core.get_node_counts_in_area(minp, maxp, ore_types)
	
	-- Calculate total ores found
	local total_ores = 0
	for node_name, count in pairs(counts) do
		total_ores = total_ores + count
	end
	
	if total_ores > 0 then
		print("Found " .. total_ores .. " ore nodes:")
		for node_name, count in pairs(counts) do
			if count > 0 then
				print("  " .. node_name .. ": " .. count)
			end
		end
	else
		print("No ores found in this area")
	end
	
	return counts
end

-- Example 4: Building progress checker
-- Use case: Verify that a build area has been cleared or filled
local function example_build_checker(build_area_min, build_area_max)
	-- Check if area is clear (only air)
	local counts = core.get_node_counts_in_area(build_area_min, build_area_max, "air")
	
	local total_volume = 
		(build_area_max.x - build_area_min.x + 1) *
		(build_area_max.y - build_area_min.y + 1) *
		(build_area_max.z - build_area_min.z + 1)
	
	local air_count = counts["air"] or 0
	local percent_clear = (air_count / total_volume) * 100
	
	print(string.format("Build area is %.1f%% clear (%d/%d air nodes)",
		percent_clear, air_count, total_volume))
	
	return air_count == total_volume
end

-- Example 5: Resource density calculation
-- Use case: Find the best mining spot based on ore density
local function example_resource_density(player_pos)
	local search_radius = 5
	local best_spot = nil
	local best_density = 0
	
	-- Scan multiple positions around player
	for x_offset = -20, 20, 10 do
		for z_offset = -20, 20, 10 do
			local scan_pos = {
				x = player_pos.x + x_offset,
				y = player_pos.y,
				z = player_pos.z + z_offset
			}
			
			local minp = {
				x = scan_pos.x - search_radius,
				y = scan_pos.y - search_radius,
				z = scan_pos.z - search_radius
			}
			local maxp = {
				x = scan_pos.x + search_radius,
				y = scan_pos.y + search_radius,
				z = scan_pos.z + search_radius
			}
			
			-- Count iron ore
			local counts = core.get_node_counts_in_area(minp, maxp, "default:stone_with_iron")
			local iron_count = counts["default:stone_with_iron"] or 0
			
			if iron_count > best_density then
				best_density = iron_count
				best_spot = scan_pos
			end
		end
	end
	
	if best_spot then
		print(string.format("Best mining spot at (%d, %d, %d) with %d iron ore nodes",
			best_spot.x, best_spot.y, best_spot.z, best_density))
	end
	
	return best_spot
end

-- Example 6: Using with node groups (requires filtering afterwards)
-- Use case: Count all tree nodes regardless of type
local function example_node_filtering(area_min, area_max)
	-- Get all registered node names that are trees
	local tree_nodes = {}
	for name, def in pairs(core.registered_nodes) do
		if def.groups and def.groups.tree then
			table.insert(tree_nodes, name)
		end
	end
	
	-- Count all tree types
	local counts = core.get_node_counts_in_area(area_min, area_max, tree_nodes)
	
	-- Sum up all tree counts
	local total_trees = 0
	for node_name, count in pairs(counts) do
		total_trees = total_trees + count
	end
	
	print("Total tree nodes in area: " .. total_trees)
	return total_trees
end

--[[
Performance notes:
- Large areas will take more time to process
- Keep area size reasonable (e.g., 100x100x100 or smaller for frequent calls)
- Only query for node types you actually need
- Results are immediate; no callbacks required

Common patterns:
1. Define area boundaries (minp, maxp)
2. Specify which nodes to count (string or table)
3. Call core.get_node_counts_in_area()
4. Process the returned table of counts

Error handling:
- Returns empty table if area is not loaded
- Returns 0 count for nodes not found in the area
- Node names must be valid registered node names
]]
