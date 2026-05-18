# TDGame Style Guide

> **Status:** PRE-ANCHOR — direction chosen, anchor PNG not yet selected.
> Direction is locked: **pixel art, in the lineage of Stardew Valley and Dave the Diver.**
> Use this guide for exploration runs; do NOT treat any candidate as canonical until
> a winner is copied to `.art/anchors/style_anchor.png` and this status moves to LOCKED.

## Target aesthetic

**Reference points:**
- **Stardew Valley** — cozy, warm earthy palette, soft pixel shading, friendly proportions, clean shapes
- **Dave the Diver** — "modern HD pixel art": higher pixel density (~32–48px subjects), richer shading depth, painterly atmosphere applied to pixel sprites, more cinematic lighting

We want the **Dave-the-Diver pixel density** with **Stardew warmth** — pixels are clearly visible but not chunky-blocky, soft-shaded with 4–6 color depths per surface, warm rather than cold palette overall.

## Composition rules

- **Single subject, centered**, no scene context
- **3/4 isometric perspective** (slight downward tilt) — works for towers, enemies, and ground tiles alike
- **Transparent background** required (post-process if generation includes one)
- **Lighting from top-left** consistently across every asset
- **Soft drop-shadow** under subject (not a hard pixel shadow), helps sprites read against any ground tile
- **No text, no labels, no UI frames** on the sprite itself
- **No 3D render look** — we want clearly pixel-quantized art, not smooth rendered

## Tentative style prefix (to be locked after anchor exploration)

Working draft of the prompt prefix the agent will use:

```
pixel art game asset, high-resolution pixel style inspired by Stardew Valley and Dave the Diver, 3/4 isometric view, soft pixel shading with 4-6 color depths per surface, warm earthy palette, clean dark outlines, light source from upper-left, single sprite centered on plain neutral background, no text, no UI
```

The exploration round will vary this prefix across stylistic axes (see "Exploration axes" below) and the winning combination becomes the locked prefix.

## Exploration axes (for the first anchor session)

When generating candidate sets to choose the anchor from, vary across these dimensions:

| Axis | Variant A | Variant B | Variant C |
|---|---|---|---|
| Pixel density | "16-bit chunky pixels" | "32-bit modern pixel art" | "high-resolution pixel art" |
| Outline | "clean dark outlines" | "no outlines, color-edge shading only" | "soft brown outlines" |
| Saturation | "warm earthy muted palette" | "warm vibrant palette" | "saturated fantasy palette" |
| Shading | "soft pixel shading, 4 color depths" | "painterly pixel shading, 6 color depths" | "flat pixel cel shading" |

The agent's exploration prompt should rotate through combinations to give us a spread.

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

## Anchor session protocol

When invoking asset-forge for the first anchor session:
1. Parent agent's prompt: "exploration mode: generate 12 Arrow Tower candidates rotating through the exploration axes in style_guide.md"
2. Agent generates 12 PNGs into `.art/candidates/` with descriptive suffixes (e.g. `arrow_tower_a16-outline-earthy.png`)
3. Human picks the winner
4. Winner is copied to `.art/anchors/style_anchor.png`
5. The exact prompt + seed of the winner is locked into "Standard prompt prefix" section above
6. Status moves to LOCKED
7. Subsequent invocations use the locked prefix verbatim
