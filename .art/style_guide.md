# TDGame Style Guide

> **Status:** SCAFFOLD — style anchor not yet established.
> Do not use the agent for production assets until this guide is filled in and an anchor exists in `.art/anchors/`.

## Current style anchor

*Not yet set.* The first session at the GPU will iterate on Arrow Tower prompts until we lock a style anchor PNG here. Save the chosen image as `.art/anchors/style_anchor.png` and update this section with:
- The exact prompt used
- The seed
- Brief description of the look (e.g. "flat 2D, hand-painted, dark warm palette, 3/4 isometric view")

## Standard prompt prefix

*Not yet defined.* Once the anchor is set, write the canonical prefix here. Every asset prompt the agent constructs will start with this prefix verbatim. Example shape:

```
<style prefix>: flat 2D game art, hand-painted, 3/4 isometric view, transparent background, vibrant primary colors, soft shadow underneath, single subject centered
```

## Resolution per asset category

| Category | Generation size | Final sprite size | Output path |
|---|---|---|---|
| Tower | 1024×1024 | 96×96 | `assets/sprites/towers/` |
| Enemy | 1024×1024 | 48×48 | `assets/sprites/enemies/` |
| Projectile | 1024×1024 | 24×24 | `assets/sprites/projectiles/` |
| Status overlay | 1024×1024 | 32×32 | `assets/sprites/elements/` |
| UI icon | 1024×1024 | 32×32 | `assets/sprites/ui/` |
| Tile (path / ground) | 1024×1024 | 64×64 | `assets/sprites/tiles/` |
| Element icon | 1024×1024 | 48×48 | `assets/sprites/elements/` |

Generation always at 1024×1024 (FLUX's native training resolution) → downscaled to final sprite size as a post-process. Reason: FLUX produces poor results at small native resolutions; downscaling is cleaner.

## Naming convention

`<category>_<element_or_kind>_<variant>.png`

Examples: `tower_fire_basic.png`, `enemy_goblin.png`, `projectile_homing.png`, `status_burning.png`, `ui_gold.png`, `tile_path_corner.png`.

## Core composition rules (game-engine constraints)

- **Transparent background** — required for sprite use. If the model bakes a background, post-process with rembg.
- **Single subject, centered** — no scene context, no foreground/background elements.
- **Consistent lighting direction** — top-left light source by convention. Locked once anchor is chosen.
- **No text** — no labels, captions, or signs on assets.
- **No frames** — sprites are bare; the game UI provides any framing.

## Element-themed color guidance

Color identity per element, drawn from `data/elements/*.tres`. The agent uses these as prompt hints but should not over-saturate — the element's primary color should be ~60% of the sprite, with secondary tones for depth.

| Element | Primary | Secondary | Mood |
|---|---|---|---|
| Fire | warm orange/red | dark crimson, ash | aggressive, intense |
| Water | sky blue | deep teal, foam white | flowing, calm |
| Ice | pale cyan | white, slate blue | sharp, brittle |
| Electric | bright yellow | violet, white-hot core | crackling, fast |
| Earth | warm brown | tan, dusty grey | heavy, solid |
| Air | pale grey-white | sky blue, silver | wispy, fast |
| Poison | green | sickly chartreuse, purple bruise | toxic, organic |

## Approved-asset reference list

*Empty.* Populated automatically by the agent as the manifest grows. Each entry here is a "this looks correct" benchmark for future regenerations.
