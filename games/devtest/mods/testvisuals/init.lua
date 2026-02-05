-- Test mod for player:set_node_visual() API
-- This mod provides chat commands to test various features of the set_node_visual API

-- Helper functions to get mapgen nodes (actually used in world generation)
local function get_test_node_stone()
	-- Most common mapgen node - used for terrain
	return "mapgen_stone"
end

local function get_test_node_dirt_grass()
	-- Surface layer node
	return "mapgen_dirt_with_grass"
end

local function get_test_node_sand()
	-- Beach and riverbed node
	return "mapgen_sand"
end

local function get_test_node_cobble()
	-- Dungeon node
	return "mapgen_cobble"
end

-- Test 1: Simple texture strings (backward compatibility)
core.register_chatcommand("test_visual_simple", {
	description = "Test set_node_visual with simple texture strings",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Change mapgen_stone to use dirt_with_grass texture on all faces
		player:set_node_visual(get_test_node_stone(), {
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png"
		})
		
		return true, "Stone (mapgen) now uses grass texture (simple strings)"
	end,
})

-- Test 2: Color tinting
core.register_chatcommand("test_visual_color", {
	description = "Test set_node_visual with color tinting",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Apply different colors to each face of mapgen_stone
		player:set_node_visual(get_test_node_stone(), {
			{name = "basenodes_stone.png", color = "#FF0000"},  -- Red top
			{name = "basenodes_stone.png", color = "#00FF00"},  -- Green bottom
			{name = "basenodes_stone.png", color = "#0000FF"},  -- Blue right
			{name = "basenodes_stone.png", color = "#FFFF00"},  -- Yellow left
			{name = "basenodes_stone.png", color = "#FF00FF"},  -- Magenta back
			{name = "basenodes_stone.png", color = "#00FFFF"}   -- Cyan front
		})
		
		return true, "Stone (mapgen) now has rainbow-colored faces"
	end,
})

-- Test 3: World-aligned textures with scale
core.register_chatcommand("test_visual_aligned", {
	description = "Test set_node_visual with world-aligned textures",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Apply world-aligned texture with scale to mapgen_stone
		player:set_node_visual(get_test_node_stone(), {
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 2
			},
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 2
			},
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 2
			},
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 2
			},
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 2
			},
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 2
			}
		})
		
		return true, "Stone (mapgen) now uses world-aligned texture with scale=2"
	end,
})

-- Test 4: Animated textures
core.register_chatcommand("test_visual_animated", {
	description = "Test set_node_visual with animated textures",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Apply animated texture to mapgen_stone
		-- Note: This will only show animation if the texture is actually animated
		player:set_node_visual(get_test_node_stone(), {
			{
				name = "basenodes_stone.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0
				}
			},
			{
				name = "basenodes_stone.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0
				}
			},
			{
				name = "basenodes_stone.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0
				}
			},
			{
				name = "basenodes_stone.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0
				}
			},
			{
				name = "basenodes_stone.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0
				}
			},
			{
				name = "basenodes_stone.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0
				}
			}
		})
		
		return true, "Stone (mapgen) now has animation definition (effect depends on texture)"
	end,
})

-- Test 5: Backface culling
core.register_chatcommand("test_visual_culling", {
	description = "Test set_node_visual with backface culling disabled",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Disable backface culling on mapgen_stone
		player:set_node_visual(get_test_node_stone(), {
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false}
		})
		
		return true, "Stone (mapgen) now has backface culling disabled"
	end,
})

-- Test 6: Mixed formats (strings and full definitions)
core.register_chatcommand("test_visual_mixed", {
	description = "Test set_node_visual with mixed tile formats",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Mix simple strings with full tile definitions on mapgen_stone
		player:set_node_visual(get_test_node_stone(), {
			"basenodes_dirt.png",  -- Simple string for top
			"basenodes_sand.png",  -- Simple string for bottom
			{name = "basenodes_stone.png", color = "#FF0000"},  -- Red tinted right
			{name = "basenodes_stone.png", color = "#00FF00"},  -- Green tinted left
			{name = "basenodes_stone.png", backface_culling = false},  -- No culling back
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 1
			}  -- World-aligned front
		})
		
		return true, "Stone (mapgen) now has mixed tile definitions"
	end,
})

-- Test 7: Different texture on each face
core.register_chatcommand("test_visual_multiface", {
	description = "Test set_node_visual with different texture on each face",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Use different textures for each face of mapgen_stone
		player:set_node_visual(get_test_node_stone(), {
			"basenodes_grass.png",          -- Top (grass)
			"basenodes_dirt.png",           -- Bottom (dirt)
			"basenodes_sand.png",           -- Right (sand)
			"basenodes_cobble.png",         -- Left (cobble)
			"basenodes_stone.png",          -- Back (stone)
			"basenodes_grass_side.png"      -- Front (grass side)
		})
		
		return true, "Stone (mapgen) faces now have different textures"
	end,
})

-- Test 8: Apply visual changes to multiple mapgen nodes
core.register_chatcommand("test_visual_multi", {
	description = "Test set_node_visual on multiple different mapgen nodes",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Change mapgen_stone (terrain)
		player:set_node_visual(get_test_node_stone(), {
			{name = "basenodes_sand.png", color = "#FF8800"}
		})
		
		-- Change mapgen_dirt_with_grass (surface)
		player:set_node_visual(get_test_node_dirt_grass(), {
			{name = "basenodes_stone.png", color = "#8888FF"}
		})
		
		-- Change mapgen_sand (beaches)
		player:set_node_visual(get_test_node_sand(), {
			{name = "basenodes_dirt.png", color = "#88FF88"}
		})
		
		-- Change mapgen_cobble (dungeons)
		player:set_node_visual(get_test_node_cobble(), {
			{name = "basenodes_grass.png", color = "#FF88FF"}
		})
		
		return true, "Multiple mapgen nodes changed: stone, dirt_with_grass, sand, and cobble"
	end,
})

-- Reset command to restore original textures
core.register_chatcommand("test_visual_reset", {
	description = "Reset mapgen node visuals to default (requires server restart to fully restore)",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Reset mapgen_stone to its original texture
		player:set_node_visual(get_test_node_stone(), {
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png"
		})
		
		-- Reset mapgen_dirt_with_grass
		player:set_node_visual(get_test_node_dirt_grass(), {
			"basenodes_grass.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png",
			"basenodes_dirt.png^basenodes_grass_side.png"
		})
		
		-- Reset mapgen_sand
		player:set_node_visual(get_test_node_sand(), {
			"basenodes_sand.png",
			"basenodes_sand.png",
			"basenodes_sand.png",
			"basenodes_sand.png",
			"basenodes_sand.png",
			"basenodes_sand.png"
		})
		
		-- Reset mapgen_cobble
		player:set_node_visual(get_test_node_cobble(), {
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png"
		})
		
		return true, "Mapgen node visuals reset to default textures"
	end,
})

-- Help command listing all available tests
core.register_chatcommand("test_visual_help", {
	description = "Show help for set_node_visual test commands",
	func = function(name)
		return true, [[
Available test_visual commands:
  /test_visual_simple - Simple texture strings (backward compatible)
  /test_visual_color - Color tinting on each face
  /test_visual_aligned - World-aligned textures with scale
  /test_visual_animated - Animated texture definitions
  /test_visual_culling - Backface culling disabled
  /test_visual_mixed - Mixed tile formats (strings + tables)
  /test_visual_multiface - Different texture per face
  /test_visual_multi - Apply to multiple mapgen node types
  /test_visual_reset - Reset to default textures
  /test_visual_help - Show this help

Tests use mapgen nodes (actually used in world generation):
  - mapgen_stone (terrain)
  - mapgen_dirt_with_grass (surface)
  - mapgen_sand (beaches/riverbeds)
  - mapgen_cobble (dungeons)

Note: Changes are global and affect all players.
The world terrain will change appearance when you run these commands!
]]
	end,
})

core.log("action", "[testvisuals] Test mod for set_node_visual() loaded")
