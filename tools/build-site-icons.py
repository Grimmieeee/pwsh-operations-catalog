"""Render the site's geometric slash mark to opaque iOS and browser PNGs."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
assets = root / "assets"
polygons = [[(42, 132), (76, 48), (88, 48), (54, 132)],
            [(92, 132), (126, 48), (138, 48), (104, 132)]]
for size, name in [(180, "apple-touch-icon.png"), (32, "favicon-32.png")]:
    scale = size * 4 / 180
    image = Image.new("RGB", (size * 4, size * 4), "#101619")
    draw = ImageDraw.Draw(image)
    for polygon in polygons:
        draw.polygon([(round(x * scale), round(y * scale)) for x, y in polygon], fill="#00e6c7")
    image.resize((size, size), Image.Resampling.LANCZOS).save(assets / name)
