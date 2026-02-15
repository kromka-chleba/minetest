// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2026 Minetest core developers & community

#include "test.h"

#include "mock_server.h"
#include "server/luaentity_sao.h"
#include "serverenvironment.h"
#include "servermap.h"
#include "emerge.h"
#include "script/scripting_server.h"
#include "script/lua_api/l_env.h"

/*
 * Tests for core.get_mapblock_data() Lua API function
 */

class TestGetMapblockData : public TestBase
{
public:
	TestGetMapblockData() { TestManager::registerTestModule(this); }
	const char *getName() { return "TestGetMapblockData"; }

	void runTests(IGameDef *gamedef);

	void testGetMapblockDataNil(ServerEnvironment *env, ServerScripting *script);
	void testGetMapblockDataExists(ServerEnvironment *env, ServerScripting *script);
	void testGetMapblockDataFields(ServerEnvironment *env, ServerScripting *script);
};

static TestGetMapblockData g_test_instance;

void TestGetMapblockData::runTests(IGameDef *gamedef)
{
	MockServer server(getTestTempDirectory());

	// Create world.mt file
	{
		std::ofstream ofs(server.getWorldPath() + DIR_DELIM "world.mt",
			std::ios::out | std::ios::binary);
		ofs << "backend = dummy\n";
	}

	server.createScripting();
	ServerScripting *script = nullptr;
	try {
		script = server.getScriptIface();
		script->loadBuiltin();
	} catch (ModError &e) {
		rawstream << e.what() << std::endl;
		num_tests_failed = 1;
		return;
	}

	// Create ServerEnvironment with a map
	MetricsBackend mb;
	EmergeManager emerge(&server, &mb);
	auto map = std::make_unique<ServerMap>(server.getWorldPath(), gamedef, &emerge, &mb);
	ServerEnvironment env(std::move(map), &server, &mb);
	env.loadMeta();

	TEST(testGetMapblockDataNil, &env, script);
	TEST(testGetMapblockDataExists, &env, script);
	TEST(testGetMapblockDataFields, &env, script);

	env.deactivateBlocksAndObjects();
}

void TestGetMapblockData::testGetMapblockDataNil(ServerEnvironment *env, ServerScripting *script)
{
	lua_State *L = script->getStack();
	
	// Test that get_mapblock_data returns nil for non-existent block
	const char *code = R"(
		local data = core.get_mapblock_data({x=1000, y=1000, z=1000})
		return data
	)";
	
	if (luaL_loadstring(L, code) != 0) {
		rawstream << "Failed to load Lua code: " << lua_tostring(L, -1) << std::endl;
		UASSERT(false);
	}
	
	if (lua_pcall(L, 0, 1, 0) != 0) {
		rawstream << "Lua error: " << lua_tostring(L, -1) << std::endl;
		UASSERT(false);
	}
	
	// Should return nil for non-existent block
	UASSERT(lua_isnil(L, -1));
	lua_pop(L, 1);
}

void TestGetMapblockData::testGetMapblockDataExists(ServerEnvironment *env, ServerScripting *script)
{
	lua_State *L = script->getStack();
	Map &map = env->getMap();
	
	// Create a mapblock at position (0, 0, 0)
	v3s16 blockpos(0, 0, 0);
	MapBlock *block = map.emergeBlock(blockpos, true);
	UASSERT(block != nullptr);
	
	// Set some nodes in the block
	block->setNode(v3s16(0, 0, 0), MapNode(CONTENT_AIR));
	block->setNode(v3s16(1, 1, 1), MapNode(t_CONTENT_STONE));
	
	// Test that get_mapblock_data returns a table for existing block
	const char *code = R"(
		local data = core.get_mapblock_data({x=0, y=0, z=0})
		return data ~= nil
	)";
	
	if (luaL_loadstring(L, code) != 0) {
		rawstream << "Failed to load Lua code: " << lua_tostring(L, -1) << std::endl;
		UASSERT(false);
	}
	
	if (lua_pcall(L, 0, 1, 0) != 0) {
		rawstream << "Lua error: " << lua_tostring(L, -1) << std::endl;
		UASSERT(false);
	}
	
	// Should return true (data is not nil)
	UASSERT(lua_toboolean(L, -1));
	lua_pop(L, 1);
}

void TestGetMapblockData::testGetMapblockDataFields(ServerEnvironment *env, ServerScripting *script)
{
	lua_State *L = script->getStack();
	Map &map = env->getMap();
	
	// Create a mapblock at position (0, 0, 0) if not already created
	v3s16 blockpos(0, 0, 0);
	MapBlock *block = map.emergeBlock(blockpos, true);
	UASSERT(block != nullptr);
	
	// Set some nodes in the block
	block->setNode(v3s16(0, 0, 0), MapNode(CONTENT_AIR));
	block->setNode(v3s16(1, 1, 1), MapNode(t_CONTENT_STONE));
	
	// Test that returned table has all expected fields
	const char *code = R"(
		local data = core.get_mapblock_data({x=0, y=0, z=0})
		if data == nil then
			return false, "data is nil"
		end
		if data.pos == nil then
			return false, "pos is nil"
		end
		if data.node_mapping == nil then
			return false, "node_mapping is nil"
		end
		if data.timestamp == nil then
			return false, "timestamp is nil"
		end
		if data.is_underground == nil then
			return false, "is_underground is nil"
		end
		-- Check that node_mapping is a table
		if type(data.node_mapping) ~= "table" then
			return false, "node_mapping is not a table"
		end
		-- Check that pos matches
		if data.pos.x ~= 0 or data.pos.y ~= 0 or data.pos.z ~= 0 then
			return false, "pos mismatch"
		end
		return true, "all fields present"
	)";
	
	if (luaL_loadstring(L, code) != 0) {
		rawstream << "Failed to load Lua code: " << lua_tostring(L, -1) << std::endl;
		UASSERT(false);
	}
	
	if (lua_pcall(L, 0, 2, 0) != 0) {
		rawstream << "Lua error: " << lua_tostring(L, -1) << std::endl;
		UASSERT(false);
	}
	
	// Check result
	bool success = lua_toboolean(L, -2);
	if (!success) {
		const char *msg = lua_tostring(L, -1);
		rawstream << "Test failed: " << (msg ? msg : "unknown") << std::endl;
	}
	UASSERT(success);
	lua_pop(L, 2);
}
