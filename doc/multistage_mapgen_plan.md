# Multi-Stage Mapgen — Implementation Plan

## 1. Problem Statement

The current map generator runs as a single monolithic pass over each chunk
(plus a 1-block overgeneration border). This design has several known issues:

- **Boundary glitches at y=47** (and similar seams at every chunk boundary) —
  because the border blocks are written but not marked generated, a later
  chunk generation pass can overwrite their content.
- **Cut-off trees / missing dust / broken schematics at chunk boundaries** —
  decorations and schematics that span chunk borders are placed during the
  central-chunk pass using border-block terrain that will later be
  overwritten, so the decoration ends up half-truncated.
- **Bush schematics** — `node_top` cannot be correctly placed under leaves
  that hang into an adjacent, unfinished chunk.
- **Dust (snow)** — requires knowing the final top surface node, which is
  only determined once decorations on neighbouring chunks are complete.

Tracked issues: #9357, #15643, #2519, #7392.

**Root cause:** a single-stage generator cannot satisfy the dependency
"decorations need finished terrain on all neighbours" within one pass.

---

## 2. Proposed Design

### 2.1 Generation Stage Numbering

Stages are unsigned 8-bit integers. The reserved default pipeline is:

| Stage | Name | Description |
|------:|------|-------------|
| 0 | `STAGE_NONE` | Not yet started (initial state) |
| 16 | `STAGE_TERRAIN` | Terrain skeleton from noise (solid, water, lava fill) |
| 32 | `STAGE_CAVES` | Cave and dungeon carving |
| 48 | `STAGE_ORES` | Ore placement |
| 64 | `STAGE_DECORATIONS` | Decorations (trees, plants, schematics) |
| 96 | `STAGE_DUST` | Dust/snow overlay (requires completed neighbours at DECORATIONS) |
| 239 | `STAGE_LIGHTING` | Final light propagation |
| 255 | `STAGE_COMPLETE` | All stages done; equivalent to current `m_generated = true` |

Stages between the reserved values are available to mods (see §2.4).  
Missing stages in the default pipeline are simply skipped.

### 2.2 Neighbourhood Requirement

- **Stage 16 (TERRAIN):** Generates a single chunk in isolation (same as
  today). No neighbourhood requirement.
- **Every subsequent stage N:** Requires that all 8 horizontal neighbours
  (3×3 chunk area) have completed stage N−1 before stage N can run on the
  centre chunk. If any neighbour has not reached the required predecessor
  stage, the centre chunk is re-queued until they do.

> **Why 3×3?**  Decorations (trees, schematics) can extend at most one chunk
> in any horizontal direction. Dust only needs to know the surface top node,
> which is stable after decorations are complete.  Vertical dependency is not
> needed in practice: the relevant surface is always inside the centre column.

### 2.3 Replacing `m_generated` with `m_generation_stage`

`MapBlock::m_generated` (bool, 1 bit) is replaced by
`MapBlock::m_generation_stage` (u8).  Backward compatibility:

- Old serialized `flags & 0x08 == 0` (block was generated) → load as
  `m_generation_stage = STAGE_COMPLETE`.
- Old `flags & 0x08 != 0` (block was not generated / border block) → load
  as `m_generation_stage = STAGE_NONE`.
- A new serialization format version (30) stores `m_generation_stage`
  as a u8 in the flags area; the 0x08 bit is repurposed.

For the emerge layer, "has stage S completed?" means
`block->m_generation_stage >= S`.

### 2.4 Lua-Defined Custom Stages

Mods may register custom stages:

```lua
-- Register a new stage with number between 33 and 63 (between caves and decorations).
-- handler receives the same vmanip/environment as on_generated.
minetest.register_mapgen_stage({
    stage = 20,
    name  = "mymod:buildings",
    func  = function(vm, minp, maxp, blockseed) ... end,
})
```

Constraints:

- Stage numbers 0–255 (u8); reserved values listed in §2.1 may be
  overridden only for stage 16 (terrain) and onwards (mods cannot
  remove or renumber the lighting stage 239).
- Adding a custom stage at number N means every chunk needs its neighbours
  to have reached N−1 before N can run. Each additional stage adds one
  round-trip through the emerge queue per chunk. Mods are encouraged to
  batch related work into a single stage.
- Stages are registered during mod loading (before world load).
  The sorted list of active stage numbers is frozen at world start and
  written to `world.mt` so it can be validated on re-open.

---

## 3. Data Model Changes

### 3.1 `MapBlock` (`src/mapblock.h / .cpp`)

```diff
-bool m_generated = false;
+u8 m_generation_stage = 0;  // 0 = STAGE_NONE, 255 = STAGE_COMPLETE

// Compatibility helpers:
+bool isGenerated() const { return m_generation_stage >= STAGE_COMPLETE; }
+void setGenerated(bool generated) {
+    m_generation_stage = generated ? STAGE_COMPLETE : STAGE_NONE;
+}
+bool hasCompletedStage(u8 stage) const {
+    return m_generation_stage >= stage;
+}
```

**Serialization (new format version 30):**

```
Byte offset  Field
0            flags (u8)
               bit 0 — is_underground
               bit 1 — (reserved, was "is air")
               bit 2 — (reserved)
               bit 3 — (reserved; was "not generated" — now always 0 in v30)
               bits 4-7 — (reserved)
1            generation_stage (u8)  ← NEW in v30
2-3          lighting_complete (u16)
...          (unchanged)
```

When reading version < 30: reconstruct `m_generation_stage` from the old
0x08 flag as described in §2.3.

### 3.2 `BlockMakeData` (`src/emerge.h`)

```diff
 struct BlockMakeData {
     MMVManip  *vmanip         = nullptr;
     u64        seed           = 0;
     v3s16      blockpos_min;
     v3s16      blockpos_max;
+    u8         target_stage   = 0;   // Stage we are asked to produce
+    u8         input_stage    = 0;   // Highest stage already complete in central blocks
     UniqueQueue<v3s16> transforming_liquid;
     const NodeDefManager *nodedef = nullptr;
 };
```

### 3.3 `BlockEmergeData` (`src/emerge.h`)

```diff
 struct BlockEmergeData {
     u16 peer_requested;
-    u16 flags;
+    u16 flags;             // BLOCK_EMERGE_ALLOW_GEN etc. unchanged
+    u8  required_stage;    // Minimum stage the requester needs
     EmergeCallbackList callbacks;
 };
```

### 3.4 `EmergeManager` (`src/emerge.h / .cpp`)

Add `required_stage` parameter throughout:

```cpp
bool enqueueBlockEmerge(
    session_t peer_id,
    v3s16     blockpos,
    bool      allow_generate,
    u8        required_stage = STAGE_COMPLETE,   // ← new
    bool      ignore_queue_limits = false);
```

Internal tracking: when merging a duplicate queue entry, take
`max(existing.required_stage, new.required_stage)`.

---

## 4. Emerge / Generation Pipeline Changes

### 4.1 Stage Resolution in `EmergeThread`

Replace the current `getBlockOrStartGen()` logic with a stage-aware version:

```
getBlockOrStartStage(pos, required_stage, flags, &block, &bmdata):

  block = map.getBlockNoCreateNoEx(pos)
  if block && block->m_generation_stage >= required_stage:
      return EMERGE_FROM_MEMORY   // already done

  if not block:
      block = try_load_from_disk(pos)

  if block && block->m_generation_stage >= required_stage:
      return EMERGE_FROM_DISK

  // Determine next stage to run
  next_stage = next_active_stage_after(block ? block->m_generation_stage : 0)
  if next_stage == 0 || next_stage > required_stage:
      return EMERGE_CANCELLED     // no generation permitted or nothing to do

  // For next_stage > STAGE_TERRAIN: check 3×3 neighbourhood
  if next_stage > STAGE_TERRAIN:
      predecessor = previous_active_stage(next_stage)
      for each (dx, dz) in 3×3 grid excluding centre:
          nb = map.getBlockContaining(pos + (dx*chunksize, 0, dz*chunksize))
          if nb == null || nb->m_generation_stage < predecessor:
              re_enqueue(pos, required_stage, delay=true)
              return EMERGE_DEFERRED   // new action code

  bmdata.target_stage = next_stage
  bmdata.input_stage  = block ? block->m_generation_stage : 0
  return EMERGE_GENERATING
```

New `EmergeAction` value:

```cpp
EMERGE_DEFERRED   // Re-queued; waiting for neighbours
```

### 4.2 `Mapgen::makeChunk()` Split into Stage Methods

The monolithic `makeChunk()` virtual method is supplemented (not replaced, to
retain backward compatibility for custom mapgens) by a new virtual:

```cpp
virtual void makeChunkStage(BlockMakeData *data, u8 stage);
```

Default implementation dispatches to the existing internal methods:

```cpp
void Mapgen::makeChunkStage(BlockMakeData *data, u8 stage) {
    switch (stage) {
    case STAGE_TERRAIN:
        // existing: terrain skeleton, biomes
        makeChunk(data);   // ← legacy call for custom mapgens
        return;
    case STAGE_CAVES:
        // generateCaves only, vmanip already loaded from disk
        generateCavesAndDungeons(data);
        return;
    case STAGE_ORES:
        generateOres(data);
        return;
    case STAGE_DECORATIONS:
        generateDecorations(data);
        return;
    case STAGE_DUST:
        generateDust(data);
        return;
    case STAGE_LIGHTING:
        calcLighting(...);
        return;
    }
}
```

For stage N > `STAGE_TERRAIN`, the VoxelManipulator must be pre-populated
from the stored node data of all blocks in the 3×3 neighbourhood
(a 3-chunk-wide horizontal slice) before `makeChunkStage()` is called.
`initBlockMake()` is extended to accept a `target_stage` and loads the
appropriate neighbourhood size.

### 4.3 `ServerMap::initBlockMake()` Changes

```diff
-bool initBlockMake(BlockMakeData *data, v3s16 blockpos);
+bool initBlockMake(BlockMakeData *data, v3s16 blockpos, u8 target_stage);
```

- If `target_stage == STAGE_TERRAIN`: behaviour identical to today
  (1 chunk + `EMERGE_EXTRA_BORDER` all round).
- If `target_stage > STAGE_TERRAIN`: load **3 chunks × 3 chunks** horizontal
  neighbourhood into the VoxelManipulator (full vertical extent for each
  column). The centre chunk's existing blocks are included so that stage N
  can read and modify terrain placed by stages 0…N-1.

### 4.4 `ServerMap::finishBlockMake()` Changes

- Blit only the **centre chunk** nodes back to disk after each stage.
- Advance `m_generation_stage` on each centre block to `target_stage`.
- Only set `MOD_STATE_WRITE_NEEDED` on centre blocks (neighbours were read-
  only for this stage and are unchanged).
- Lighting (`STAGE_LIGHTING`) continues to propagate into the full loaded area
  as today.

### 4.5 Re-queue Cascade

When stage N completes on chunk C, any of C's neighbours that are waiting
for C to finish stage N−1 (so they can run stage N themselves) should be
woken up. Mechanism:

1. After `finishBlockMake()`, emit a `STAGE_COMPLETE_EVENT(chunk_pos, stage)`.
2. `EmergeManager` listens and re-enqueues any `EMERGE_DEFERRED` entries
   for the 8 neighbours of `chunk_pos` that were blocked on this stage.

---

## 5. Lua API Changes

### 5.1 Stage Registration (new)

```lua
-- Register a custom generation stage.
-- stage:  integer 1–254 (cannot override 0 or 255)
-- name:   human-readable name for debugging
-- func:   called in EmergeThread context, same as on_generated
minetest.register_mapgen_stage({
    stage    = 20,
    name     = "mymod:buildings",
    func     = function(vm, minp, maxp, blockseed) ... end,
})
```

### 5.2 `on_generated` Retains Its Contract (unchanged)

`on_generated` is called after stage `STAGE_DECORATIONS` (64) completes,
preserving backward compatibility. Mods that relied on the combined
terrain+cave+ore+decoration pass will continue to work, since all four
stages now run before `on_generated` fires.

### 5.3 Per-Stage Callbacks (new)

```lua
minetest.register_on_mapgen_stage(stage, function(vm, minp, maxp, blockseed)
    -- Called after the named stage completes on the centre chunk.
    -- vm covers the centre chunk (not the wider neighbourhood).
end)
```

### 5.4 Querying Stage Progress (new)

```lua
-- Returns the generation stage of the block containing pos.
-- 0 = not started, 255 = fully complete.
minetest.get_mapgen_stage(pos)  --> integer

-- Returns true if the chunk containing pos has completed at least stage.
minetest.chunk_has_stage(pos, stage)  --> bool
```

### 5.5 `minetest.emerge_area` Extended (backward-compatible)

```lua
-- New optional 'min_stage' parameter (default: STAGE_COMPLETE = 255)
minetest.emerge_area(pos1, pos2, callback, param, min_stage)
```

---

## 6. World Metadata (`world.mt`) Changes

Two new keys:

```
mapgen_stage_count = 6
mapgen_stages = 16,32,48,64,96,239
```

These are written at world creation / first mod-loaded stage registration.
On world open, the engine validates that the stored stage list matches the
current mod set; a mismatch triggers a warning (not an error) and the
world can still be opened.

---

## 7. Backward Compatibility

| Concern | Mitigation |
|---------|------------|
| Old worlds with format < 30 | Reconstruct `m_generation_stage` from 0x08 flag on first read; saved as v30 on next write |
| Custom `makeChunk()` implementations | Default `makeChunkStage(TERRAIN)` calls `makeChunk()` unchanged; other stages call the new split methods, which call `generateDecorations()` etc. directly |
| `minetest.register_on_generated` | Fired after `STAGE_DECORATIONS` as before |
| Mods calling `minetest.emerge_area` | Default `min_stage` = `STAGE_COMPLETE`; no change in behaviour |
| `block->isGenerated()` / `setGenerated()` callers | Compat shims forward to `m_generation_stage`; no compile break |

---

## 8. Phased Implementation Checklist

### Phase 1 — Data Layer (no behaviour change)

- [ ] Add `m_generation_stage` (u8) to `MapBlock`; add compat shims for
      `isGenerated()` / `setGenerated()`.
- [ ] Bump block serialization to format version 30; write/read
      `m_generation_stage`; read old 0x08 flag and convert.
- [ ] Add `target_stage` / `input_stage` to `BlockMakeData`.
- [ ] Add `required_stage` to `BlockEmergeData` and
      `enqueueBlockEmerge()` signature.
- [ ] Add `EMERGE_DEFERRED` to `EmergeAction` enum.
- [ ] Add `STAGE_*` constants to a new `src/mapgen/mapgen_stage.h`.
- [ ] Write and pass unit tests for serialization round-trips.

### Phase 2 — Split `makeChunk()` into Stage Methods

- [ ] Add `Mapgen::makeChunkStage(BlockMakeData*, u8)` virtual method.
- [ ] Move cave, ore, decoration, dust, lighting sub-passes into individual
      methods callable from `makeChunkStage()`.
- [ ] Default `makeChunkStage(TERRAIN)` calls existing `makeChunk()` to
      preserve custom-mapgen compatibility.
- [ ] All built-in mapgens (`v5`, `v6`, `v7`, `flat`, `carpathian`,
      `valleys`, `fractal`) route their sub-passes through the new stage
      dispatch.
- [ ] Verify existing generation tests still pass.

### Phase 3 — Stage-Aware `initBlockMake` / `finishBlockMake`

- [ ] Extend `initBlockMake()` to accept `target_stage`; load 3×3
      neighbourhood VoxelManipulator when stage > `STAGE_TERRAIN`.
- [ ] Extend `finishBlockMake()` to blit only centre chunk and advance
      `m_generation_stage` to `target_stage`.
- [ ] Add `STAGE_COMPLETE_EVENT` and neighbour re-queue in
      `EmergeManager`.

### Phase 4 — Stage-Aware Emerge Queue Logic

- [ ] Replace `getBlockOrStartGen()` with `getBlockOrStartStage()`.
- [ ] Add neighbourhood readiness check (3×3, predecessor stage).
- [ ] Handle `EMERGE_DEFERRED`: add deferred set per chunk in
      `EmergeManager`; re-enqueue on `STAGE_COMPLETE_EVENT`.
- [ ] Integrate deferred blocks into `EmergeThread::run()`.
- [ ] End-to-end integration test: generate a chunk with a tree decoration
      at the border; verify the tree is not cut off.

### Phase 5 — Lua API

- [ ] Implement `minetest.register_mapgen_stage({stage, name, func})`.
- [ ] Implement `minetest.register_on_mapgen_stage(stage, func)`.
- [ ] Implement `minetest.get_mapgen_stage(pos)` and
      `minetest.chunk_has_stage(pos, stage)`.
- [ ] Extend `minetest.emerge_area` with optional `min_stage` parameter.
- [ ] Call `on_generated` after `STAGE_DECORATIONS` (unchanged timing).
- [ ] Document all new API in `doc/lua_api.md`.

### Phase 6 — World Metadata and Validation

- [ ] Write stage list to `world.mt` on world creation / mod-load.
- [ ] Validate stored stage list on world open; emit warning on mismatch.
- [ ] Provide `minetest.get_active_mapgen_stages()` Lua function for
      debugging.

### Phase 7 — Testing and Polish

- [ ] Add `minetest.place_schematic` / bush-schematic boundary test (3×3
      leaf cube) and verify `node_top` placement.
- [ ] Verify dust/snow appears correctly at chunk borders.
- [ ] Benchmark emerge queue throughput (deferred re-queue overhead should
      be < 5 % on a flat, unmodded world).
- [ ] Update `doc/mapgen_internals.md` with the multi-stage design.
- [ ] Release notes and migration guide for modders.

---

## 9. Performance Considerations

| Concern | Analysis |
|---------|----------|
| More emerge queue entries per chunk | Each chunk now passes through up to 6 (or more with mods) emerge events instead of 1. Queue depth grows proportionally. Mitigated by: deferred entries do not consume EmergeThread time; they only consume queue memory until neighbours are ready. |
| 3×3 VoxelManipulator load for later stages | Loading 9 chunks of node data per stage N > TERRAIN. For a 5-chunk-side mapchunk (default), that is 9×5³ = 1125 blocks. With compression, tolerable. Only the centre chunk is written back. |
| Neighbour polling / deferred wakeup | Avoid polling: use the `STAGE_COMPLETE_EVENT` push model (§4.5). Each stage completion broadcasts to at most 8 neighbours; constant overhead. |
| World generation throughput | In practice, the pipeline is deeply pipelined: while the centre chunk does DECORATIONS, its neighbours do TERRAIN. Throughput should be close to the current single-stage rate once the pipeline is full. |
| Lighting stage | Lighting is already the most expensive step. Keeping it as a separate final stage (239) allows it to run once all terrain and decorations are stable, avoiding repeated light recalculation. |

---

## 10. Open Questions / Future Work

1. **Vertical dependency**: The current plan only checks horizontal 3×3
   neighbours. Very tall structures (e.g., floating-island decorations) may
   require vertical neighbours too. This is deferred to a later iteration.

2. **Stage persistence across sessions**: If a world is saved mid-pipeline
   (e.g., chunk at stage 32 when the server stops), the next session must
   detect the incomplete stage and re-run stages 32+ on resumption.
   `m_generation_stage` handles this naturally; no extra work needed.

3. **Parallelism between non-adjacent chunks**: Chunks that are not
   neighbours can still be generated in parallel across EmergeThreads.
   The existing thread-per-chunk model is retained; deferred re-queuing
   does not require a global lock.

4. **Mapgen debug overlay**: A future HUD overlay could colour-code chunks
   by `m_generation_stage` to help modders debug stage dependencies.

5. **Stage skipping for non-generated-content worlds**: Worlds using
   `mapgen_singlenode` can skip stages 32–96 entirely; the stage list
   in `world.mt` would contain only `16,239`.
