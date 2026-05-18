# TDGame Style Guide

> **Status:** LOCKED — anchor selected, production mode active.
> Style anchor: `.art/anchors/style_anchor.png` (originally `arrow_tower_B_dave_54208754.png`, B-direction "Dave modern").
> Locked prompt prefix and seed are in the **Standard prompt prefix** section below — use them verbatim.
> If the visual direction needs to change in the future, generate a new exploration round, pick a new winner, and update this guide. Don't drift mid-project.

## Target aesthetic — LOCKED

**Direction adopted:** "Dave modern" from the first exploration round. Reference points still relevant:
- **Stardew Valley** — warm palette, soft shading, friendly proportions
- **Dave the Diver** — modern HD pixel art density, painterly shading, cinematic atmosphere

**Style traits locked in:**
- 32-bit modern pixel art (medium-density pixels — clearly pixelated but not chunky-blocky)
- **No hard outlines** — color-edge shading defines silhouettes
- **Warm vibrant palette** — not muted, not oversaturated
- **Painterly pixel shading with 6 color depths per surface** — soft gradients within the pixel grid
- 3/4 isometric perspective, light source from upper-left

The anchor image at `.art/anchors/style_anchor.png` is the visual truth for what this means in practice — when in doubt, look at it.

## Composition rules

- **Single subject, centered**, no scene context
- **3/4 isometric perspective** (slight downward tilt) — works for towers, enemies, and ground tiles alike
- **Transparent background** required (post-process if generation includes one)
- **Lighting from top-left** consistently across every asset
- **Soft drop-shadow** under subject (not a hard pixel shadow), helps sprites read against any ground tile
- **No text, no labels, no UI frames** on the sprite itself
- **No 3D render look** — we want clearly pixel-quantized art, not smooth rendered

## Standard prompt prefix — LOCKED

Every production prompt MUST begin with this exact text:

```
pixel art game asset, 32-bit modern pixel art, medium pixels, no outlines, color-edge shading only, warm vibrant palette, painterly pixel shading with 6 color depths, 3/4 isometric view, light source from upper-left
```

## Standard prompt suffix — LOCKED

Every production prompt MUST end with this exact text:

```
single sprite centered on plain neutral background, soft drop shadow under base, no text, no UI, fantasy tower defense game asset
```

## Final prompt template

```
<LOCKED PREFIX>, <subject description>, <LOCKED SUFFIX>
```

The agent only varies the `<subject description>` per asset. Prefix and suffix are immutable until the project re-anchors.

## Reference: how the anchor was generated

- File: `.art/candidates/arrow_tower_B_dave_54208754.png` (now also at `.art/anchors/style_anchor.png`)
- Seed: `54208754`
- Full prompt: see manifest entry with seed `54208754` in `.art/generated.json`
- Resolution: 1024×1024, FLUX.1 schnell, 4 steps, CFG 1.0, euler/simple

## Historical: original exploration axes

Kept for reference if we ever re-explore. The chosen direction was column B (32-bit modern, no outlines, warm vibrant, painterly 6-depth).

| Axis | A (Stardew) | **B (Dave) ← chosen** | C (Cozy) | D (Bold) |
|---|---|---|---|---|
| Pixel density | 16-bit chunky | **32-bit modern, medium pixels** | high-res small pixels | 16-bit chunky |
| Outline | clean dark | **no outlines, color-edge only** | soft brown | clean dark |
| Saturation | warm earthy muted | **warm vibrant** | warm vibrant | saturated fantasy |
| Shading | 4-depth soft | **painterly 6-depth** | painterly 6-depth | flat cel |

## Resolution per asset category

Generation always at 1024×1024 (FLUX's native training res). Downscale to final sprite size as a post-process using nearest-neighbor + optional palette quantization for true-pixel feel.

| Category | Generation size | Final sprite size | Output path |
|---|---|---|---|
| Tower | 1024×1024 | 144×144 | `assets/sprites/towers/` |
| Enemy | 1024×1024 | 72×72 | `assets/sprites/enemies/` |
| Projectile | 1024×1024 | 36×36 | `assets/sprites/projectiles/` |
| Status overlay | 1024×1024 | 48×48 | `assets/sprites/elements/` |
| UI icon | 1024×1024 | 48×48 | `assets/sprites/ui/` |
| Tile (path / ground) | 1024×1024 | 96×96 | `assets/sprites/tiles/` |
| Element icon | 1024×1024 | 72×72 | `assets/sprites/elements/` |

Sizing rationale: bumped 1.5× from the original spec after playtest feedback that the 96px towers were too small for the painted features (cauldron, brazier) to read at game scale — particularly affecting the shader-based pixel-color-range animations. Grid cell size moved in lockstep from 64 to 96 to keep the same sprite-to-cell ratio (~1.5×) and visual feel; the path layout was redesigned for the 20×8 grid.

## Naming convention

`<category>_<element_or_kind>_<variant>.png`

Examples: `tower_fire_basic.png`, `enemy_goblin.png`, `projectile_homing.png`, `status_burning.png`, `ui_gold.png`, `tile_path_corner.png`.

## Element-themed color guidance

Color identity per element. The element's primary color is ~60% of the sprite, with secondary tones for depth and a small accent for highlights.

| Element | Primary | Secondary | Accent | Mood |
|---|---|---|---|---|
| Fire | warm orange/red | dark crimson, ash grey | bright yellow core | aggressive, intense |
| Water | sky blue | deep teal, dusty white | foam highlight | flowing, calm |
| Ice | pale cyan | white, slate blue | bright cyan glint | sharp, brittle |
| Electric | bright yellow | violet, sand | white-hot center | crackling, fast |
| Earth | warm brown | tan, mossy green | dusty cream | heavy, solid |
| Air | pale grey-white | sky blue, silver | bright white | wispy, fast |
| Poison | toxic green | sickly chartreuse, bruise purple | acidic yellow drips | toxic, organic |

## Environment art

Environment art (ground, path, endpoints, decorations) is a separate generation track from tower/enemy/projectile sprites. Key differences:

### Ground anchor — LOCKED

- File: `.art/anchors/ground_anchor.png` (originally `ground_grass_dense_A_lush_1657454243.png`)
- Variant: **A_lush** — dense vibrant green meadow grass with full coverage, no patchiness
- Seed: `1657454243`
- Full prompt: see manifest entry with seed `1657454243` in `.art/generated.json`
- Production sprite: `assets/sprites/tiles/ground/tile_ground_basic.png` (downscaled 1024 → 96, LANCZOS)

The ground anchor establishes the world's environment style — Shadow of the Colossus mood, abandoned/mossy/crumbling, full grass coverage rather than scattered patches. Future ground variants (for visual variety per cell) and path tiles should be generated to feel cohesive with this anchor, using the same prefix/suffix and similar palette.

### Locked tile prompt prefix and suffix

For all environment generation, use:

**Prefix:**
```
pixel art game texture, 32-bit modern pixel art, medium pixels, no outlines, painterly pixel shading with 6 color depths
```

**Suffix:**
```
top-down ground texture viewed straight from above, edge-to-edge fill texture, no border, no margins, no objects on top, no characters, just the ground material, abandoned ruins atmosphere, Shadow of the Colossus mood
```

### Workflow choice

| Category | Workflow | Reason |
|---|---|---|
| Ground tiles | `flux_schnell_tile.json` (no rembg) | Edge-to-edge fill; the "background" IS the asset |
| Path tiles | `flux_schnell_tile.json` | Same |
| Sky / large backgrounds | `flux_schnell_tile.json` | Same |
| Endpoints (castle, cave) | usually `flux_schnell_basic.json` | Sits on top of a ground tile, needs alpha |
| Decorations (trees, rocks, mushrooms) | `flux_schnell_basic.json` | Sits on top of ground, needs alpha |

### Path tile shape system (forward-compatible with junctions)

Each path cell is tagged with a **4-bit neighbor bitmask** describing which of its 4 sides have a path neighbor:

- bit 0 (1): top has path
- bit 1 (2): right has path
- bit 2 (4): bottom has path
- bit 3 (8): left has path

Bitmask → tile shape mapping covers all 16 combinations. The current snake path uses only 6:

| Bitmask | Shape | Sprite filename |
|---|---|---|
| 0b0101 (5) | Horizontal (L+R) | `tile_path_horizontal.png` |
| 0b1010 (10) | Vertical (T+B) | `tile_path_vertical.png` |
| 0b0110 (6) | Corner TR (T+R) | `tile_path_corner_tr.png` |
| 0b1001 (9) | Corner TL (T+L) | `tile_path_corner_tl.png` |
| 0b0011 (3) | Corner BR (B+R) | `tile_path_corner_br.png` |
| 0b1100 (12) | Corner BL (B+L) | `tile_path_corner_bl.png` |

Future additions (generate when first needed by an actual path):

| Bitmask | Shape | Sprite |
|---|---|---|
| 0b0111 (7) | T-junction, top closed (opens R, B, L) | `tile_path_t_top_closed.png` |
| 0b1011 (11) | T-junction, right closed | `tile_path_t_right_closed.png` |
| 0b1101 (13) | T-junction, bottom closed | `tile_path_t_bottom_closed.png` |
| 0b1110 (14) | T-junction, left closed | `tile_path_t_left_closed.png` |
| 0b1111 (15) | 4-way cross | `tile_path_cross.png` |
| 0b0001..0b1000 | Single-side dead ends (×4) | spawn/exit endpoints handle these instead |

The renderer computes each path cell's bitmask from `GridManager.path_waypoints` and looks up the corresponding sprite. Adding intersections later is content work (generate the missing sprites), not a code refactor.

### Ground tile variants

Multiple non-tiling variants per terrain type prevent the obvious tiled-repetition look. Recommended: 3–4 variants per terrain. Assigned per cell with a deterministic seed from cell coords so a given map renders identically each load.

### Resolution per environment category

| Category | Generation | Final | Path |
|---|---|---|---|
| Ground tile | 1024×1024 | 96×96 | `assets/sprites/tiles/ground/` |
| Path tile | 1024×1024 | 96×96 | `assets/sprites/tiles/path/` |
| Decoration | 1024×1024 | 48–72 | `assets/sprites/decorations/` |
| Endpoint (spawn / goal) | 1024×1024 | 144×144 | `assets/sprites/endpoints/` |

## Approved-asset reference list

Benchmarks for future regenerations and style consistency checks. Every kept asset is listed here with its source seed so we can reproduce or iterate.

### Towers — tier 1 basics

| Sprite | Element | Production path | Source candidate | Seed |
|---|---|---|---|---|
| Arrow Tower | (universal) | `assets/sprites/towers/tower_arrow_basic.png` | `.art/anchors/style_anchor.png` (originally `tower_B_dave_54208754`) | 54208754 |
| Flame Tower | Fire | `assets/sprites/towers/tower_fire_basic.png` | `tower_flame_1664193671.png` | 1664193671 |
| Frost Bolt | Ice | `assets/sprites/towers/tower_ice_basic.png` | `tower_frost_677434158.png` | 677434158 |
| Spark | Electric | `assets/sprites/towers/tower_electric_basic.png` | `tower_spark_1340725904.png` | 1340725904 |
| Toxin Spray | Poison | `assets/sprites/towers/tower_poison_basic.png` | `tower_toxin_397391420.png` | 397391420 |
| Mist | Water | `assets/sprites/towers/tower_water_basic.png` | `tower_mist_228084629.png` | 228084629 |
| Stone Thrower | Earth | `assets/sprites/towers/tower_earth_basic.png` | `tower_stonethrower_672486315.png` | 672486315 |
| Gale | Air | `assets/sprites/towers/tower_air_basic.png` | `tower_gale_2119838968.png` | 2119838968 |

All downscaled 1024×1024 → 96×96 with PIL LANCZOS. Source manifest entries marked `status: kept` (or `anchor` for Arrow).

### Towers — tier 2 (deferred unlock content)

10 Boulder candidates exist in `.art/candidates/` (`tower_boulder_*.png` catapult variants + `tower_boulder_ramp_*.png` ramp variants) tagged `tier: 2, unlock_status: deferred_t2_unlock` in the manifest. To be revisited when the in-run reward-card unlock system lands. Note: ramp variants need a UX solution for tower facing direction before they can ship.

## Re-anchor protocol (if the project ever needs a new style)

1. Parent agent's prompt: "exploration mode: generate N candidates for <subject>, rotating across new variants"
2. Agent generates PNGs into `.art/candidates/` with descriptive suffixes
3. Human picks the winner
4. Winner is copied to `.art/anchors/style_anchor.png`
5. The exact prompt prefix of the winner is locked into the "Standard prompt prefix" section above
6. Status moves to LOCKED, this section gets updated with the new direction details

## Post-processing: transparent backgrounds — AUTOMATED

Background removal is now built into the workflow. The generation pipeline runs:

1. `CheckpointLoaderSimple` → `CLIPTextEncode` → `KSampler` → `VAEDecode` produces the raw 1024×1024 image
2. **`InspyrenetRembg` strips the background to alpha** (using the `transparent-background` library via the `ComfyUI-Inspyrenet-Rembg` custom node)
3. `SaveImage` writes the resulting RGBA PNG with proper transparency

The agent's submitted workflows already include this. Outputs from `assets/sprites/*` should have clean alpha channels straight from generation. No separate post-process step.

**Downscaling** to the category's final sprite size (96px for towers, 48px for enemies, etc.) is still a separate step — typically nearest-neighbor for pixel-perfect feel.

**If background removal quality is poor on a specific asset**, two knobs:
- Swap the node to `InspyrenetRembgAdvanced` and tune the `threshold` parameter (0.0–1.0). Lower threshold = aggressive cutout (may remove subject pixels). Higher = conservative (may leave background bleed).
- Regenerate with a different seed — sometimes the model's framing makes the cutout harder.
