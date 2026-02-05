# testvisuals

Test mod for the `player:set_node_visual()` API.

## Description

This mod provides chat commands to test various features of the `player:set_node_visual()` API, which allows dynamic modification of node textures and visual properties at runtime.

## Chat Commands

All commands start with `test_visual_`:

- **test_visual_simple** - Test with simple texture strings (backward compatible)
- **test_visual_color** - Test color tinting on different faces
- **test_visual_aligned** - Test world-aligned textures with scale parameter
- **test_visual_animated** - Test animated texture definitions
- **test_visual_culling** - Test backface culling disabled
- **test_visual_mixed** - Test mixed tile formats (simple strings + full definitions)
- **test_visual_multiface** - Test different textures on each face
- **test_visual_multi** - Test applying changes to multiple node types
- **test_visual_reset** - Reset node visuals to default textures
- **test_visual_help** - Show help message with all commands

## Usage

1. Place some stone, dirt, and cobble nodes in the world
2. Run one of the test commands (e.g., `/test_visual_color`)
3. Observe the visual changes on the placed nodes
4. Use `/test_visual_reset` to restore default appearances

## Notes

- All changes are global and affect all players on the server
- Changes persist until server restart
- The mod depends on the `basenodes` mod for testing
- Each test demonstrates different features of the tile definition format

## Tested Features

- ✅ Simple texture strings (backward compatible)
- ✅ Full tile definition tables
- ✅ Color tinting/multiplication
- ✅ World-aligned textures with scale
- ✅ Animation definitions
- ✅ Backface culling control
- ✅ Mixed formats (strings + tables in same call)
- ✅ Multiple textures per node (different face textures)
- ✅ Multiple node types
