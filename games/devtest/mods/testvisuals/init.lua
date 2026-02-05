-- Test mod for player:set_node_visual() API
-- This mod provides chat commands to test various features of the set_node_visual API

-- Helper function to get basenodes
local function get_test_node()
	-- Use a common node from basenodes mod
	return "basenodes:stone"
end

local function get_test_node_dirt()
	return "basenodes:dirt"
end

local function get_test_node_cobble()
	return "basenodes:cobble"
end

-- Test 1: Simple texture strings (backward compatibility)
core.register_chatcommand("test_visual_simple", {
	description = "Test set_node_visual with simple texture strings",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Change stone to use dirt texture on all faces
		player:set_node_visual(get_test_node(), {
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png"
		})
		
		return true, "Stone now uses dirt texture (simple strings)"
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
		
		-- Apply different colors to each face of stone
		player:set_node_visual(get_test_node(), {
			{name = "basenodes_stone.png", color = "#FF0000"},  -- Red top
			{name = "basenodes_stone.png", color = "#00FF00"},  -- Green bottom
			{name = "basenodes_stone.png", color = "#0000FF"},  -- Blue right
			{name = "basenodes_stone.png", color = "#FFFF00"},  -- Yellow left
			{name = "basenodes_stone.png", color = "#FF00FF"},  -- Magenta back
			{name = "basenodes_stone.png", color = "#00FFFF"}   -- Cyan front
		})
		
		return true, "Stone now has rainbow-colored faces"
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
		
		-- Apply world-aligned texture with scale
		player:set_node_visual(get_test_node(), {
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
		
		return true, "Stone now uses world-aligned texture with scale=2"
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
		
		-- Apply animated texture (if the texture has multiple frames)
		-- Note: This will only show animation if the texture is actually animated
		player:set_node_visual(get_test_node(), {
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
		
		return true, "Stone now has animation definition (effect depends on texture)"
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
		
		-- Disable backface culling (useful for glass-like nodes)
		player:set_node_visual(get_test_node(), {
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false},
			{name = "basenodes_stone.png", backface_culling = false}
		})
		
		return true, "Stone now has backface culling disabled"
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
		
		-- Mix simple strings with full tile definitions
		player:set_node_visual(get_test_node(), {
			"basenodes_dirt.png",  -- Simple string for top
			"basenodes_cobble.png",  -- Simple string for bottom
			{name = "basenodes_stone.png", color = "#FF0000"},  -- Red tinted right
			{name = "basenodes_stone.png", color = "#00FF00"},  -- Green tinted left
			{name = "basenodes_stone.png", backface_culling = false},  -- No culling back
			{
				name = "basenodes_stone.png",
				align_style = "world",
				scale = 1
			}  -- World-aligned front
		})
		
		return true, "Stone now has mixed tile definitions"
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
		
		-- Use different textures for each face
		player:set_node_visual(get_test_node(), {
			"basenodes_dirt.png",      -- Top
			"basenodes_cobble.png",    -- Bottom
			"basenodes_stone.png",     -- Right
			"basenodes_dirt.png",      -- Left
			"basenodes_cobble.png",    -- Back
			"basenodes_stone.png"      -- Front
		})
		
		return true, "Stone faces now have different textures"
	end,
})

-- Test 8: Apply visual changes to multiple nodes
core.register_chatcommand("test_visual_multi", {
	description = "Test set_node_visual on multiple different nodes",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Change stone
		player:set_node_visual(get_test_node(), {
			{name = "basenodes_dirt.png", color = "#FF8800"}
		})
		
		-- Change dirt
		player:set_node_visual(get_test_node_dirt(), {
			{name = "basenodes_stone.png", color = "#8888FF"}
		})
		
		-- Change cobble
		player:set_node_visual(get_test_node_cobble(), {
			{name = "basenodes_dirt.png", color = "#88FF88"}
		})
		
		return true, "Multiple nodes changed: stone, dirt, and cobble"
	end,
})

-- Reset command to restore original textures
core.register_chatcommand("test_visual_reset", {
	description = "Reset node visuals to default (requires server restart to fully restore)",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		
		-- Reset stone to its original texture
		player:set_node_visual(get_test_node(), {
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png",
			"basenodes_stone.png"
		})
		
		-- Reset dirt
		player:set_node_visual(get_test_node_dirt(), {
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png",
			"basenodes_dirt.png"
		})
		
		-- Reset cobble
		player:set_node_visual(get_test_node_cobble(), {
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png",
			"basenodes_cobble.png"
		})
		
		return true, "Node visuals reset to default textures"
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
  /test_visual_multi - Apply to multiple node types
  /test_visual_reset - Reset to default textures
  /test_visual_help - Show this help

Note: Changes are global and affect all players.
Place some stone, dirt, and cobble nodes to see the effects.
]]
	end,
})

core.log("action", "[testvisuals] Test mod for set_node_visual() loaded")
