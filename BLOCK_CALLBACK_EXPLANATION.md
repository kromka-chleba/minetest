# Block Callback Timing and Overgeneration Issues

## The Question

Why does `register_on_block_loaded` work correctly without overgeneration issues, but `register_on_block_activated` has problems where outdated blocks are written?

## The Answer

### on_block_loaded Timing

`on_block_loaded` is called:
1. **During chunk generation** in the emerge thread
2. **AFTER** `finishBlockMake()` → `blitBackAll()` completes
3. **ONLY for CORE blocks** (bpmin to bpmax, not border blocks)
4. **ONCE per block** when first generated/loaded

See `src/emerge.cpp` lines 759-780:
```cpp
// Call on_block_loaded callback after chunk emerges but before activation
// This allows voxel manipulator to run after all mapgen liquid transforms
// and lighting calculations are complete
if (block && !error) {
    ...
    // Iterate Y first for better cache locality
    for (s16 y = bpmin.Y; y <= bpmax.Y; y++)
    for (s16 z = bpmin.Z; z <= bpmax.Z; z++)
    for (s16 x = bpmin.X; x <= bpmax.X; x++) {
        v3s16 bp(x, y, z);
        // Only call callback if block actually exists
        MapBlock *gen_block = m_map->getBlockNoCreateNoEx(bp);
        if (gen_block)
            script->on_block_loaded(bp);
    }
}
```

### on_block_activated Timing

`on_block_activated` is called:
1. **When blocks enter the active area** (near players)
2. **In the server thread** (not during generation)
3. **For ANY block** that becomes active (could be core or border blocks)
4. **Multiple times** as blocks activate/deactivate

See `src/serverenvironment.cpp` lines 548-592 (activateBlock function).

### Why on_block_loaded Seems to Work Better

**Key Insight**: `on_block_loaded` is only called for **CORE blocks**, never for border blocks.

- Core blocks are in the range [bpmin, bpmax]
- Border blocks are in [bpmin - EMERGE_EXTRA_BORDER, bpmax + EMERGE_EXTRA_BORDER]
- Only core blocks are marked as `generated` (see `servermap.cpp` line 352)
- Border blocks remain "not generated" until their own chunk is generated

When a neighboring chunk generates:
- It includes border blocks from the previous chunk
- These border blocks are loaded via `emergeBlock()` 
- `blitBackAll()` writes the new chunk's voxel data to ALL blocks including borders
- **This can overwrite modifications made to core blocks from the previous chunk!**

However, the impact is limited because:
1. Only blocks within EMERGE_EXTRA_BORDER distance (1 block) from chunk boundaries are affected
2. Most modifications in `on_block_loaded` are to blocks in the center of chunks
3. The visual effect might not be noticeable if modifications are sparse

### Why on_block_activated Has More Visible Issues

`on_block_activated` is called for ALL active blocks, including:
- Blocks that are border blocks for neighboring chunks
- Blocks that haven't been generated yet
- Blocks that will be overwritten when neighboring chunks generate

This makes the overgeneration issue more visible because:
1. Players often modify blocks near chunk boundaries
2. The activation area is larger than the generation area
3. Multiple chunks can be activated simultaneously

## The Solution

### Option 1: Use on_generated Instead (Recommended)

The `on_generated` callback runs DURING chunk generation, so modifications are part of the generation itself:

```lua
core.register_on_generated(function(minp, maxp, blockseed)
    local vm = core.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local data = vm:get_data()
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    
    -- Make modifications to data
    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do
                local vi = area:index(x, y, z)
                -- Modify data[vi]
            end
        end
    end
    
    vm:set_data(data)
    vm:write_to_map()
end)
```

### Option 2: Only Modify Non-Border Blocks

If you must use `on_block_activated` or `on_block_loaded`, avoid modifying blocks near chunk boundaries:

```lua
local mapblock_size = 16
local chunksize = 5  -- blocks per chunk (default)
local border_distance = 1  -- EMERGE_EXTRA_BORDER

core.register_on_block_activated(function(blockpos)
    -- Check if this is a border block for any neighboring chunk
    local is_border_block = false
    for axis_name, axis_coord in pairs(blockpos) do
        if axis_coord % chunksize == 0 or 
           axis_coord % chunksize == (chunksize - 1) then
            is_border_block = true
            break
        end
    end
    
    if is_border_block then
        -- Skip or be careful with modifications
        return
    end
    
    -- Safe to modify this block
    local vm = core.get_voxel_manip()
    -- ... make modifications ...
end)
```

### Option 3: Accept the Limitation

Document that modifications to blocks near chunk boundaries may be overwritten by subsequent chunk generation. This is a fundamental limitation of chunk-based world generation.

## Conclusion

The real difference between `on_block_loaded` and `on_block_activated` is:
- **Scope**: on_block_loaded only affects core blocks; on_block_activated affects all active blocks
- **Frequency**: on_block_loaded is called once; on_block_activated can be called multiple times
- **Timing**: on_block_loaded is during generation; on_block_activated is during gameplay

Both can have overgeneration issues, but the issue is more visible and frequent with `on_block_activated` because it affects more blocks and is called more often.

The recommended solution is to use `on_generated` for mapgen-related modifications, as these are guaranteed to be part of the generation and won't be overwritten.
