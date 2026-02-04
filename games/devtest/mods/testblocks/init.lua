-- Test mod for block loading callbacks and tracking tables

local function print_to_everything(msg)
	core.log("action", "[testblocks] " .. msg)
	core.chat_send_all("[testblocks] " .. msg)
end

-- Register on_block_loaded callback
core.register_on_block_loaded(function(blockpos)
	print_to_everything("Block loaded at " .. core.pos_to_string(blockpos))
end)

-- Register on_block_activated callback
core.register_on_block_activated(function(blockpos)
	print_to_everything("Block activated at " .. core.pos_to_string(blockpos))
end)

-- Register on_block_unloaded callback
core.register_on_block_unloaded(function(blockpos_list)
	if #blockpos_list > 0 then
		print_to_everything("Blocks unloaded: " .. #blockpos_list)
		-- Print first few positions for debugging
		for i = 1, math.min(3, #blockpos_list) do
			print_to_everything("  - " .. core.pos_to_string(blockpos_list[i]))
		end
		if #blockpos_list > 3 then
			print_to_everything("  ... and " .. (#blockpos_list - 3) .. " more")
		end
	end
end)

-- Add chat commands to query loaded and active blocks
core.register_chatcommand("list_loaded_blocks", {
	description = "List all currently loaded blocks",
	func = function(name, param)
		local count = 0
		local examples = {}
		
		for hash, _ in pairs(core.loaded_blocks) do
			count = count + 1
			if count <= 5 then
				local pos = core.get_position_from_hash(hash)
				table.insert(examples, core.pos_to_string(pos))
			end
		end
		
		local msg = "Total loaded blocks: " .. count
		if #examples > 0 then
			msg = msg .. "\nFirst " .. #examples .. " examples:\n  " .. table.concat(examples, "\n  ")
		end
		
		return true, msg
	end,
})

core.register_chatcommand("list_active_blocks", {
	description = "List all currently active blocks",
	func = function(name, param)
		local count = 0
		local examples = {}
		
		for hash, _ in pairs(core.active_blocks) do
			count = count + 1
			if count <= 5 then
				local pos = core.get_position_from_hash(hash)
				table.insert(examples, core.pos_to_string(pos))
			end
		end
		
		local msg = "Total active blocks: " .. count
		if #examples > 0 then
			msg = msg .. "\nFirst " .. #examples .. " examples:\n  " .. table.concat(examples, "\n  ")
		end
		
		return true, msg
	end,
})

-- Add command to check if a specific block is loaded or active
core.register_chatcommand("check_block", {
	params = "<x> <y> <z>",
	description = "Check if a block at given position is loaded and/or active",
	func = function(name, param)
		local x, y, z = param:match("^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		if not x then
			return false, "Invalid coordinates. Usage: /check_block <x> <y> <z>"
		end
		
		local blockpos = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
		local hash = core.hash_node_position(blockpos)
		
		local is_loaded = core.loaded_blocks[hash] ~= nil
		local is_active = core.active_blocks[hash] ~= nil
		
		local msg = "Block at " .. core.pos_to_string(blockpos) .. ":\n"
		msg = msg .. "  Loaded: " .. tostring(is_loaded) .. "\n"
		msg = msg .. "  Active: " .. tostring(is_active)
		
		return true, msg
	end,
})

print_to_everything("Test mod loaded successfully!")
