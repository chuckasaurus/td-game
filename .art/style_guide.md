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
| Tower | 1024×1024 | 96×96 | `assets/sprites/towers/` |
| Enemy | 1024×1024 | 48×48 | `assets/sprites/enemies/` |
| Projectile | 1024×1024 | 24×24 | `assets/sprites/projectiles/` |
| Status overlay | 1024×1024 | 32×32 | `assets/sprites/elements/` |
| UI icon | 1024×1024 | 32×32 | `assets/sprites/ui/` |
| Tile (path / ground) | 1024×1024 | 64×64 | `assets/sprites/tiles/` |
| Element icon | 1024×1024 | 48×48 | `assets/sprites/elements/` |

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

## Approved-asset reference list

*Empty.* Populated by the agent as the manifest grows and the user marks assets as approved. Each entry here is a benchmark for future regenerations.

## Re-anchor protocol (if the project ever needs a new style)

1. Parent agent's prompt: "exploration mode: generate N candidates for <subject>, rotating across new variants"
2. Agent generates PNGs into `.art/candidates/` with descriptive suffixes
3. Human picks the winner
4. Winner is copied to `.art/anchors/style_anchor.png`
5. The exact prompt prefix of the winner is locked into the "Standard prompt prefix" section above
6. Status moves to LOCKED, this section gets updated with the new direction details

## Post-processing: transparent backgrounds

The locked prompt asks for "plain neutral background" — production sprites need this stripped to alpha. Workflow:

1. Generate the asset normally via the locked prompt (this produces a 1024×1024 PNG with a neutral-color background)
2. Run background removal as a post-process before downscaling to final sprite size
3. Downscale with nearest-neighbor to the target resolution from the category table above

**Background removal options** (decide once, install once):
- `rembg` Python CLI — install via `pip install rembg[cpu]` or `rembg[gpu]`, then `rembg i input.png output.png`. Fast, decent quality, accepts CPU or GPU.
- `BiRefNet` — newer, much better quality especially for fine details (rope, leaves, hair); GPU-required for speed.
- ComfyUI custom node — adds a node directly to the workflow (e.g. `ComfyUI-Inspyrenet-Rembg`), so background removal happens as part of the generation pipeline. Installable via ComfyUI-Manager.

Current install: **none of the above present.** The agent currently saves PNGs with the original neutral background. Pick one of the above and update this section + the agent when ready.
