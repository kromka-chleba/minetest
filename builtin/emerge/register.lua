local builtin_shared = ...

-- Copy all the registration tables over
do
	local all = assert(core.transferred_globals)
	core.transferred_globals = nil

	all.registered_nodes = {}
	all.registered_craftitems = {}
	all.registered_tools = {}
	for k, v in pairs(all.registered_items) do
		-- Ignore new keys
		setmetatable(v, {__newindex = function() end})
		-- Reassemble the other tables
		if v.type == "node" then
			getmetatable(v).__index = all.nodedef_default
			all.registered_nodes[k] = v
		elseif v.type == "craft" then
			getmetatable(v).__index = all.craftitemdef_default
			all.registered_craftitems[k] = v
		elseif v.type == "tool" then
			getmetatable(v).__index = all.tooldef_default
			all.registered_tools[k] = v
		else
			getmetatable(v).__index = all.noneitemdef_default
		end
	end

	for k, v in pairs(all) do
		core[k] = v
	end
end

-- For tables that are indexed by item name:
-- If table[X] does not exist, default to table[core.registered_aliases[X]]
local alias_metatable = {
	__index = function(t, name)
		return rawget(t, core.registered_aliases[name])
	end,
	__newindex = function()
		error("table is read-only")
	end
}
setmetatable(core.registered_items, alias_metatable)
setmetatable(core.registered_nodes, alias_metatable)
setmetatable(core.registered_craftitems, alias_metatable)
setmetatable(core.registered_tools, alias_metatable)

--
-- Callbacks
--

local make_registration = builtin_shared.make_registration

core.registered_on_mods_loaded, core.register_on_mods_loaded = make_registration()
core.registered_on_generateds, core.register_on_generated = make_registration()
core.registered_on_shutdown, core.register_on_shutdown = make_registration()

--
-- Mapgen stage registrations
--
core.registered_mapgen_stages = {}
core.registered_on_mapgen_stages = {}

local function validate_stage_number(stage)
	stage = tonumber(stage)
	if not stage then
		error("register_mapgen_stage: stage must be a number")
	end
	if stage <= 0 or stage >= 255 then
		error("register_mapgen_stage: stage must be in range 1..254")
	end
	return stage
end

function core.register_mapgen_stage(def)
	if type(def) ~= "table" then
		error("register_mapgen_stage: table expected")
	end

	local stage = validate_stage_number(def.stage)
	local func = def.func or def.callback
	if type(func) ~= "function" then
		error("register_mapgen_stage: def.func is required and must be a function")
	end

	local entry = {
		stage = stage,
		name = def.name or tostring(stage),
		func = func,
	}
	local list = core.registered_mapgen_stages[stage]
	if not list then
		list = {}
		core.registered_mapgen_stages[stage] = list
	end
	list[#list + 1] = entry
	core.callback_origins[func] = {
		mod = core.get_current_modname() or "??",
		name = entry.name,
	}
end

function core.register_on_mapgen_stage(stage, func)
	stage = validate_stage_number(stage)
	if type(func) ~= "function" then
		error("register_on_mapgen_stage: function expected")
	end

	local list = core.registered_on_mapgen_stages[stage]
	if not list then
		list = {}
		core.registered_on_mapgen_stages[stage] = list
	end

	list[#list + 1] = func
	core.callback_origins[func] = {
		mod = core.get_current_modname() or "??",
		name = "on_mapgen_stage " .. stage,
	}
end
