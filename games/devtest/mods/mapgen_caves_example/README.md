# Cave Generation Example Mod

This mod demonstrates how to use `core.generate_caves()` with custom parameters
introduced in the Luanti/Minetest Lua API.

## Purpose

The `core.generate_caves()` function can now accept an optional `params` table
as its 4th argument, allowing you to override the default cave generation
parameters. This is particularly useful for:

- Custom mapgens without built-in cave parameters (e.g., singlenode)
- Creating unique cave systems with specific characteristics
- Fine-tuning cave generation for different biomes or depth levels

## Parameters

The `params` table supports the following fields:

### Noise-Based Cave Parameters

- **`np_cave1`**: NoiseParams table for the first 3D noise pattern defining tunnels
  - Controls the shape and distribution of cave tunnels
  
- **`np_cave2`**: NoiseParams table for the second 3D noise pattern
  - Intersects with np_cave1 to create the final cave system
  
- **`cave_width`**: Float value controlling tunnel width
  - Smaller values create wider tunnels
  - Value >= 10.0 disables noise-based caves entirely
  - Default: 0.09

### Randomwalk Cave Parameters

- **`small_cave_num_min`**: Minimum number of small caves per mapchunk
  - Default: 0
  
- **`small_cave_num_max`**: Maximum number of small caves per mapchunk
  - Default: 0
  
- **`large_cave_num_min`**: Minimum number of large caves per mapchunk
  - Default: 0
  
- **`large_cave_num_max`**: Maximum number of large caves per mapchunk
  - Default: 2
  
- **`large_cave_depth`**: Y coordinate of upper limit for large caves
  - Large caves only generate below this Y level
  - Default: -33
  
- **`large_cave_flooded`**: Proportion of large caves containing liquid
  - Float value between 0.0 and 1.0
  - Determines probability of water/lava in large caves
  - Default: 0.5

## Examples Included

This mod includes several example functions demonstrating different use cases:

1. **Custom Noise Caves**: Modified noise parameters for varied cave tunnels
2. **Small Caves Only**: Disables noise caves, uses only small randomwalk caves
3. **Flooded Caves**: Generates mostly water/lava-filled caves
4. **Narrow Caves**: Creates tight, narrow cave networks

## Usage

To use this mod:

1. Copy to your game's mods directory
2. Enable it in your world
3. Start a new world or explore new chunks

For your own mods, you can use any of the example functions as a starting point
and customize the parameters to fit your needs.

## Important Notes

- `core.generate_biomes()` must be called **before** `core.generate_caves()`
  because cave generation needs the biomemap for biome-aware liquid placement
  
- The params table is optional - if omitted, the function uses the current
  mapgen's cave parameters or sensible defaults
  
- You can override only specific parameters; unspecified ones use defaults
  
- Parameters apply per-mapchunk, not globally

## See Also

- Lua API documentation: `doc/lua_api.md`
- Mapgen API section: Search for "core.generate_caves"
