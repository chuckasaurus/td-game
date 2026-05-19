"""Generate a path mask PNG for inpainting from the map's cell-coord waypoints.

Output: a 1920x768 RGB PNG, white (255) where the path should be inpainted,
black (0) elsewhere, with Gaussian-blurred edges so the inpainted path blends
softly into the surrounding ground rather than cutting hard.

Run again with new WAYPOINTS to generate a mask for a different map.
"""
from PIL import Image, ImageDraw, ImageFilter
import os

OUT_PATH = "C:/Users/Chuck/Projects/TDGame/assets/sprites/backgrounds/map_01_path_mask.png"

# Background image dimensions
WIDTH = 1920
HEIGHT = 768

# Grid layout (must match map_01.tscn's GridManager)
CELL_SIZE = 96

# Path waypoints in CELL coordinates, matching map_01.tscn GridManager.path_waypoints.
# (0,4) -> (7,4) -> (7,1) -> (14,1) -> (14,6) -> (19,6)
WAYPOINTS_CELL = [(0, 4), (7, 4), (7, 1), (14, 1), (14, 6), (19, 6)]

# Path width in pixels. Matches cell size so the painted path occupies the
# same width as the gameplay path cells.
PATH_WIDTH = CELL_SIZE

# Edge feather radius (pixels). Larger = softer blend at path edges, but
# eats into the path's solid-fill area.
FEATHER_BLUR = 6


def cell_to_pixel(cell):
    """Convert a cell coord to its center in the 1920x768 background image."""
    col, row = cell
    return (col * CELL_SIZE + CELL_SIZE // 2, row * CELL_SIZE + CELL_SIZE // 2)


def main():
    # Convert cell-coord waypoints to image-pixel coords
    points = [cell_to_pixel(wp) for wp in WAYPOINTS_CELL]

    # Extend the first and last waypoints off-image so the path visually flows
    # off the screen edges (enemies spawn outside the frame, exit outside).
    first = points[0]
    last = points[-1]
    points[0] = (-CELL_SIZE, first[1])
    points[-1] = (WIDTH + CELL_SIZE, last[1])

    mask = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
    draw = ImageDraw.Draw(mask)

    # Draw connected segments as thick white lines, with circular caps at each
    # waypoint to ensure clean corner joins.
    radius = PATH_WIDTH // 2
    for i in range(len(points) - 1):
        a = points[i]
        b = points[i + 1]
        draw.line([a, b], fill=(255, 255, 255), width=PATH_WIDTH)
    for p in points:
        draw.ellipse(
            [p[0] - radius, p[1] - radius, p[0] + radius, p[1] + radius],
            fill=(255, 255, 255),
        )

    # Soft edges so the inpaint blends rather than hard-cuts
    if FEATHER_BLUR > 0:
        mask = mask.filter(ImageFilter.GaussianBlur(radius=FEATHER_BLUR))

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    mask.save(OUT_PATH, "PNG")
    print("Mask saved: " + OUT_PATH + " (" + str(WIDTH) + "x" + str(HEIGHT) + ")")


if __name__ == "__main__":
    main()
