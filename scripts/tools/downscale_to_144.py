"""One-shot: re-downscale chosen tower candidates from 1024 to 144 (1.5x larger
than the prior 96 production size). LANCZOS resampling preserves the soft-pixel
FLUX-output look. Overwrites assets/sprites/towers/*.png."""
from PIL import Image
import os

BASE = "C:/Users/Chuck/Projects/TDGame"
CAND = BASE + "/.art/candidates"
ANCH = BASE + "/.art/anchors"
OUT  = BASE + "/assets/sprites/towers"

PAIRS = [
    (ANCH + "/style_anchor.png",                       "tower_arrow_basic.png"),
    (CAND + "/tower_flame_1664193671.png",             "tower_fire_basic.png"),
    (CAND + "/tower_frost_677434158.png",              "tower_ice_basic.png"),
    (CAND + "/tower_spark_1340725904.png",             "tower_electric_basic.png"),
    (CAND + "/tower_toxin_397391420.png",              "tower_poison_basic.png"),
    (CAND + "/tower_mist_228084629.png",               "tower_water_basic.png"),
    (CAND + "/tower_stonethrower_672486315.png",       "tower_earth_basic.png"),
    (CAND + "/tower_gale_2119838968.png",              "tower_air_basic.png"),
]

for src, dst_name in PAIRS:
    dst = OUT + "/" + dst_name
    if not os.path.exists(src):
        print("MISSING: " + src)
        continue
    im = Image.open(src)
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    out = im.resize((144, 144), Image.LANCZOS)
    out.save(dst, "PNG", optimize=True)
    print("OK: " + dst_name + " (1024 -> 144)")
print("Done.")
