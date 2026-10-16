"""Generate the Luma blue-purple glow star for all Windows icon sizes.

Usage: python tools/make_icon.py
Dependencies: Pillow, numpy (also used by upstream's icon generator).
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SIZES = (16, 20, 24, 28, 30, 32, 36, 40, 48, 64, 96, 128, 256)

def artwork(size: int) -> Image.Image:
    # Render at higher resolution, then downsample with good antialiasing.
    dim = max(192, size * 3)
    yy, xx = np.mgrid[0:dim, 0:dim]
    x = (xx + .5) / dim - .5
    y = (yy + .5) / dim - .5
    r = np.hypot(x, y)
    angle = np.arctan2(y, x)
    # Four long rounded tips and four concave corners.
    edge = .112 + .320 * np.abs(np.cos(2 * angle)) ** 2.05
    sdf = r - edge
    mask = np.clip(-sdf * dim + .5, 0, 1)
    # Dark navy rounded-square icon tile.
    corner = .167
    dx = np.maximum(np.abs(x) - (.5 - corner), 0)
    dy = np.maximum(np.abs(y) - (.5 - corner), 0)
    tile_alpha = np.clip((corner - np.hypot(dx, dy)) * dim + .5, 0, 1)
    bg_glow = np.clip(1 - np.hypot(x * 1.4, y * 1.4), 0, 1)
    bg = np.zeros((dim, dim, 4), dtype=np.float32)
    bg[:, :, 0] = 7 + 9 * bg_glow
    bg[:, :, 1] = 18 + 23 * bg_glow
    bg[:, :, 2] = 48 + 42 * bg_glow
    bg[:, :, 3] = tile_alpha * 255
    base = Image.fromarray(np.clip(bg, 0, 255).astype("uint8"), "RGBA")

    # Gentle cyan / violet halo, strongest at the star's edge.
    glow_mask = Image.fromarray(np.uint8(mask * 255), "L").filter(
        ImageFilter.GaussianBlur(max(3, dim // 17)))
    halo = Image.new("RGBA", (dim, dim), (63, 93, 249, 0))
    halo.putalpha(glow_mask.point(lambda t: int(t * .57)))
    base = Image.alpha_composite(base, halo)

    # Cyan at top-left, lavender on the right, cool electric blue below.
    glow_at_center = np.exp(-(r / .15) ** 2)
    right = np.clip((x + .15) / .48, 0, 1)
    down = np.clip((y + .13) / .49, 0, 1)
    star = np.zeros((dim, dim, 4), dtype=np.float32)
    star[:, :, 0] = 40 + 154 * right + 120 * glow_at_center
    star[:, :, 1] = 215 - 108 * right - 41 * down + 78 * glow_at_center
    star[:, :, 2] = 248 + 7 * glow_at_center
    star[:, :, 3] = mask * 255
    light = Image.fromarray(np.uint8(np.clip(star, 0, 255)), "RGBA")
    base = Image.alpha_composite(base, light)
    return base.resize((size, size), Image.Resampling.LANCZOS)

def main():
    resources = ROOT / "resources"
    for name in ("app.ico", "search.ico"):
        frames = [artwork(n) for n in SIZES]
        frames[-1].save(resources / name, format="ICO",
            sizes=[(n, n) for n in SIZES], append_images=frames[:-1])
        print("Wrote", name)
    artwork(512).save(resources / "luma-preview.png")
    print("Wrote luma-preview.png")

if __name__ == "__main__":
    main()
