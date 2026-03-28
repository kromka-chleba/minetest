local builtin_shared = ...
local debug_getinfo = debug.getinfo

do
	local default = {mod = "??", name = "??"}
	core.callback_origins = setmetatable({}, {
		__index = function()
			return default
		end
	})
end

function core.run_callbacks(callbacks, mode, ...)
	assert(type(callbacks) == "table")
	local cb_len = #callbacks
	if cb_len == 0 then
		if mode == 2 or mode == 3 then
			return true
		elseif mode == 4 or mode == 5 then
			return false
		end
	end
	local ret = nil
	for i = 1, cb_len do
		local origin = core.callback_origins[callbacks[i]]
		core.set_last_run_mod(origin.mod)
		local cb_ret = callbacks[i](...)

		if mode == 0 and i == 1 then
			ret = cb_ret
		elseif mode == 1 and i == cb_len then
			ret = cb_ret
		elseif mode == 2 then
			if not cb_ret or i == 1 then
				ret = cb_ret
			end
		elseif mode == 3 then
			if cb_ret then
				return cb_ret
			end
			ret = cb_ret
		elseif mode == 4 then
			if (cb_ret and not ret) or i == 1 then
				ret = cb_ret
			end
		elseif mode == 5 and cb_ret then
			return cb_ret
		end
	end
	return ret
end

function builtin_shared.make_registration()
	local t = {}
	local registerfunc = function(func)
		t[#t + 1] = func
		core.callback_origins[func] = {
			-- may be nil or return nil
			mod = core.get_current_modname and core.get_current_modname() or "??",
			name = debug_getinfo(1, "n").name or "??"
		}
	end
	return t, registerfunc
end

function builtin_shared.make_registration_reverse()
	local t = {}
	local registerfunc = function(func)
		table.insert(t, 1, func)
		core.callback_origins[func] = {
			-- may be nil or return nil
			mod = core.get_current_modname and core.get_current_modname() or "??",
			name = debug_getinfo(1, "n").name or "??"
		}
	end
	return t, registerfunc
end

function builtin_shared.setup_mapgen_stage_registration()
	if core.register_mapgen_stage then
		return
	end

	core.registered_mapgen_stages = core.registered_mapgen_stages or {}
	core.registered_on_mapgen_stages = core.registered_on_mapgen_stages or {}

	local function validate_stage_number(stage)
		stage = tonumber(stage)
		if not stage then
			error("register_mapgen_stage: stage must be a number")
		end
		if stage < 1 or stage > 254 then
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
			error("register_mapgen_stage: def.func or def.callback is required and must be a function")
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
			mod = core.get_current_modname and core.get_current_modname() or "??",
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
			mod = core.get_current_modname and core.get_current_modname() or "??",
			name = "on_mapgen_stage " .. stage,
		}
	end
end
