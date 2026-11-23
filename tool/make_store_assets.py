"""Makes the Google Play graphics for Tablecraft.

    pip install cairosvg pillow
    python tool/make_store_assets.py            # run from the project folder

Output in store_assets/:
  icon-512.png, icon-preview.png, feature-graphic-1024x500.png, screenshot-1..5.png (1080x1920, 9:16)
  and assets/icon/icon_foreground.png (Android adaptive icon layer).

The screen pictures follow the app's real layout. Once the app runs, you can put real
screenshots (1080x1920) into store_assets/real/ named 1.png ... 5.png and run this again:
they will be framed with the same captions instead.
"""
import base64
import io
import os
import random

import cairosvg
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'store_assets')
os.makedirs(OUT, exist_ok=True)

INK, SOFT, CREAM, CARD, LINE = '#3B2A1A', '#6E5034', '#FBF5EA', '#FFFDF8', '#EADCC6'
TEAL, COIN, COIN_D, WOOD_T = '#1E6E68', '#F2A93B', '#C47D12', '#5A3415'
FONT = "font-family=\"Nunito\""


def img_uri(name):
    with open(os.path.join(ROOT, 'assets', 'puzzles', name + '.jpg'), 'rb') as f:
        return 'data:image/jpeg;base64,' + base64.b64encode(f.read()).decode()


import importlib.util as _ilu
_spec = _ilu.spec_from_file_location('levels_gen', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'make_level_images.py'))
_levels = _ilu.module_from_spec(_spec)
_spec.loader.exec_module(_levels)
title_of = _levels.level_title


def medium_grid(level):
    return round(3 + (level - 1) / 49 * 5)


# Names used in this script -> level pictures made by tool/make_level_images.py
_FILES = {'alpine_lake': 'level_17', 'tulip_mill': 'level_01', 'golden_dunes': 'level_34', 'old_harbour': 'level_22', 'autumn_walk': 'level_45',
          **{f'level_{i:02d}': f'level_{i:02d}' for i in range(1, 51)}}
PICS = {k: img_uri(v) for k, v in _FILES.items()}


def render(svg, path, w, h):
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=w, output_height=h)
    Image.open(io.BytesIO(png)).convert('RGB').save(path, optimize=True)
    print('wrote', os.path.relpath(path, ROOT))


# ---------- jigsaw shapes (same rules as lib/game/jigsaw_shape.dart) ----------
TAB = [(0.36, 0), (0.40, 0), (0.42, 0.04), (0.39, 0.10), (0.34, 0.20), (0.40, 0.28), (0.50, 0.28),
       (0.60, 0.28), (0.66, 0.20), (0.61, 0.10), (0.58, 0.04), (0.60, 0), (0.64, 0)]


def gen_edges(n, seed):
    r = random.Random(seed)
    H = [[0 if y in (0, n) else r.choice((1, -1)) for _ in range(n)] for y in range(n + 1)]
    V = [[0 if x in (0, n) else r.choice((1, -1)) for x in range(n + 1)] for _ in range(n)]
    return [[(-H[y][x], V[y][x + 1], H[y + 1][x], -V[y][x]) for x in range(n)] for y in range(n)]


def piece_d(e, s, ox, oy):
    def edge(sx, sy, dx, dy, nx, ny, t):
        def P(a, b):
            return f'{sx + dx * a * s + nx * b * s * t + ox:.1f} {sy + dy * a * s + ny * b * s * t + oy:.1f}'
        if t == 0:
            return ' L' + P(1, 0)
        d = ' L' + P(*TAB[0])
        for i in range(1, 13, 3):
            d += ' C' + P(*TAB[i]) + ' ' + P(*TAB[i + 1]) + ' ' + P(*TAB[i + 2])
        return d + ' L' + P(1, 0)
    top, right, bottom, left = e
    d = f'M{ox:.1f} {oy:.1f}'
    d += edge(0, 0, 1, 0, 0, -1, top) + edge(s, 0, 0, 1, 1, 0, right)
    d += edge(s, s, -1, 0, 0, 1, bottom) + edge(0, s, 0, -1, -1, 0, left)
    return d + ' Z'


_uid = [0]


def uid(p='c'):
    _uid[0] += 1
    return f'{p}{_uid[0]}'


def board(pic, x, y, side, n, seed, missing=(), outline_alpha=0.55, well=True):
    """Puzzle board with placed pieces; missing pieces leave the well visible."""
    E = gen_edges(n, seed)
    cell = side / n
    cid = uid()
    paths = [(r, c, piece_d(E[r][c], cell, x + c * cell, y + r * cell)) for r in range(n) for c in range(n)
             if (r * n + c) not in missing]
    clip = ''.join(f'<path d="{d}"/>' for _, _, d in paths)
    out = f'<defs><clipPath id="{cid}">{clip}</clipPath></defs>'
    if well:
        out += f'<rect x="{x}" y="{y}" width="{side}" height="{side}" rx="4" fill="#000" fill-opacity="0.15"/>'
    out += f'<image href="{PICS[pic]}" x="{x}" y="{y}" width="{side}" height="{side}" clip-path="url(#{cid})" preserveAspectRatio="xMidYMid slice"/>'
    for _, _, d in paths:
        out += f'<path d="{d}" fill="none" stroke="#28190A" stroke-opacity="0.28" transform="translate(0.7 0.9)"/>'
        out += f'<path d="{d}" fill="none" stroke="#fff" stroke-opacity="{outline_alpha}"/>'
    return out, E, cell


def loose_piece(pic, E, n, r, c, cell, cx, cy, size, rot):
    """One piece out of the board, drawn centred at (cx, cy) with `size` = cell size on screen."""
    k = size / cell
    side = cell * n
    cid = uid()
    d = piece_d(E[r][c], cell, c * cell, r * cell)
    g = (f'<g transform="translate({cx} {cy}) rotate({rot}) scale({k}) translate({-(c + .5) * cell} {-(r + .5) * cell})">'
         f'<defs><clipPath id="{cid}"><path d="{d}"/></clipPath></defs>'
         f'<path d="{d}" fill="#000" fill-opacity="0.25" transform="translate(1.5 3)"/>'
         f'<image href="{PICS[pic]}" x="0" y="0" width="{side}" height="{side}" clip-path="url(#{cid})" preserveAspectRatio="xMidYMid slice"/>'
         f'<path d="{d}" fill="none" stroke="#fff" stroke-opacity="0.6" stroke-width="{1.2 / k}"/></g>')
    return g


def wood(w, h, base='#E7C99C', grain='#7A4E24', alpha=0.12, seed=7):
    r = random.Random(seed)
    out = f'<rect width="{w}" height="{h}" fill="{base}"/>'
    x = 0.0
    while x < w:
        sw = (0.6 + r.random() * 1.8) * w / 390
        bend = (r.random() * 8 - 4) * w / 390
        out += f'<path d="M{x:.1f} 0 Q{x + bend:.1f} {h / 2} {x:.1f} {h}" stroke="{grain}" stroke-opacity="{alpha}" stroke-width="{sw:.2f}" fill="none"/>'
        x += (3 + r.random() * 9) * w / 390
    return out


def felt(w, h, base='#2F5D46'):
    out = f'<rect width="{w}" height="{h}" fill="{base}"/>'
    for d in range(-h, w, 4):
        out += f'<line x1="{d}" y1="0" x2="{d + h}" y2="{h}" stroke="#fff" stroke-opacity="0.07"/>'
    return out


def text(x, y, s, size, weight=800, color=INK, anchor='start', extra=''):
    return f'<text x="{x}" y="{y}" {FONT} font-size="{size}" font-weight="{weight}" fill="{color}" text-anchor="{anchor}" {extra}>{s}</text>'


def icon(d, x, y, size=22, color=INK, sw=2.2):
    k = size / 24
    return (f'<g transform="translate({x} {y}) scale({k})" fill="none" stroke="{color}" stroke-width="{sw}" '
            f'stroke-linecap="round" stroke-linejoin="round"><path d="{d}"/></g>')


def round_btn(cx, cy, d, active=False):
    return (f'<circle cx="{cx}" cy="{cy}" r="22" fill="{TEAL if active else "#FFFAF0"}" fill-opacity="{1 if active else 0.92}" stroke="#6B4A2B" stroke-opacity="0.3"/>'
            + icon(d, cx - 11, cy - 11, 22, '#fff' if active else INK))


def coin(cx, cy, r=11):
    k = r / 12
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{COIN}" stroke="{COIN_D}" stroke-width="{1.5 * k}"/>'
            f'<g transform="translate({cx - 12 * k} {cy - 12 * k}) scale({k})"><path d="M7 7h3.2a1.8 1.8 0 113.6 0H17v3.2a1.8 1.8 0 110 3.6V17h-3.2a1.8 1.8 0 10-3.6 0H7v-3.2a1.8 1.8 0 100-3.6z" fill="#FFF4DC"/></g>')


def logo(x, y, size, color=TEAL):
    cell = size / 1.56
    pad = cell * 0.28
    return f'<path d="{piece_d((1, 1, -1, -1), cell, x + pad, y + pad)}" fill="{color}"/>'


def pill(x, y, w, label, d=None, active=False, badge=None):
    out = f'<rect x="{x}" y="{y}" width="{w}" height="44" rx="22" fill="{TEAL if active else "#FFFAF0"}" fill-opacity="{1 if active else 0.85}" stroke="#6B4A2B" stroke-opacity="0.3"/>'
    tx = x + 16
    if d:
        out += icon(d, tx, y + 13, 18, '#fff' if active else INK)
        tx += 26
    out += text(tx, y + 27, label, 14, 800, '#fff' if active else INK)
    if badge:
        out += f'<rect x="{x + w - 36}" y="{y + 12}" width="24" height="20" rx="10" fill="{TEAL}"/>' + text(x + w - 24, y + 27, badge, 12, 800, '#fff', 'middle')
    return out


BACK = 'M15 18l-6-6 6-6'
EYE = 'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z M12 9a3 3 0 100 6 3 3 0 000-6z'
SQUARE = 'M5 5h14v14H5z'
TIMER = 'M12 8v5l3 2 M12 4a9 9 0 100 18 9 9 0 000-18z M9 2h6'
BULB = 'M9 18h6M10 21h4M12 3a6 6 0 00-4 10.5V16h8v-2.5A6 6 0 0012 3z'
PALETTE = 'M12 3a9 9 0 100 18c1 0 1.6-.8 1.6-1.6 0-.5-.2-.8-.4-1.1-.3-.3-.4-.7-.4-1.1 0-.9.7-1.6 1.6-1.6H16a5 5 0 005-5c0-4.1-4-7.6-9-7.6z'
PHOTO = 'M4 5h12v4M4 5v14h16v-6M8 15l3-3 3 3 2-2 4 4M18 3v6M15 6h6'
CHEV = 'M9 18l6-6-6-6'
PLAY = 'M8 5v14l11-7z'


# ---------- the five app screens (390 x 844, same layout as the Flutter code) ----------

def screen_game():
    s = wood(390, 844)
    s += round_btn(42, 78, BACK)
    s += text(76, 72, title_of(17), 18, 900) + text(306, 72, '37 / 42', 13, 800, INK, 'end')
    s += f'<rect x="76" y="82" width="230" height="6" rx="3" fill="#6B4A2B" fill-opacity="0.18"/><rect x="76" y="82" width="202" height="6" rx="3" fill="{TEAL}"/>'
    s += round_btn(348, 78, EYE)
    b, E, cell = board('alpine_lake', 20, 150, 350, 6, 11, missing={2, 4, 5, 11, 17})
    s += f'<g>{b}</g>'
    s += pill(31, 560, 98, 'Edges', SQUARE) + pill(137, 560, 92, '3:24', TIMER) + pill(237, 560, 122, 'Hint', BULB, badge='3')
    s += '<rect x="0" y="640" width="390" height="204" fill="#6E461E" fill-opacity="0.13"/><line x1="0" y1="640" x2="390" y2="640" stroke="#6E461E" stroke-opacity="0.25"/>'
    for i, (pid, rot) in enumerate([(4, -9), (11, 6), (17, -4), (2, 8)]):
        s += loose_piece('alpine_lake', E, 6, pid // 6, pid % 6, cell, 60 + i * 90, 714, 52, rot)
    return s


def screen_difficulty():
    s = f'<image href="{PICS["alpine_lake"]}" x="-227" y="0" width="844" height="844" preserveAspectRatio="xMidYMid slice"/>'
    s += '<rect width="390" height="844" fill="#19120A" fill-opacity="0.28"/>'
    s += round_btn(42, 78, BACK)
    s += f'<path d="M0 352 Q0 324 28 324 H362 Q390 324 390 352 V844 H0Z" fill="{CREAM}"/>'
    s += '<rect x="175" y="336" width="40" height="5" rx="2.5" fill="#DCCBB2"/>'
    s += text(20, 376, 'Alpine Lake', 14, 800, SOFT) + text(20, 408, 'How many pieces?', 24, 900)
    opts = [(3, 'About 2 min'), (4, 'About 4 min'), (6, 'About 10 min'), (8, 'About 18 min'), (10, 'About 30 min')]
    for i, (n, t) in enumerate(opts):
        x, y = 20 + (i % 3) * 120, 428 + (i // 3) * 112
        on = n == 6
        s += f'<rect x="{x}" y="{y}" width="110" height="102" rx="16" fill="{"#E2EFEC" if on else CARD}" stroke="{TEAL if on else LINE}" stroke-width="{2.5 if on else 1}"/>'
        c = TEAL if on else '#9C7C5A'
        gx, gy = x + 42, y + 16
        s += f'<rect x="{gx}" y="{gy}" width="26" height="26" rx="3" fill="none" stroke="{c}"/>'
        for j in range(1, n):
            v = 26 * j / n
            s += f'<path d="M{gx + v:.1f} {gy}V{gy + 26}M{gx} {gy + v:.1f}H{gx + 26}" stroke="{c}" stroke-width="0.7"/>'
        s += text(x + 55, y + 66, str(n * n), 18, 900, INK, 'middle') + text(x + 55, y + 86, t, 11, 700, SOFT, 'middle')
    s += f'<rect x="20" y="664" width="350" height="72" rx="16" fill="{CARD}" stroke="{LINE}"/>'
    s += text(36, 694, 'Rotate pieces', 16, 900) + text(36, 716, 'Pieces start turned. Tap one to turn it.', 13, 600, SOFT)
    s += f'<rect x="306" y="686" width="52" height="30" rx="15" fill="#E8DDCB" stroke="#9C7C5A"/><circle cx="322" cy="701" r="9" fill="#9C7C5A"/>'
    s += f'<rect x="20" y="756" width="350" height="54" rx="27" fill="{TEAL}"/>' + text(195, 789, 'Start with 36 pieces', 17, 900, '#fff', 'middle')
    return s


def screen_home():
    s = f'<rect width="390" height="844" fill="{CREAM}"/>'
    s += f'<g>{wood(390, 250)}</g><line x1="0" y1="250" x2="390" y2="250" stroke="#6E461E" stroke-opacity="0.25"/>'
    s += logo(20, 52, 30) + text(56, 76, 'Tablecraft', 26, 900, WOOD_T)
    s += f'<rect x="232" y="56" width="90" height="40" rx="20" fill="{CARD}"/>' + coin(253, 76) + text(270, 82, '312', 15, 900)
    s += round_btn(348, 76, PALETTE)
    s += f'<rect x="20" y="118" width="350" height="96" rx="18" fill="{CARD}"/>'
    s += f'<clipPath id="ct"><rect x="32" y="130" width="72" height="72" rx="12"/></clipPath><image href="{PICS["tulip_mill"]}" x="32" y="130" width="72" height="72" clip-path="url(#ct)"/>'
    s += text(118, 150, 'Continue where you left off', 12, 800, SOFT) + text(118, 172, 'Tulip Mill', 18, 900)
    s += f'<rect x="118" y="182" width="150" height="6" rx="3" fill="{LINE}"/><rect x="118" y="182" width="95" height="6" rx="3" fill="{TEAL}"/>' + text(276, 189, '63%', 12, 800)
    s += f'<circle cx="334" cy="166" r="24" fill="{TEAL}"/><path d="M328 155v22l17-11z" fill="#fff"/>'
    s += f'<rect x="20" y="270" width="350" height="76" rx="18" fill="{CARD}" stroke="{LINE}"/><circle cx="58" cy="308" r="24" fill="#E2EFEC"/>' + icon(PHOTO, 47, 297, 22, TEAL, 2)
    s += text(96, 302, 'Use your own photo', 16, 900) + text(96, 322, 'Turn any picture into a puzzle', 13, 600, SOFT) + icon(CHEV, 340, 297, 22, SOFT)
    s += text(20, 388, 'Puzzles', 20, 900)
    cards = [('alpine_lake', 'Alpine Lake', 'Landscapes', 0), ('tulip_mill', 'Tulip Mill', 'Countryside', 0),
             ('golden_dunes', 'Golden Dunes', 'Landscapes', 0), ('old_harbour', 'Old Harbour', 'Towns', 300)]
    for i, (pic, title, cat, price) in enumerate(cards):
        x, y = 20 + (i % 2) * 182, 404 + (i // 2) * 222
        s += f'<rect x="{x}" y="{y}" width="168" height="210" rx="18" fill="{CARD}"/>'
        cid = uid()
        s += f'<clipPath id="{cid}"><rect x="{x + 8}" y="{y + 8}" width="152" height="148" rx="12"/></clipPath>'
        s += f'<image href="{PICS[pic]}" x="{x + 8}" y="{y + 8}" width="152" height="148" preserveAspectRatio="xMidYMid slice" clip-path="url(#{cid})"/>'
        if price:
            s += f'<rect x="{x + 8}" y="{y + 8}" width="152" height="148" rx="12" fill="#000" fill-opacity="0.35"/>'
            s += f'<rect x="{x + 50}" y="{y + 68}" width="68" height="28" rx="14" fill="{INK}"/>' + coin(x + 64, y + 82, 10) + text(x + 78, y + 87, str(price), 14, 900, '#FFF4DC')
        s += text(x + 12, y + 178, title, 15, 900) + text(x + 12, y + 196, cat, 12, 600, SOFT)
    return s


def screen_backgrounds():
    s = f'<g>{felt(390, 470)}</g>'
    s += f'<circle cx="42" cy="78" r="22" fill="#fff" fill-opacity="0.14" stroke="#fff" stroke-opacity="0.22"/>' + icon(BACK, 31, 67, 22, '#fff')
    s += f'<g transform="rotate(-2.3 195 270)"><rect x="100" y="180" width="190" height="190" fill="#000" fill-opacity="0.3" transform="translate(0 6)"/><image href="{PICS["alpine_lake"]}" x="100" y="180" width="190" height="190"/></g>'
    s += f'<path d="M0 470 Q0 442 28 442 H362 Q390 442 390 470 V844 H0Z" fill="{CREAM}"/>'
    s += text(20, 492, 'Table background', 22, 900)
    sw = [('Light oak', 'oak'), ('Walnut', 'walnut'), ('Linen', 'linen'), ('Green felt', 'felt'), ('Slate', 'slate'), ('Denim', 'denim')]
    fills = {'oak': '#E7C99C', 'walnut': '#6E4529', 'linen': '#E9E2D3', 'felt': '#2F5D46', 'slate': '#3A4048', 'denim': '#4F7099'}
    for i, (name, key) in enumerate(sw):
        x, y = 20 + (i % 3) * 120, 512 + (i // 3) * 122
        on = key == 'felt'
        s += f'<rect x="{x}" y="{y}" width="110" height="88" rx="14" fill="{TEAL if on else LINE}"/>'
        cid = uid()
        inset = 3 if on else 1
        s += f'<clipPath id="{cid}"><rect x="{x + inset}" y="{y + inset}" width="{110 - 2 * inset}" height="{88 - 2 * inset}" rx="11"/></clipPath>'
        tex = wood(110, 88, fills[key], '#000' if key == 'walnut' else '#7A4E24', 0.15, i) if key in ('oak', 'walnut') else felt(110, 88, fills[key])
        if key == 'linen':
            tex = f'<rect width="110" height="88" fill="{fills[key]}"/>' + ''.join(f'<path d="M0 {y2}H110M{y2} 0V88" stroke="#000" stroke-opacity="0.05"/>' for y2 in range(0, 110, 3))
        s += f'<g clip-path="url(#{cid})"><g transform="translate({x} {y})">{tex}</g></g>'
        s += text(x + 55, y + 108, name, 13, 800, INK, 'middle')
    s += f'<rect x="20" y="764" width="350" height="54" rx="27" fill="{TEAL}"/>' + text(195, 797, 'Use this background', 17, 900, '#fff', 'middle')
    return s


def screen_complete():
    s = wood(390, 844, seed=3)
    s += text(195, 80, 'Puzzle complete!', 30, 900, WOOD_T, 'middle') + text(195, 104, 'Tulip Mill, 64 pieces', 14, 700, WOOD_T, 'middle')
    s += f'<rect x="139" y="118" width="112" height="28" rx="14" fill="{COIN}"/>' + text(195, 137, 'New best time', 13, 900, INK, 'middle')
    b, _, _ = board('tulip_mill', 0, 0, 270, 8, 5, outline_alpha=0.22, well=False)
    s += f'<g transform="translate(195 330) rotate(-1.4) translate(-145 -145)"><rect x="0" y="0" width="290" height="290" fill="#000" fill-opacity="0.22" transform="translate(0 6)"/><rect width="290" height="290" fill="{CARD}"/><g transform="translate(10 10)">{b}</g></g>'
    for i, (k, v) in enumerate([('Time', '11:02'), ('Your best', '11:02'), ('Hints used', '0')]):
        x = 20 + i * 120
        s += f'<rect x="{x}" y="498" width="110" height="64" rx="14" fill="{CARD}"/>' + text(x + 12, 520, k, 12, 800, SOFT) + text(x + 12, 546, v, 20, 900)
    s += f'<rect x="20" y="572" width="350" height="68" rx="16" fill="{CARD}"/>' + coin(52, 606, 18)
    s += text(82, 602, '+67 coins', 18, 900) + text(82, 622, 'Includes 15 bonus coins for using no hints', 12, 700, SOFT)
    s += f'<rect x="20" y="660" width="350" height="54" rx="27" fill="{TEAL}"/>' + text(195, 693, 'Back to puzzles', 17, 900, '#fff', 'middle')
    s += f'<rect x="20" y="726" width="350" height="48" rx="24" fill="#FFFAF0" fill-opacity="0.6" stroke="{SOFT}" stroke-width="1.5"/>' + text(195, 756, 'Play again', 15, 800, INK, 'middle')
    return s


GRID = 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z'
TODAY = 'M4 6h16v14H4zM4 10h16M8 3v4M16 3v4'
PERSON = 'M12 12a4 4 0 100-8 4 4 0 000 8zM4 21c0-4 4-6 8-6s8 2 8 6'
LOCK = 'M6 11h12v10H6zM8 11V8a4 4 0 018 0v3'
FIRE = 'M12 3c1 4 5 5 5 10a5 5 0 01-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-5 1-9z'


def nav_bar(active):
    s = f'<rect x="0" y="764" width="390" height="80" fill="{CARD}"/><line x1="0" y1="764" x2="390" y2="764" stroke="{LINE}"/>'
    for i, (d, label) in enumerate([(GRID, 'Levels'), (TODAY, 'Daily'), (PHOTO, 'Create'), (PERSON, 'Me')]):
        cx = 49 + i * 97.5
        on = i == active
        if on:
            s += f'<rect x="{cx - 30}" y="776" width="60" height="32" rx="16" fill="#E2EFEC"/>'
        s += icon(d, cx - 12, 780, 24, TEAL if on else SOFT, 2)
        s += text(cx, 826, label, 12, 800 if on else 600, INK if on else SOFT, 'middle')
    return s


def star_icons(x, y, n, size=14):
    out = ''
    for i in range(3):
        k = size / 24
        fill = COIN if i < n else 'none'
        stroke = COIN if i < n else '#9C7C5A'
        out += (f'<g transform="translate({x + i * (size + 1)} {y}) scale({k})"><path d="M12 2l3 6.5 7 .8-5.2 4.8 1.5 7L12 17.6 5.7 21.1l1.5-7L2 9.3l7-.8z" '
                f'fill="{fill}" stroke="{stroke}" stroke-width="2"/></g>')
    return out


def screen_levels():
    s = f'<rect width="390" height="844" fill="{CREAM}"/>'
    s += f'<g>{wood(390, 140)}</g><line x1="0" y1="140" x2="390" y2="140" stroke="#6E461E" stroke-opacity="0.25"/>'
    s += f'<circle cx="42" cy="66" r="22" fill="{TEAL}" stroke="{CARD}" stroke-width="2"/>' + text(42, 74, 'A', 19, 900, '#fff', 'middle')
    s += text(74, 62, 'Hi, Ali', 20, 900, WOOD_T) + text(74, 82, '12 of 50 done, Medium mode', 13, 700, WOOD_T)
    s += f'<rect x="270" y="46" width="100" height="40" rx="20" fill="{CARD}"/>' + coin(291, 66) + text(308, 72, '486', 15, 900)
    s += f'<rect x="20" y="104" width="350" height="8" rx="4" fill="#6B4A2B" fill-opacity="0.18"/><rect x="20" y="104" width="84" height="8" rx="4" fill="{TEAL}"/>'
    s += text(20, 172, 'Chapter 2', 12, 800, SOFT) + text(20, 194, 'Warming Up', 19, 900) + text(370, 190, '2 / 10', 14, 800, SOFT, 'end')
    tw, th = 108.7, 140
    blur = uid('bl')
    s += f'<defs><filter id="{blur}"><feGaussianBlur stdDeviation="5"/></filter></defs>'
    for i in range(9):
        lvl = 11 + i
        x, y = 20 + (i % 3) * (tw + 12), 210 + (i // 3) * (th + 12)
        nxt, done, locked = lvl == 13, lvl < 13, lvl > 13
        s += f'<rect x="{x}" y="{y}" width="{tw}" height="{th}" rx="16" fill="{CARD}" stroke="{TEAL if nxt else LINE}" stroke-width="{2.5 if nxt else 1}"/>'
        cid = uid()
        ix, iy, iw, ih = x + 6, y + 6, tw - 12, th - 36
        s += f'<clipPath id="{cid}"><rect x="{ix}" y="{iy}" width="{iw}" height="{ih}" rx="11"/></clipPath>'
        img = f'<image href="{PICS[f"level_{lvl:02d}"]}" x="{ix - 4}" y="{iy - 4}" width="{iw + 8}" height="{ih + 8}" preserveAspectRatio="xMidYMid slice" {"filter=" + chr(34) + "url(#" + blur + ")" + chr(34) if locked else ""}/>'
        s += f'<g clip-path="url(#{cid})">{img}'
        if locked:
            s += f'<rect x="{ix}" y="{iy}" width="{iw}" height="{ih}" fill="#241A10" fill-opacity="0.5"/>' + icon(LOCK, ix + iw / 2 - 13, iy + ih / 2 - 13, 26, '#fff', 2.2)
        s += '</g>'
        if nxt:
            s += f'<circle cx="{ix + iw / 2}" cy="{iy + ih / 2}" r="20" fill="{TEAL}"/><path d="M{ix + iw / 2 - 6} {iy + ih / 2 - 10}v20l16-10z" fill="#fff"/>'
        s += text(x + 8, y + th - 10, str(lvl), 15, 900)
        if done:
            s += star_icons(x + tw - 52, y + th - 24, 3 if lvl == 11 else 2)
        else:
            g = medium_grid(lvl)
            s += text(x + tw - 8, y + th - 11, f'{g * g} pcs', 11, 700, SOFT, 'end')
    s += nav_bar(0)
    return s


def screen_daily():
    s = f'<rect width="390" height="844" fill="{CREAM}"/>'
    s += f'<g>{wood(390, 110)}</g><line x1="0" y1="110" x2="390" y2="110" stroke="#6E461E" stroke-opacity="0.25"/>'
    s += text(20, 78, 'Daily puzzle', 26, 900, WOOD_T)
    s += f'<rect x="270" y="50" width="100" height="40" rx="20" fill="{CARD}"/>' + icon(FIRE, 282, 58, 24, '#E0612A', 2) + text(312, 76, '5 days', 15, 900)
    # this week card
    s += f'<rect x="20" y="130" width="350" height="186" rx="20" fill="{CARD}"/>'
    s += text(34, 158, 'Week 1', 18, 900) + text(34, 178, '22 - 28 November', 13, 700, SOFT) + text(356, 166, '3 / 7', 18, 900, TEAL, 'end')
    tw = (322 - 36) / 7
    for i, (letter, day) in enumerate(zip('SMTWTFS', range(22, 29))):
        x, y = 34 + i * (tw + 6), 192
        done, today, locked = i < 3, i == 3, i > 3
        fill = TEAL if done else ('#E2EFEC' if today else ('#F1E9DC' if locked else CREAM))
        fg = '#fff' if done else ('#A8957E' if locked else INK)
        s += f'<rect x="{x:.1f}" y="{y}" width="{tw:.1f}" height="80" rx="14" fill="{fill}" stroke="{TEAL if today else LINE}" stroke-width="{2 if today else 1}"/>'
        cx = x + tw / 2
        s += text(cx, y + 22, letter, 12, 800, fg, 'middle') + text(cx, y + 44, str(day), 18, 900, fg, 'middle')
        d = 'M7 12l4 4 7-8' if done else (LOCK if locked else 'M8 5v14l11-7z')
        s += icon(d, cx - 8, y + 52, 16, fg, 2.4 if done else 2)
    s += icon('M8 21h8M12 17v4M7 4h10v5a5 5 0 01-10 0zM17 6h3v2a3 3 0 01-3 3M7 6H4v2a3 3 0 003 3', 34, 284, 20, SOFT, 2)
    s += text(62, 299, 'Solve all 7 days for 100 bonus coins', 13, 700, SOFT)
    # today card
    s += f'<rect x="20" y="332" width="350" height="300" rx="22" fill="{CARD}"/>'
    cid = uid()
    s += f'<clipPath id="{cid}"><path d="M20 354 Q20 332 42 332 H348 Q370 332 370 354 V551 H20Z"/></clipPath>'
    s += f'<image href="{PICS["level_38"]}" x="20" y="332" width="350" height="219" preserveAspectRatio="xMidYMid slice" clip-path="url(#{cid})"/>'
    s += text(36, 576, 'Today, Wednesday, 25 November', 13, 800, SOFT) + text(36, 600, title_of(38), 20, 900) + text(36, 620, '36 pieces', 13, 600, SOFT)
    s += f'<rect x="282" y="574" width="76" height="44" rx="22" fill="{TEAL}"/>' + text(320, 602, 'Play', 16, 900, '#fff', 'middle')
    s += nav_bar(1)
    return s


def screen_level_complete():
    s = wood(390, 844, seed=3)
    s += text(195, 74, 'Level 7 complete!', 28, 900, WOOD_T, 'middle') + text(195, 98, f'{title_of(7)}, {medium_grid(7) ** 2} pieces', 14, 700, WOOD_T, 'middle')
    s += star_icons(144, 110, 3, 32)
    b, _, _ = board('level_07', 0, 0, 270, 4, 5, outline_alpha=0.22, well=False)
    s += f'<g transform="translate(195 318) rotate(-1.4) translate(-145 -145)"><rect x="0" y="0" width="290" height="290" fill="#000" fill-opacity="0.22" transform="translate(0 6)"/><rect width="290" height="290" fill="{CARD}"/><g transform="translate(10 10)">{b}</g></g>'
    for i, (k, v) in enumerate([('Time', '1:48'), ('Your best', '1:48'), ('Coins', '+43')]):
        x = 20 + i * 120
        s += f'<rect x="{x}" y="486" width="110" height="64" rx="14" fill="{CARD}"/>' + text(x + 12, 508, k, 12, 800, SOFT) + text(x + 12, 534, v, 20, 900)
    s += f'<rect x="20" y="562" width="350" height="48" rx="14" fill="{TEAL}"/>'
    s += icon('M8 21h8M12 17v4M7 4h10v5a5 5 0 01-10 0zM17 6h3v2a3 3 0 01-3 3M7 6H4v2a3 3 0 003 3', 34, 574, 24, COIN, 2)
    s += text(68, 592, 'Achievement unlocked: No help needed', 14, 800, '#fff')
    s += f'<rect x="20" y="628" width="350" height="54" rx="27" fill="{TEAL}"/>' + text(195, 661, 'Next: level 8', 17, 900, '#fff', 'middle')
    s += f'<rect x="20" y="694" width="350" height="48" rx="24" fill="#FFFAF0" fill-opacity="0.6" stroke="{SOFT}" stroke-width="1.5"/>' + text(195, 724, 'Back to levels', 15, 800, INK, 'middle')
    return s


def screen_create():
    s = f'<rect width="390" height="844" fill="{CREAM}"/>'
    s += f'<g>{wood(390, 124)}</g><line x1="0" y1="124" x2="390" y2="124" stroke="#6E461E" stroke-opacity="0.25"/>'
    s += text(20, 74, 'Create', 26, 900, WOOD_T) + text(20, 98, 'Make a puzzle from any photo', 14, 700, WOOD_T)
    s += f'<rect x="20" y="144" width="350" height="500" rx="24" fill="{CARD}"/>'
    b, _, _ = board('level_08', 45, 160, 300, 4, 9, missing={6}, outline_alpha=0.7, well=False)
    cid = uid()
    s += f'<clipPath id="{cid}"><rect x="45" y="160" width="300" height="300" rx="14"/></clipPath><rect x="45" y="160" width="300" height="300" rx="14" fill="#241A10" fill-opacity="0.55"/><g clip-path="url(#{cid})">{b}</g>'
    s += text(36, 494, 'Your photos, as puzzles', 22, 900)
    s += text(36, 518, 'Family, pets, trips, anything. Pick a picture', 14, 600, SOFT) + text(36, 536, 'and choose how many pieces you want.', 14, 600, SOFT)
    s += f'<rect x="36" y="552" width="318" height="40" rx="20" fill="{TEAL}"/>' + text(195, 578, 'Choose from gallery', 15, 900, '#fff', 'middle')
    s += f'<rect x="36" y="600" width="318" height="36" rx="18" fill="none" stroke="{SOFT}" stroke-width="1.5"/>' + text(195, 623, 'Take a photo', 14, 800, INK, 'middle')
    s += text(20, 676, 'How it works', 18, 900)
    for i, label in enumerate(['1. Pick a photo', '2. Choose pieces', '3. Play']):
        x = 20 + i * 120
        s += f'<rect x="{x}" y="690" width="110" height="62" rx="16" fill="{CARD}"/>' + text(x + 55, 727, label, 12, 800, INK, 'middle')
    s += nav_bar(2)
    return s


SCREENS = [
    ('Real jigsaw pieces', 'Drag them in and feel the snap', screen_game),
    ('50 levels to unlock', 'Easy, Medium or Hard', screen_levels),
    ('A new puzzle every day', 'Finish your week for bonus coins', screen_daily),
    ('Your photos, as puzzles', 'Family, pets, trips: anything', screen_create),
    ('Earn stars and trophies', 'Solve without hints for 3 stars', screen_level_complete),
]


def screenshot(i, title, sub, screen_fn):
    W, H = 1080, 1920
    sx, sy, sw = 214, 430, 652
    sh = round(sw * 844 / 390)
    real = os.path.join(OUT, 'real', f'{i}.png')
    if os.path.exists(real):
        with open(real, 'rb') as f:
            inner = f'<image href="data:image/png;base64,{base64.b64encode(f.read()).decode()}" x="0" y="0" width="390" height="844" preserveAspectRatio="xMidYMid slice"/>'
    else:
        inner = screen_fn()
    clip = uid()
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
           + wood(W, H, '#E2C192', '#7A4E24', 0.10, i)
           + text(W / 2, 190, title, 84, 900, WOOD_T, 'middle') + text(W / 2, 262, sub, 42, 700, SOFT, 'middle')
           + f'<rect x="{sx - 18}" y="{sy - 18}" width="{sw + 36}" height="{sh + 36}" rx="70" fill="#000" fill-opacity="0.25" transform="translate(0 14)"/>'
           + f'<rect x="{sx - 18}" y="{sy - 18}" width="{sw + 36}" height="{sh + 36}" rx="70" fill="#21170F"/>'
           + f'<clipPath id="{clip}"><rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="52"/></clipPath>'
           + f'<g clip-path="url(#{clip})"><svg x="{sx}" y="{sy}" width="{sw}" height="{sh}" viewBox="0 0 390 844">{inner}</svg></g>'
           + '</svg>')
    render(svg, os.path.join(OUT, f'screenshot-{i}.png'), W, H)


# ---------- icon ----------

def piece3d(cx, cy, width):
    """The 3D logo piece (same look as lib/widgets/logo_3d.dart), centred at (cx, cy)."""
    depth = width * 0.07
    cell = (width - depth) / 1.56
    pad = cell * 0.28
    ox, oy = cx - width / 2 + pad, cy - width / 2 + pad - depth / 2
    d = piece_d((1, 1, -1, -1), cell, ox, oy)
    gid, cid, bid = uid('g'), uid('c'), uid('b')
    out = (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="1">'
           f'<stop offset="0" stop-color="#47AFA5"/><stop offset="0.55" stop-color="#1E6E68"/><stop offset="1" stop-color="#165955"/></linearGradient>'
           f'<clipPath id="{cid}"><path d="{d}"/></clipPath>'
           f'<filter id="{bid}" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="{depth * 0.9:.1f}"/></filter></defs>')
    out += f'<path d="{d}" fill="#000" fill-opacity="0.3" transform="translate(0 {depth * 1.6:.1f})" filter="url(#{bid})"/>'
    i = depth
    while i > 0:
        out += f'<path d="{d}" fill="#0E4743" transform="translate(0 {i:.1f})"/>'
        i -= max(1.0, depth / 14)
    bev = depth * 0.7
    out += f'<path d="{d}" fill="url(#{gid})"/>'
    out += (f'<g clip-path="url(#{cid})">'
            f'<path d="{d}" fill="none" stroke="#fff" stroke-opacity="0.25" stroke-width="{bev:.1f}" transform="translate({bev / 2:.1f} {bev / 2:.1f})"/>'
            f'<path d="{d}" fill="none" stroke="#000" stroke-opacity="0.2" stroke-width="{bev:.1f}" transform="translate({-bev / 2:.1f} {-bev / 2:.1f})"/></g>')
    return out


def icon_svg(size, foreground_only=False, scale=0.66):
    bg = '' if foreground_only else wood(480, 480, alpha=0.14, seed=2)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 480 480">'
            f'{bg}{piece3d(240, 240, 480 * scale)}</svg>')


def make_icons():
    render(icon_svg(512), os.path.join(OUT, 'icon-512.png'), 512, 512)
    render(icon_svg(1024), os.path.join(ROOT, 'assets', 'icon', 'icon.png'), 1024, 1024)
    # Transparent layers: Android adaptive icon (piece inside the safe zone) and the native splash.
    for name, scale in [('icon_foreground.png', 0.46), ('splash_logo.png', 0.62)]:
        png = cairosvg.svg2png(bytestring=icon_svg(1024, foreground_only=True, scale=scale).encode(), output_width=1024, output_height=1024)
        with open(os.path.join(ROOT, 'assets', 'icon', name), 'wb') as f:
            f.write(png)
        print('wrote assets/icon/' + name)

    # Preview: how the icon looks with the masks Android launchers and Google Play use.
    with open(os.path.join(OUT, 'icon-512.png'), 'rb') as f:
        uri = 'data:image/png;base64,' + base64.b64encode(f.read()).decode()
    W, H = 1200, 700
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="350" fill="#F2F2F2"/><rect y="350" width="{W}" height="350" fill="#1F1F1F"/>'
    shapes = [('Google Play', 'rr', 0.2), ('Circle', 'c', 0), ('Squircle', 'rr', 0.32), ('Square', 'rr', 0.06)]
    for row, (y0, col) in enumerate([(0, '#333'), (350, '#EEE')]):
        for i, (name, kind, rad) in enumerate(shapes):
            for j, sz in enumerate([160, 72]):
                cx = 150 + i * 300 + (j * 130 - 50)
                cy = y0 + 150
                cid = uid()
                x, y = cx - sz / 2, cy - sz / 2
                clip = f'<circle cx="{cx}" cy="{cy}" r="{sz / 2}"/>' if kind == 'c' else f'<rect x="{x}" y="{y}" width="{sz}" height="{sz}" rx="{sz * rad}"/>'
                svg += f'<clipPath id="{cid}">{clip}</clipPath><image href="{uri}" x="{x}" y="{y}" width="{sz}" height="{sz}" clip-path="url(#{cid})"/>'
            svg += text(150 + i * 300 + 15, y0 + 290, name, 26, 800, col, 'middle')
            if row == 0:
                pass
    svg += '</svg>'
    render(svg, os.path.join(OUT, 'icon-preview.png'), W, H)


# ---------- feature graphic ----------

def feature_graphic():
    W, H = 1024, 500
    s = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">' + wood(W, H, alpha=0.11, seed=4)
    s += piece3d(110, 160, 104) + text(172, 186, 'Tablecraft', 82, 900, WOOD_T)
    s += text(74, 252, 'Relaxing jigsaw puzzles', 38, 800, INK)
    s += text(74, 300, 'Real pieces. Your table. Your pace.', 26, 700, SOFT)
    b, E, cell = board('alpine_lake', 0, 0, 330, 6, 21, missing={4, 5, 11, 17, 3})
    s += (f'<g transform="translate(612 82) rotate(3 165 165)">'
          f'<rect width="350" height="350" x="-10" y="-10" fill="#000" fill-opacity="0.22" transform="translate(0 10)"/>'
          f'<rect width="350" height="350" x="-10" y="-10" fill="{CARD}"/>{b}</g>')
    for pid, cx, cy, rot in [(5, 985, 445, -14), (11, 575, 420, 12), (4, 990, 70, 16)]:
        s += loose_piece('alpine_lake', E, 6, pid // 6, pid % 6, cell, cx, cy, 70, rot)
    s += '</svg>'
    render(s, os.path.join(OUT, 'feature-graphic-1024x500.png'), W, H)


if __name__ == '__main__':
    make_icons()
    feature_graphic()
    for i, (t, sub, fn) in enumerate(SCREENS, start=1):
        screenshot(i, t, sub, fn)
