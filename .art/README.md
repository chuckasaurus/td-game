# `.art/` — asset generation contract

This directory is the **style consistency contract** for the asset-forge subagent.
Every generation reads from here; every successful generation appends to it.

## What lives here

| File / dir | Purpose |
|---|---|
| `style_guide.md` | The style anchor + standard prompt prefix + resolution per category. The single source of truth for "what does this game look like." Edit when the project's visual direction changes; don't drift. |
| `workflows/` | ComfyUI workflow JSON templates. `flux_schnell_basic.json` is the default text-to-image template. Future: IPAdapter-conditioned templates, ControlNet templates, img2img variants. |
| `anchors/` | Reference images used for style anchoring (and future IPAdapter conditioning). The canonical style anchor lives here once chosen. |
| `generated.json` | Chronological manifest of every asset produced. Records prompt, seed, size, output path, anchor used. Never deleted entries — kept for reproducibility. |

## Conventions

- ComfyUI server: `http://127.0.0.1:8188` (default), running from `C:\Users\Chuck\Tools\ComfyUI`.
- ComfyUI output directory: `C:\Users\Chuck\Tools\ComfyUI\ComfyUI\output\`. The agent copies files from there into `assets/sprites/<category>/`.
- Generated PNGs land in `assets/sprites/<category>/` with canonical naming defined in `style_guide.md`.
- Anchors and the manifest ARE version-controlled (`.art/anchors/` + `.art/generated.json`); transient ComfyUI outputs that didn't make the cut are NOT.

## Invocation

```
Agent(subagent_type="asset-forge", prompt="generate <category>: <subject>")
```

The agent handles: checking ComfyUI is alive, reading the style contract, building the workflow, submitting, polling for completion, moving the output, updating the manifest.
