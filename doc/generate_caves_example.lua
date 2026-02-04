-- Example: Using core.generate_caves() with cavern parameters
-- This example demonstrates how to control all cave types including caverns

-- Example 1: Disable all caves (including caverns)
minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    
    -- Generate biomes first (required for cave generation)
    minetest.generate_biomes(vm)
    
    -- Disable all cave types
    minetest.generate_caves(vm, minp, maxp, {
        -- Disable noise-based tunnels
        cave_width = 10,
        
        -- Disable small randomwalk caves
        small_cave_num_min = 0,
        small_cave_num_max = 0,
        
        -- Disable large randomwalk caves
        large_cave_num_min = 0,
        large_cave_num_max = 0,
        
        -- Disable caverns by setting limit very high
        cavern_limit = 31000
    })
    
    vm:write_to_map()
end)

-- Example 2: Enable only caverns (no other caves)
minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    
    minetest.generate_biomes(vm)
    
    -- Enable only caverns
    minetest.generate_caves(vm, minp, maxp, {
        -- Disable other cave types
        cave_width = 10,
        small_cave_num_min = 0,
        small_cave_num_max = 0,
        large_cave_num_min = 0,
        large_cave_num_max = 0,
        
        -- Enable caverns below Y=-256
        cavern_limit = -256,
        cavern_taper = 256,
        cavern_threshold = 0.7
    })
    
    vm:write_to_map()
end)

-- Example 3: Customize cavern generation
minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    
    minetest.generate_biomes(vm)
    
    -- Generate larger, more frequent caverns
    minetest.generate_caves(vm, minp, maxp, {
        -- Keep narrow tunnels
        cave_width = 4,
        
        -- Enable large caves
        large_cave_num_min = 0,
        large_cave_num_max = 2,
        large_cave_depth = -33,
        
        -- Customize caverns
        cavern_limit = -100,       -- Caverns start at Y=-100
        cavern_taper = 200,        -- Taper zone is 200 nodes
        cavern_threshold = 0.6,    -- Lower threshold = more caverns
        np_cavern = {
            offset = 0,
            scale = 1,
            spread = {x = 300, y = 100, z = 300},  -- Tighter spacing
            seed = 723,
            octaves = 5,
            persistence = 0.63,
            lacunarity = 2.0
        }
    })
    
    vm:write_to_map()
end)

-- Example 4: Apply the original issue's requirements
-- Create narrow tunnels only, no large caves or caverns
minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    
    minetest.generate_biomes(vm)
    
    -- Very narrow tunnels: 4 nodes wide, no caverns
    minetest.generate_caves(vm, minp, maxp, {
        -- Very narrow tunnels: 4 nodes wide
        cave_width = 4,
        
        -- Standard depth for large caves (but disabled)
        large_cave_depth = -33,
        
        -- Limit small caves to deeper areas (y <= -10)
        small_cave_depth = -10,
        
        -- Disable small caves
        small_cave_num_min = 0,
        small_cave_num_max = 0,
        
        -- Disable large caves
        large_cave_num_min = 0,
        large_cave_num_max = 0,
        
        -- NEW: Disable caverns (this was the missing parameter!)
        cavern_limit = 31000  -- Set very high to disable
    })
    
    vm:write_to_map()
end)
