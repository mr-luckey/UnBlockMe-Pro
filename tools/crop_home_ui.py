from PIL import Image
from pathlib import Path

src = Image.open(r'D:\Playstore\UnBlockMe-Pro\assets\ui\home_screen.png').convert('RGBA')
out = Path(r'D:\Playstore\UnBlockMe-Pro\assets\ui\home')
out.mkdir(parents=True, exist_ok=True)

# Background: full art (widgets layered on top in Flutter)
src.save(out / 'bg.png')

crops = {
    # wooden logo plaque with BLOCKED / SLIDE PUZZLE
    'logo.png': (35, 48, 425, 180),
    # puzzle board only
    'puzzle_preview.png': (50, 175, 410, 450),
    # wood bottom bar texture strip (we'll rebuild icons in Flutter)
    'nav_wood.png': (10, 900, 450, 1010),
}

for name, box in crops.items():
    crop = src.crop(box)
    crop.save(out / name)
    print(f'{name}: {box} size={crop.size}')

print('ok', sorted(p.name for p in out.iterdir()))
