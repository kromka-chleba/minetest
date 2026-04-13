/*
Luanti
Copyright (C) 2024 celeron55, Perttu Ahola <celeron55@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#pragma once

#include "irrlichttypes.h"

/*
 * Generation stage numbers for multi-stage mapgen.
 *
 * Stages are unsigned 8-bit integers.  The reserved default pipeline:
 *
 *  0   STAGE_NONE         – Not yet started (initial state of a new block).
 *  16  STAGE_TERRAIN      – Terrain skeleton from noise (solid, water, lava fill).
 *  32  STAGE_CAVES        – Cave and dungeon carving.
 *  48  STAGE_ORES         – Ore placement.
 *  64  STAGE_DECORATIONS  – Decorations (trees, plants, schematics).
 *  96  STAGE_DUST         – Dust/snow overlay (requires completed neighbours
 *                           at STAGE_DECORATIONS).
 * 239  STAGE_LIGHTING     – Final light propagation.
 * 255  STAGE_COMPLETE     – All stages done; equivalent to the old
 *                           m_generated == true.
 *
 * Stage numbers between the reserved values are available to mods.
 * A chunk at stage N can begin stage N+1 only after all 26 neighbours
 * (3×3×3 volume) have completed stage N.  STAGE_TERRAIN is the sole
 * exception: it generates a single chunk in isolation.
 */

constexpr u8 STAGE_NONE        =   0; ///< Block not yet started.
constexpr u8 STAGE_TERRAIN     =  16; ///< Terrain noise, solid/liquid fill.
constexpr u8 STAGE_CAVES       =  32; ///< Cave and dungeon carving.
constexpr u8 STAGE_ORES        =  48; ///< Ore vein placement.
constexpr u8 STAGE_DECORATIONS =  64; ///< Trees, plants, schematics.
constexpr u8 STAGE_DUST        =  96; ///< Snow/dust overlay.
constexpr u8 STAGE_LIGHTING    = 239; ///< Final light propagation.
constexpr u8 STAGE_COMPLETE    = 255; ///< All stages finished.
