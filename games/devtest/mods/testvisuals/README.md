# testvisuals

Test mod for the `player:set_node_visual()` API using mapgen nodes.

## Description

This mod provides chat commands to test various features of the `player:set_node_visual()` API, which allows dynamic modification of node textures and visual properties at runtime.

**This mod uses actual mapgen nodes** (nodes that are used in world generation), so the effects are immediately visible in the terrain when you run the commands!

## Tested Mapgen Nodes

- **mapgen_stone** - The primary terrain/underground stone
- **mapgen_dirt_with_grass** - Surface layer with grass
- **mapgen_sand** - Beach and riverbed material
- **mapgen_cobble** - Dungeon walls

## Chat Commands

All commands start with `test_visual_`:

- **test_visual_simple** - Test with simple texture strings (backward compatible)
- **test_visual_color** - Test color tinting on different faces (rainbow effect)
- **test_visual_aligned** - Test world-aligned textures with scale parameter
- **test_visual_animated** - Test animated texture definitions
- **test_visual_culling** - Test backface culling disabled
- **test_visual_mixed** - Test mixed tile formats (simple strings + full definitions)
- **test_visual_multiface** - Test different textures on each face
- **test_visual_multi** - Test applying changes to multiple mapgen node types
- **test_visual_reset** - Reset mapgen node visuals to default textures
- **test_visual_help** - Show help message with all commands

## Usage

1. Start a new world with the devtest game
2. The world will generate with mapgen nodes (stone, grass, sand, etc.)
3. Run one of the test commands (e.g., `/test_visual_color`)
4. Watch the entire terrain change appearance!
5. Use `/test_visual_reset` to restore default appearances

## Notes

- All changes are global and affect all players on the server
- Changes persist until server restart
- The mod depends on the `basenodes` mod (via mapgen aliases)
- Each test demonstrates different features of the tile definition format
- **Effects are immediately visible in the generated terrain!**

## Tested Features

- ✅ Simple texture strings (backward compatible)
- ✅ Full tile definition tables
- ✅ Color tinting/multiplication
- ✅ World-aligned textures with scale
- ✅ Animation definitions
- ✅ Backface culling control
- ✅ Mixed formats (strings + tables in same call)
- ✅ Multiple textures per node (different face textures)
- ✅ Multiple node types simultaneously
