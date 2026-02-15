# Add Lua API to retrieve mapblock data with node ID mappings

## Goal of the PR

Add a new Lua API function `core.get_mapblock_data(blockpos)` that allows mods to retrieve low-level mapblock metadata and, most importantly, the **node content ID to name mappings** for blocks. This enables mods to understand the actual node content IDs used within a mapblock, which is essential for analyzing map data at a low level.

## How does the PR work?

The PR implements a new server-side Lua API function that:

1. **Takes a mapblock position** (not node position) as input
2. **Loads the block from disk** if not already in memory, using the existing `ServerMap::loadBlock()` mechanism
3. **Extracts and returns mapblock metadata** in a Lua table:
   - `pos`: Block position (x, y, z in mapblock coordinates)
   - `node_mapping`: **Content ID → node name mapping** (the key feature)
   - `timestamp`: Game time when the block was last saved
   - `is_underground`: Underground flag for lighting
   - `generated`: Whether the block has been fully generated
   - `lighting_complete`: Lighting completion status flags
4. **Relies on automatic memory management** - blocks loaded by this function are managed by the game's periodic unloader (`Map::timerUpdate()`), which unloads inactive blocks after ~20 seconds

The node_mapping table is built by scanning all 4096 nodes in the block and collecting unique content IDs, then mapping them to their registered node names via the NodeDefManager.

## Does it resolve any reported issue?

This PR addresses the feature request to access mapblock data and node ID mappings for low-level map analysis and tools.

## If not a bug fix, why is this PR needed? What usecases does it solve?

### Primary Use Case: Node ID Mappings
The main purpose is to provide access to the **content ID to node name mappings** used within a specific mapblock. This is crucial for:

- **Map analysis tools** that need to understand which content IDs correspond to which node types
- **Map format documentation/verification** - understanding how blocks are stored
- **Debugging map-related issues** - inspecting actual block contents
- **Performance analysis** - understanding node distribution in blocks

### Additional Use Cases:
- **Block metadata inspection** - checking timestamps, generation status, lighting status
- **World exploration tools** - discovering which blocks exist and their properties
- **Custom map tools** - building external map viewers or analyzers
- **Education** - helping developers understand Luanti's map format

### Why Node ID Mappings Matter:
In Luanti's map format, nodes are stored using numeric content IDs (not names). These IDs can vary between worlds and are mapped through a name→ID table. This API exposes that mapping for each block, which is essential for anyone working with raw map data or trying to understand the low-level block storage.

## LLM/AI Disclosure

This feature was implemented with assistance from GitHub Copilot (AI code completion and suggestions).

## To do

This PR is **Ready for Review**.

- [x] Implement `core.get_mapblock_data()` function in l_env.cpp
- [x] Add block loading from disk functionality
- [x] Implement automatic memory management (removed manual unloading)
- [x] Extract node ID mappings from blocks
- [x] Add all relevant metadata fields (6 fields total)
- [x] Document the API in lua_api.md with examples
- [x] Create unit tests in devtest
- [x] Build and verify compilation
- [x] Test all functionality

## How to test

### Using devtest:

1. Start a server with the devtest game:
   ```bash
   ./bin/luantiserver --gameid devtest --world /path/to/testworld
   ```

2. Run the unit tests - they will automatically test `core.get_mapblock_data`:
   ```
   /test_mapblock_data
   ```

### Manual testing with a mod:

Create a test mod with this code in `init.lua`:

```lua
minetest.register_chatcommand("blockinfo", {
    params = "",
    description = "Get info about the block you're standing in",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local pos = player:get_pos()
        
        -- Convert node position to block position
        local blockpos = {
            x = math.floor(pos.x / 16),
            y = math.floor(pos.y / 16),
            z = math.floor(pos.z / 16)
        }
        
        local data = core.get_mapblock_data(blockpos)
        
        if not data then
            return true, "Block doesn't exist"
        end
        
        minetest.chat_send_player(name, "Block at " .. 
            blockpos.x .. "," .. blockpos.y .. "," .. blockpos.z)
        minetest.chat_send_player(name, "Timestamp: " .. data.timestamp)
        minetest.chat_send_player(name, "Generated: " .. tostring(data.generated))
        minetest.chat_send_player(name, "Underground: " .. tostring(data.is_underground))
        minetest.chat_send_player(name, string.format("Lighting: 0x%04x", data.lighting_complete))
        
        minetest.chat_send_player(name, "Node ID mappings in this block:")
        local count = 0
        for id, name in pairs(data.node_mapping) do
            minetest.chat_send_player(name, "  " .. id .. " -> " .. name)
            count = count + 1
            if count > 10 then
                minetest.chat_send_player(name, "  ... and more")
                break
            end
        end
        
        return true
    end,
})
```

Then in-game, use `/blockinfo` to see the mapblock data for your current position.

### Expected Results:

- The function should return `nil` for non-existent/ungenerated blocks
- For existing blocks, it should return a table with all 6 fields
- `node_mapping` should contain at least one entry (content ID → node name)
- The mappings should be accurate (placing a node and checking should show it)
- No memory leaks when calling the function repeatedly (blocks auto-unload)

### Example Output:

```
Block at 0,0,0
Timestamp: 12345
Generated: true
Underground: false
Lighting: 0x0fff
Node ID mappings in this block:
  0 -> air
  1 -> default:stone
  2 -> default:dirt
  3 -> default:grass
  ... and more
```

## Implementation Details

### Files Modified:
- `src/script/lua_api/l_env.cpp` - Core implementation (~85 lines)
- `src/script/lua_api/l_env.h` - Function declaration
- `doc/lua_api.md` - API documentation with examples
- `games/devtest/mods/unittests/mapblock_data.lua` - Unit tests
- `games/devtest/mods/unittests/init.lua` - Test registration

### Key Design Decisions:

1. **Automatic block loading**: Blocks are loaded from disk transparently if needed
2. **Automatic memory management**: No manual unloading - the game's periodic unloader handles it
3. **Efficient node mapping**: Uses `std::unordered_set` to track unique nodes, scanning the block once
4. **Map format alignment**: All fields correspond to data in the map file format specification
5. **Read-only access**: Function only reads data, never modifies blocks

### Performance Considerations:
- O(n) scan of block nodes (4096 nodes) to build mappings
- Minimal memory overhead (only stores unique content IDs)
- No blocking or heavy computation
- Safe for repeated calls due to automatic block management
