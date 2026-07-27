"""Remove baked-in checkerboard / gray shade from home UI PNGs → true RGBA."""
from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

HOME = Path(r'D:\Playstore\UnBlockMe-Pro\assets\ui\home')

# Files that currently show checkerboard behind them
TARGETS = [
    'logo.png',
    'puzzle_preview.png',
    'btn_play.png',
    'btn_levels.png',
]


def is_checkerish(r: int, g: int, b: int) -> bool:
    """Typical AI transparency checker: near-white or light gray, low chroma."""
    mx, mn = max(r, g, b), min(r, g, b)
    chroma = mx - mn
    # near white / light gray squares
    if chroma <= 18 and mn >= 175:
        return True
    # slightly darker gray tile
    if chroma <= 14 and 140 <= mn <= 210:
        return True
    return False


def remove_bg(path: Path) -> None:
    im = Image.open(path).convert('RGBA')
    w, h = im.size
    px = im.load()
    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    def try_seed(x: int, y: int) -> None:
        r, g, b, a = px[x, y]
        if is_checkerish(r, g, b):
            q.append((x, y))
            visited[y][x] = True

    for x in range(w):
        try_seed(x, 0)
        try_seed(x, h - 1)
    for y in range(h):
        try_seed(0, y)
        try_seed(w - 1, y)

    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h or visited[ny][nx]:
                continue
            r, g, b, a = px[nx, ny]
            if is_checkerish(r, g, b):
                visited[ny][nx] = True
                q.append((nx, ny))

    # Soften leftover fringe: kill near-checker pixels adjacent to transparent
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if not is_checkerish(r, g, b):
                continue
            if any(px[x + dx, y + dy][3] == 0 for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1))):
                px[x, y] = (0, 0, 0, 0)

    im.save(path)
    print(f'fixed {path.name} -> RGBA {im.size}')


def main() -> None:
    for name in TARGETS:
        p = HOME / name
        if not p.exists():
            print('missing', p)
            continue
        remove_bg(p)
    print('done')


if __name__ == '__main__':
    main()
