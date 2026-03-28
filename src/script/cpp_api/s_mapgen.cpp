// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2022 sfan5 <sfan5@live.de>

#include "cpp_api/s_mapgen.h"
#include "cpp_api/s_internal.h"
#include "common/c_converter.h"
#include "lua_api/l_vmanip.h"
#include "emerge.h"

void ScriptApiMapgen::on_mods_loaded()
{
	SCRIPTAPI_PRECHECKHEADER

	// Get registered shutdown hooks
	lua_getglobal(L, "core");
	lua_getfield(L, -1, "registered_on_mods_loaded");
	// Call callbacks
	runCallbacks(0, RUN_CALLBACKS_MODE_FIRST);
}

void ScriptApiMapgen::on_shutdown()
{
	SCRIPTAPI_PRECHECKHEADER

	// Get registered shutdown hooks
	lua_getglobal(L, "core");
	lua_getfield(L, -1, "registered_on_shutdown");
	// Call callbacks
	runCallbacks(0, RUN_CALLBACKS_MODE_FIRST);
}

void ScriptApiMapgen::on_generated(BlockMakeData *bmdata, u32 seed)
{
	SCRIPTAPI_PRECHECKHEADER

	v3s16 minp = bmdata->blockpos_min * MAP_BLOCKSIZE;
	v3s16 maxp = bmdata->blockpos_max * MAP_BLOCKSIZE +
				 v3s16(1,1,1) * (MAP_BLOCKSIZE - 1);

	LuaVoxelManip::create(L, bmdata->vmanip, true);
	const int vmanip = lua_gettop(L);

	// Store vmanip globally (used by helpers)
	lua_getglobal(L, "core");
	lua_pushvalue(L, vmanip);
	lua_setfield(L, -2, "vmanip");

	// Call callbacks
	lua_getfield(L, -1, "registered_on_generateds");
	lua_pushvalue(L, vmanip);
	push_v3s16(L, minp);
	push_v3s16(L, maxp);
	lua_pushnumber(L, seed);
	runCallbacks(4, RUN_CALLBACKS_MODE_FIRST);
	lua_pop(L, 1); // return val

	// Unset core.vmanip again
	lua_pushnil(L);
	lua_setfield(L, -2, "vmanip");
}

void ScriptApiMapgen::on_mapgen_stage(BlockMakeData *bmdata, u32 seed, u8 stage)
{
	SCRIPTAPI_PRECHECKHEADER

	v3s16 minp = bmdata->blockpos_min * MAP_BLOCKSIZE;
	v3s16 maxp = bmdata->blockpos_max * MAP_BLOCKSIZE +
				 v3s16(1,1,1) * (MAP_BLOCKSIZE - 1);

	LuaVoxelManip::create(L, bmdata->vmanip, true);
	const int vmanip = lua_gettop(L);

	lua_getglobal(L, "core");
	if (!lua_istable(L, -1))
		throw LuaError("global 'core' missing in mapgen environment");
	const int core_idx = lua_gettop(L);
	lua_pushvalue(L, vmanip);
	lua_setfield(L, core_idx, "vmanip");

	auto call_stage_list = [&](const char *field) {
		lua_getfield(L, -1, field); // stage -> list
		if (!lua_istable(L, -1)) {
			lua_pop(L, 1);
			return;
		}

		lua_pushinteger(L, stage);
		lua_gettable(L, -2); // list for this stage
		if (lua_istable(L, -1)) {
			lua_pushvalue(L, vmanip);
			push_v3s16(L, minp);
			push_v3s16(L, maxp);
			lua_pushnumber(L, seed);
			lua_pushinteger(L, stage);
			runCallbacks(5, RUN_CALLBACKS_MODE_FIRST);
			lua_pop(L, 1); // pop return value
		} else {
			lua_pop(L, 1);
		}
		lua_pop(L, 2); // pop stage-specific list (or nil) and the registered_* map
	};

	call_stage_list("registered_mapgen_stages");
	call_stage_list("registered_on_mapgen_stages");

	lua_pushnil(L);
	lua_setfield(L, core_idx, "vmanip");
	lua_pop(L, 2); // pop vmanip and core
}
