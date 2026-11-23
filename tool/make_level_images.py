"""Makes the 50 level pictures in assets/puzzles/ (level_01.jpg ... level_50.jpg).

    pip install cairosvg pillow
    python tool/make_level_images.py

15 scene types x 10 moods (time of day / season), mixed so every level looks different.
These are placeholder illustrations: you can replace any file with a real photo
of the same name (square is best).
"""
import io
import os
import random

import cairosvg
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'puzzles')
os.makedirs(OUT, exist_ok=True)
S = 300  # drawing size, rendered at 1024 x 1024


def mix(a, b, t):
    a, b = a.lstrip('#'), b.lstrip('#')
    ca = [int(a[i:i + 2], 16) for i in (0, 2, 4)]
    cb = [int(b[i:i + 2], 16) for i in (0, 2, 4)]
    return '#' + ''.join(f'{round(x + (y - x) * t):02X}' for x, y in zip(ca, cb))


# ---------- moods ----------
MOODS = [
    dict(name='Morning', sky=('#8EC9F0', '#E8F4FB'), sun='#FFF3C4', sunY=80, far='#9AA8B6', near='#6F8090',
         water=('#3AA48E', '#16605B'), ground='#7FA65A', tree=('#2E5A3B', '#24492F'), accent='#E76F51', light='#FFFFFF'),
    dict(name='Sunny', sky=('#4FA3E0', '#BFE3F7'), sun='#FFF8D6', sunY=55, far='#8E9BAA', near='#6A7B8B',
         water=('#2A9A84', '#0F5C58'), ground='#79A84E', tree=('#2D5E36', '#214A2A'), accent='#D94F3D', light='#FFFFFF'),
    dict(name='Spring', sky=('#A7DDF5', '#F3FAFC'), sun='#FFFBE0', sunY=70, far='#A3B7C9', near='#86A08A',
         water=('#58B7A3', '#2B7F72'), ground='#8FCB6A', tree=('#4E9A4F', '#F4A6C4'), accent='#F28AB2', light='#FFFFFF'),
    dict(name='Golden', sky=('#F6C177', '#FCE9C8'), sun='#FFE0A0', sunY=110, far='#B89A8A', near='#8E7A72',
         water=('#C98E5A', '#6B4A3A'), ground='#B9A25A', tree=('#5B6B3A', '#4A5A30'), accent='#C0532E', light='#FFF4DC'),
    dict(name='Autumn', sky=('#9CC3DD', '#F1E7D0'), sun=None, sunY=0, far='#A08A7A', near='#7D6658',
         water=('#4F8A8F', '#2A5558'), ground='#C08A3E', tree=('#D0662A', '#B8452A'), accent='#8A3B2A', light='#FFF8EC'),
    dict(name='Misty', sky=('#C9D3D6', '#EEF1F1'), sun='#F7F7F2', sunY=90, far='#B3BEC2', near='#98A6AB',
         water=('#8FA9AE', '#5F7C82'), ground='#8FA08A', tree=('#5F7468', '#4E6357'), accent='#9C6B5A', light='#FFFFFF'),
    dict(name='Winter', sky=('#B9CFE0', '#EEF3F7'), sun='#FFFFFF', sunY=75, far='#C8D3DE', near='#A9B6C4',
         water=('#7FA3B8', '#4A6E85'), ground='#F2F6FA', tree=('#3E5A55', '#2F4A46'), accent='#B5432F', light='#FFFFFF', snow=True),
    dict(name='Sunset', sky=('#E96D5A', '#F9C98A'), sun='#FFD38A', sunY=150, far='#8D5A6B', near='#5E3F55',
         water=('#C76B5E', '#4A2F45'), ground='#6E5A3F', tree=('#3D2F35', '#2E242A'), accent='#F2B33D', light='#FFE3C4'),
    dict(name='Dusk', sky=('#3E4C7A', '#C98FA0'), sun='#F4D7C6', sunY=165, far='#5A5878', near='#3F3D5C',
         water=('#4F5C86', '#232A45'), ground='#3D4A3E', tree=('#22302A', '#1A2620'), accent='#F4B860', light='#FFD9A0'),
    dict(name='Night', sky=('#0E1A33', '#2C3F6B'), sun='#F2F0E6', sunY=60, far='#2E3D5E', near='#1E2A45',
         water=('#1F3357', '#0B1428'), ground='#1E2E2A', tree=('#0F1E1A', '#132520'), accent='#F4C760', light='#FFE7A3', night=True),
]


def sky(m, r):
    out = (f'<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{m["sky"][0]}"/>'
           f'<stop offset="1" stop-color="{m["sky"][1]}"/></linearGradient>'
           f'<linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{m["water"][0]}"/>'
           f'<stop offset="1" stop-color="{m["water"][1]}"/></linearGradient></defs>'
           f'<rect width="{S}" height="{S}" fill="url(#sky)"/>')
    if m.get('night'):
        for _ in range(60):
            out += f'<circle cx="{r.uniform(0, S):.1f}" cy="{r.uniform(0, 150):.1f}" r="{r.uniform(0.4, 1.3):.1f}" fill="#FFFFFF" opacity="{r.uniform(0.4, 1):.2f}"/>'
        out += f'<circle cx="230" cy="{m["sunY"]}" r="20" fill="{m["sun"]}"/><circle cx="240" cy="{m["sunY"] - 5}" r="18" fill="{m["sky"][0]}"/>'
    elif m['sun']:
        x = r.choice([70, 220, 240])
        out += f'<circle cx="{x}" cy="{m["sunY"]}" r="{26 if m["sunY"] > 100 else 22}" fill="{m["sun"]}" opacity="0.95"/>'
    if not m.get('night') and m['name'] not in ('Misty',):
        for _ in range(2):
            cx, cy = r.uniform(20, 260), r.uniform(25, 70)
            out += f'<path d="M{cx:.0f} {cy:.0f} q14 -11 30 0 q13 -2 15 9 h-52z" fill="#FFFFFF" opacity="0.7"/>'
    return out


def trees(m, r, y0, y1, count, h=(18, 34)):
    out = ''
    for _ in range(count):
        x = r.uniform(-5, S)
        base = r.uniform(y0, y1)
        hh = r.uniform(*h)
        w = hh * 0.45
        col = r.choice(m['tree'])
        out += f'<path d="M{x:.1f} {base:.1f} L{x + w / 2:.1f} {base - hh:.1f} L{x + w:.1f} {base:.1f}Z" fill="{col}"/>'
        if m.get('snow'):
            out += f'<path d="M{x + w * 0.3:.1f} {base - hh * 0.6:.1f} L{x + w / 2:.1f} {base - hh:.1f} L{x + w * 0.7:.1f} {base - hh * 0.6:.1f}Z" fill="#FFFFFF"/>'
    return out


def mist(m):
    if m['name'] != 'Misty':
        return ''
    return ''.join(f'<rect y="{y}" width="{S}" height="18" fill="#FFFFFF" opacity="0.28"/>' for y in (150, 190, 230))


# ---------- scene types ----------
def countryside(m, r):
    out = sky(m, r)
    out += f'<path d="M0 190 Q80 150 160 180 T300 170 V300 H0Z" fill="{mix(m["ground"], m["near"], 0.35)}"/>'
    out += f'<path d="M0 225 Q100 195 200 220 T300 215 V300 H0Z" fill="{m["ground"]}"/>'
    # windmill
    wall = mix('#F3F1EC', m['sky'][0], 0.35 if m.get('night') else 0.08)
    out += f'<path d="M200 226 L212 128 H232 L244 226Z" fill="{wall}"/><path d="M206 130 L222 112 L238 130Z" fill="{m["accent"]}"/>'
    out += f'<rect x="216" y="196" width="12" height="30" fill="{mix(m["accent"], "#000000", 0.2)}"/>'
    if m.get('night') or m['name'] == 'Dusk':
        out += f'<rect x="218" y="160" width="8" height="10" fill="{m["light"]}"/>'
    rot = r.uniform(0, 60)
    out += f'<g transform="rotate({rot:.0f} 222 122)" stroke="{mix(m["accent"], "#000000", 0.35)}" stroke-width="2.5" fill="none">'
    out += '<rect x="219" y="50" width="6" height="68"/><rect x="219" y="126" width="6" height="68"/><rect x="150" y="119" width="68" height="6"/><rect x="226" y="119" width="68" height="6"/></g>'
    # barn
    out += f'<rect x="40" y="200" width="56" height="34" fill="{m["accent"]}"/><path d="M34 202 L68 176 L102 202Z" fill="{mix(m["accent"], "#000000", 0.3)}"/>'
    out += f'<rect x="60" y="214" width="14" height="20" fill="{mix(m["accent"], "#FFFFFF", 0.5)}"/>'
    # field rows
    for i, y in enumerate(range(244, 302, 9)):
        c = mix(m['ground'], m['tree'][i % 2] if m['name'] == 'Spring' else '#000000', 0.18 if i % 2 else 0.05)
        out += f'<path d="M0 {y} Q150 {y - 6} 300 {y}" stroke="{c}" stroke-width="5" fill="none"/>'
    if m.get('snow'):
        out += '<path d="M0 240 Q150 234 300 240 V300 H0Z" fill="#FFFFFF" opacity="0.55"/>'
    out += trees(m, r, 205, 225, 7, (14, 26)) + mist(m)
    return out


def lake(m, r):
    out = sky(m, r)
    peaks = [(0, 150), (40, 95), (70, 120), (115, 55), (150, 100), (185, 70), (230, 120), (265, 85), (300, 115)]
    d = 'M' + ' L'.join(f'{x} {y + r.uniform(-8, 8):.0f}' for x, y in peaks) + ' V205 H0Z'
    out += f'<path d="{d}" fill="{m["far"]}"/>'
    snow = mix('#F4F7FA', m['sky'][0], 0.5 if m.get('night') else 0.1)
    out += f'<path d="M115 55 L101 76 L110 73 L117 82 L124 72 L131 78Z M185 70 L174 87 L184 83 L190 90 L197 84Z M265 85 L255 99 L264 96 L270 102 L276 97Z" fill="{snow}"/>'
    out += f'<path d="M0 172 L55 132 L105 162 L168 122 L228 166 L300 142 V205 H0Z" fill="{m["near"]}"/>'
    out += trees(m, r, 200, 207, 45, (16, 32))
    out += f'<rect y="203" width="{S}" height="97" fill="url(#water)"/>'
    for _ in range(5):
        x, y = r.uniform(0, 250), r.uniform(215, 290)
        out += f'<path d="M{x:.0f} {y:.0f} h{r.uniform(30, 70):.0f}" stroke="{mix(m["water"][0], "#FFFFFF", 0.5)}" stroke-width="2" opacity="0.35"/>'
    out += f'<path d="M0 255 L70 258 L42 300 H0Z" fill="{mix("#B98B5B", m["near"], 0.3)}"/>'
    for bx, by, w in [(110, 248, 62), (165, 276, 78)]:
        out += f'<path d="M{bx} {by} h{w} q-8 12 -20 12 h-{w - 40} q-12 0 -20 -12z" fill="{m["accent"]}"/>'
    if m.get('night') or m['name'] == 'Dusk':
        out += f'<rect x="10" y="246" width="4" height="10" fill="{m["light"]}"/>'
    return out + mist(m)


def seaside(m, r):
    out = sky(m, r)
    out += f'<path d="M0 150 Q80 128 150 142 T300 138 V212 H0Z" fill="{mix(m["ground"], m["near"], 0.4)}"/>'
    x = -4
    house_cols = ['#E76F51', '#F4D35E', '#F2EDE4', '#6FB3B8', '#E9C46A', '#C9705A']
    while x < S:
        w, h = r.uniform(22, 34), r.uniform(32, 60)
        top = 212 - h
        c = mix(r.choice(house_cols), m['sky'][1], 0.15)
        if m.get('night'):
            c = mix(c, '#0E1A33', 0.6)
        elif m['name'] in ('Dusk', 'Sunset'):
            c = mix(c, m['near'], 0.35)
        out += f'<rect x="{x:.1f}" y="{top:.1f}" width="{w:.1f}" height="{h:.1f}" fill="{c}"/>'
        out += f'<path d="M{x - 2:.1f} {top:.1f} L{x + w / 2:.1f} {top - 10:.1f} L{x + w + 2:.1f} {top:.1f}Z" fill="{"#FFFFFF" if m.get("snow") else mix("#8A3B2A", m["near"], 0.3)}"/>'
        for wy in range(int(top + 8), 204, 14):
            for wx in (x + 5, x + w - 11):
                lit = (m.get('night') or m['name'] == 'Dusk') and r.random() < 0.6
                out += f'<rect x="{wx:.1f}" y="{wy}" width="6" height="8" fill="{m["light"] if lit else "#3E4F5C"}" opacity="{1 if lit else 0.7}"/>'
        x += w
    out += f'<rect y="210" width="{S}" height="90" fill="url(#water)"/>'
    if m['sun'] and not m.get('night'):
        out += f'<path d="M190 220 h60 M180 236 h80 M200 252 h40" stroke="{m["sun"]}" stroke-width="3" opacity="0.5"/>'
    for sx, sy in [(50, 266), (170, 290), (238, 252)]:
        out += (f'<path d="M{sx} {sy} h34 l-6 8 h-22z" fill="{mix("#F2EDE4", m["near"], 0.3)}"/>'
                f'<path d="M{sx + 17} {sy} V{sy - 38}" stroke="#4A3A2A" stroke-width="1.5"/>'
                f'<path d="M{sx + 18} {sy - 36} L{sx + 36} {sy - 3} H{sx + 18}Z" fill="{mix("#FFFFFF", m["sky"][1], 0.2)}"/>'
                f'<path d="M{sx + 16} {sy - 28} L{sx + 2} {sy - 3} H{sx + 16}Z" fill="{m["accent"]}"/>')
    return out + mist(m)


def desert(m, r):
    out = sky(m, r)
    sand = mix(m['ground'], '#E2A866', 0.55 if not m.get('snow') else 0.1)
    out += f'<path d="M0 200 Q90 150 170 190 T300 175 V300 H0Z" fill="{mix(sand, m["far"], 0.25)}"/>'
    out += f'<path d="M60 212 Q110 190 160 206" stroke="{mix(sand, "#FFFFFF", 0.3)}" stroke-width="2" fill="none"/>'
    out += f'<path d="M0 248 Q110 205 220 245 T300 240 V300 H0Z" fill="{sand}"/>'
    out += f'<path d="M0 290 Q120 262 300 292 V300 H0Z" fill="{mix(sand, "#000000", 0.18)}"/>'
    # cacti
    cac = mix('#3F7A4A', m['near'], 0.35)
    for cx in [r.uniform(30, 90), r.uniform(220, 270)]:
        base = 262
        out += (f'<rect x="{cx:.0f}" y="{base - 40}" width="9" height="40" rx="4" fill="{cac}"/>'
                f'<path d="M{cx:.0f} {base - 24} h-8 v-12" stroke="{cac}" stroke-width="7" stroke-linecap="round" fill="none"/>'
                f'<path d="M{cx + 9:.0f} {base - 18} h8 v-14" stroke="{cac}" stroke-width="7" stroke-linecap="round" fill="none"/>')
    # camels in a line
    camel = mix('#7A4E2C', m['near'], 0.5)
    for i, cx in enumerate([140, 168, 196]):
        cy = 214 + i * 2
        out += (f'<path d="M{cx} {cy} q4 -10 9 -2 q4 -8 9 0 l4 -6 l3 2 l-4 8 v6 h-2 v8 h-2 v-8 h-12 v8 h-2 v-8 h-2z" fill="{camel}"/>')
    return out + mist(m)


def forest(m, r):
    out = sky(m, r)
    out += f'<path d="M0 175 Q150 150 300 178 V300 H0Z" fill="{mix(m["ground"], m["near"], 0.4)}"/>'
    out += trees(m, r, 175, 195, 30, (30, 55))
    out += f'<path d="M0 225 Q150 210 300 228 V300 H0Z" fill="{m["ground"]}"/>'
    path = mix('#C9A77A', m['ground'], 0.35)
    out += f'<path d="M110 300 Q138 262 148 225 Q160 262 200 300Z" fill="{path}"/>'
    # round trees in front
    for _ in range(7):
        tx = r.choice([r.uniform(-10, 100), r.uniform(200, 310)])
        ty = r.uniform(215, 250)
        out += f'<rect x="{tx - 3:.0f}" y="{ty:.0f}" width="6" height="{290 - ty:.0f}" fill="{mix("#5B3F2A", m["near"], 0.3)}"/>'
        for _ in range(3):
            out += f'<circle cx="{tx + r.uniform(-14, 14):.0f}" cy="{ty + r.uniform(-16, 4):.0f}" r="{r.uniform(14, 22):.0f}" fill="{r.choice(m["tree"])}"/>'
            if m.get('snow'):
                out += f'<circle cx="{tx + r.uniform(-8, 8):.0f}" cy="{ty - 18:.0f}" r="8" fill="#FFFFFF"/>'
    # deer
    deer = mix('#9A6A3E', m['near'], 0.4)
    out += f'<path d="M150 232 h16 v-6 l4 -6 l2 2 l-3 5 v5 h-1 v10 h-2 v-8 h-12 v8 h-2 v-8 h-2z" fill="{deer}"/>'
    if m['name'] == 'Autumn':
        for _ in range(14):
            out += f'<circle cx="{r.uniform(0, S):.0f}" cy="{r.uniform(240, 300):.0f}" r="2.5" fill="{r.choice(m["tree"])}"/>'
    return out + mist(m)



def city(m, r):
    out = sky(m, r)
    lit = m.get('night') or m['name'] in ('Dusk', 'Sunset')
    for layer, (base, col, hmin, hmax) in enumerate([(205, m['far'], 60, 120), (225, m['near'], 40, 95)]):
        x = -5
        while x < S:
            w, h = r.uniform(22, 40), r.uniform(hmin, hmax)
            out += f'<rect x="{x:.1f}" y="{base - h:.1f}" width="{w:.1f}" height="{h + 80:.1f}" fill="{col}"/>'
            if layer == 1:
                for wy in range(int(base - h + 8), int(base) - 4, 11):
                    for wx in range(int(x + 5), int(x + w - 6), 9):
                        on = lit and r.random() < 0.55
                        out += f'<rect x="{wx}" y="{wy}" width="4" height="6" fill="{m["light"] if on else mix(col, "#FFFFFF", 0.25)}" opacity="{1 if on else 0.6}"/>'
            x += w + r.uniform(0, 4)
    out += f'<rect y="235" width="{S}" height="65" fill="url(#water)"/>'
    out += f'<rect y="228" width="{S}" height="8" fill="{mix(m["near"], "#000000", 0.25)}"/>'
    for i in range(6):
        cx = r.uniform(0, 280)
        out += f'<rect x="{cx:.0f}" y="222" width="14" height="6" rx="2" fill="{r.choice([m["accent"], "#F2C230", "#FFFFFF", "#4F7DB3"])}"/>'
    for _ in range(4):
        y = r.uniform(245, 295)
        out += f'<path d="M{r.uniform(0, 250):.0f} {y:.0f} h{r.uniform(20, 50):.0f}" stroke="{m["light"] if lit else "#FFFFFF"}" stroke-width="2" opacity="0.35"/>'
    return out + mist(m)


def lighthouse(m, r):
    out = sky(m, r)
    out += f'<rect y="180" width="{S}" height="120" fill="url(#water)"/>'
    out += f'<path d="M0 150 Q60 140 110 160 L140 300 H0Z" fill="{m["near"]}"/>'
    out += f'<path d="M0 150 Q60 140 110 160 L112 168 Q60 150 0 160Z" fill="{"#FFFFFF" if m.get("snow") else m["ground"]}"/>'
    if m.get('night') or m['name'] in ('Dusk', 'Misty'):
        out += f'<path d="M72 62 L300 20 L300 110Z" fill="{m["light"]}" opacity="0.25"/>'
    out += f'<path d="M58 152 L64 70 H80 L86 152Z" fill="#F4F1EA"/>'
    for y in (80, 104, 128):
        out += f'<path d="M{64 - (y - 70) * 0.075:.1f} {y} H{80 + (y - 70) * 0.075:.1f} L{80 + (y + 12 - 70) * 0.075:.1f} {y + 12} H{64 - (y + 12 - 70) * 0.075:.1f}Z" fill="{m["accent"]}"/>'
    out += f'<rect x="62" y="58" width="20" height="12" fill="{m["light"] if (m.get("night") or m["name"] == "Dusk") else "#9CC7D9"}"/><path d="M60 58 L72 46 L84 58Z" fill="{mix(m["accent"], "#000000", 0.3)}"/>'
    out += f'<rect x="94" y="140" width="14" height="12" fill="#F4F1EA"/><path d="M92 140 L101 132 L110 140Z" fill="{m["accent"]}"/>'
    for _ in range(7):
        x, y = r.uniform(130, 290), r.uniform(195, 295)
        out += f'<path d="M{x:.0f} {y:.0f} q8 -5 16 0 q8 -5 16 0" stroke="#FFFFFF" stroke-width="2" fill="none" opacity="0.5"/>'
    for _ in range(3):
        x, y = r.uniform(150, 270), r.uniform(60, 120)
        out += f'<path d="M{x:.0f} {y:.0f} q5 -5 10 0 q5 -5 10 0" stroke="{mix(m["near"], "#000000", 0.3)}" stroke-width="1.5" fill="none"/>'
    out += f'<path d="M200 230 h40 l-6 8 h-28z" fill="{m["accent"]}"/><path d="M220 230 V196 L240 228Z" fill="#FFFFFF"/>'
    return out + mist(m)


def balloons(m, r):
    out = sky(m, r)
    out += f'<path d="M0 240 Q90 205 180 235 T300 225 V300 H0Z" fill="{mix(m["ground"], m["near"], 0.3)}"/>'
    out += f'<path d="M0 265 Q120 240 300 262 V300 H0Z" fill="{m["ground"]}"/>'
    out += trees(m, r, 245, 262, 10, (10, 18))
    cols = [m['accent'], '#F2C230', '#4F9DD9', '#E8669A', '#5FB36B', '#F08A2E']
    spots = [(70, 80, 30), (180, 60, 38), (250, 140, 24), (120, 160, 20), (30, 175, 16), (215, 205, 14)]
    for i, (cx, cy, rad) in enumerate(spots):
        c1, c2 = cols[i % len(cols)], cols[(i + 2) % len(cols)]
        if m.get('night'):
            c1, c2 = mix(c1, '#0E1A33', 0.4), mix(c2, '#0E1A33', 0.4)
        env = f'M{cx - rad} {cy} a{rad} {rad} 0 1 1 {2 * rad} 0 q0 {rad * 0.6:.1f} {-rad * 0.6:.1f} {rad * 1.1:.1f} h{-rad * 0.8:.1f} q{-rad * 0.6:.1f} {-rad * 0.5:.1f} {-rad * 0.6:.1f} {-rad * 1.1:.1f}z'
        out += f'<path d="{env}" fill="{c1}"/>'
        out += f'<path d="M{cx - rad * 0.35:.1f} {cy - rad} q{-rad * 0.25:.1f} {rad:.1f} {rad * 0.05:.1f} {rad * 2.1:.1f} M{cx + rad * 0.35:.1f} {cy - rad} q{rad * 0.25:.1f} {rad:.1f} {-rad * 0.05:.1f} {rad * 2.1:.1f}" stroke="{c2}" stroke-width="{rad * 0.22:.1f}" fill="none"/>'
        out += f'<path d="M{cx - rad * 0.3:.1f} {cy + rad * 1.1:.1f} L{cx - rad * 0.2:.1f} {cy + rad * 1.45:.1f} M{cx + rad * 0.3:.1f} {cy + rad * 1.1:.1f} L{cx + rad * 0.2:.1f} {cy + rad * 1.45:.1f}" stroke="#5B3F2A" stroke-width="1"/>'
        out += f'<rect x="{cx - rad * 0.22:.1f}" y="{cy + rad * 1.45:.1f}" width="{rad * 0.44:.1f}" height="{rad * 0.3:.1f}" fill="#8A5A34"/>'
        if m.get('night'):
            out += f'<circle cx="{cx}" cy="{cy + rad * 1.3:.1f}" r="{rad * 0.2:.1f}" fill="{m["light"]}" opacity="0.8"/>'
    return out + mist(m)


def castle(m, r):
    out = sky(m, r)
    out += f'<path d="M0 170 L50 120 L90 150 L150 100 L210 150 L260 115 L300 140 V230 H0Z" fill="{m["far"]}"/>'
    out += f'<path d="M0 230 Q150 165 300 230 V300 H0Z" fill="{mix(m["ground"], m["near"], 0.2)}"/>'
    wall = mix('#C9BBA5', m['near'], 0.35)
    roof = m['accent']
    out += f'<rect x="100" y="130" width="100" height="62" fill="{wall}"/>'
    for x in range(100, 200, 10):
        out += f'<rect x="{x}" y="124" width="6" height="8" fill="{wall}"/>'
    for tx, tw, th in [(84, 26, 92), (190, 26, 92), (136, 28, 120)]:
        out += f'<rect x="{tx}" y="{192 - th}" width="{tw}" height="{th}" fill="{mix(wall, "#000000", 0.08)}"/>'
        out += f'<path d="M{tx - 4} {192 - th} L{tx + tw / 2} {192 - th - 30} L{tx + tw + 4} {192 - th}Z" fill="{roof}"/>'
        lit = m.get('night') or m['name'] == 'Dusk'
        out += f'<rect x="{tx + tw / 2 - 3}" y="{192 - th + 14}" width="6" height="10" rx="3" fill="{m["light"] if lit else mix(wall, "#000000", 0.45)}"/>'
    out += f'<path d="M150 42 V28 l14 5 -14 5" fill="{m["accent"]}" stroke="#5B3F2A" stroke-width="1"/>'
    out += f'<path d="M140 192 v-22 a10 10 0 0 1 20 0 v22z" fill="{mix(wall, "#000000", 0.5)}"/>'
    out += f'<path d="M140 300 Q146 240 150 192 Q154 240 170 300Z" fill="{mix("#C9A77A", m["ground"], 0.3)}"/>'
    out += trees(m, r, 225, 260, 12, (14, 26))
    return out + mist(m)


def beach(m, r):
    out = sky(m, r)
    out += f'<rect y="170" width="{S}" height="80" fill="url(#water)"/>'
    for _ in range(4):
        y = r.uniform(180, 240)
        out += f'<path d="M{r.uniform(0, 240):.0f} {y:.0f} h{r.uniform(30, 60):.0f}" stroke="#FFFFFF" stroke-width="2" opacity="0.4"/>'
    sand = mix('#EBCB95', m['sky'][1], 0.25 if not m.get('night') else 0.6)
    out += f'<path d="M0 235 Q150 222 300 238 V300 H0Z" fill="{sand}"/>'
    out += f'<path d="M0 235 Q150 222 300 238" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.6"/>'
    trunk = mix('#8A5A34', m['near'], 0.3)
    leaf = mix('#3E8A4A', m['near'], 0.3)
    for bx, h, lean in [(40, 120, 18), (255, 100, -14)]:
        top = (bx + lean, 240 - h)
        out += f'<path d="M{bx} 245 Q{bx + lean * 0.2:.0f} {240 - h / 2:.0f} {top[0]} {top[1]}" stroke="{trunk}" stroke-width="7" fill="none"/>'
        for ang in (-60, -20, 20, 60, 100, 140):
            import math
            ex = top[0] + 34 * math.cos(math.radians(ang - 90))
            ey = top[1] + 34 * math.sin(math.radians(ang - 90)) * 0.6 + 12
            out += f'<path d="M{top[0]} {top[1]} Q{(top[0] + ex) / 2:.0f} {min(top[1], ey) - 10:.0f} {ex:.0f} {ey:.0f}" stroke="{leaf}" stroke-width="6" fill="none" stroke-linecap="round"/>'
    out += f'<path d="M140 262 a34 22 0 0 1 68 0z" fill="{m["accent"]}"/><path d="M162 262 a12 22 0 0 1 24 0z" fill="#FFFFFF"/>'
    out += f'<path d="M174 262 V292" stroke="#5B3F2A" stroke-width="2"/>'
    out += f'<rect x="200" y="280" width="34" height="8" rx="3" fill="#4F9DD9"/>'
    out += f'<circle cx="100" cy="282" r="7" fill="#F2C230"/><path d="M93 282 h14 M100 275 v14" stroke="#E76F51" stroke-width="2"/>'
    return out + mist(m)


def cabin(m, r):
    out = sky(m, r)
    out += f'<path d="M0 170 L70 95 L120 140 L190 80 L250 135 L300 110 V220 H0Z" fill="{m["far"]}"/>'
    out += f'<path d="M70 95 L58 110 L70 106 L80 114Z M190 80 L176 98 L190 93 L202 100Z" fill="#F4F7FA"/>'
    out += trees(m, r, 210, 222, 30, (24, 44))
    out += f'<path d="M0 220 Q150 205 300 222 V300 H0Z" fill="{m["ground"]}"/>'
    wood_c = mix('#8A5A34', m['near'], 0.25)
    out += f'<rect x="110" y="196" width="80" height="50" fill="{wood_c}"/>'
    for y in range(200, 246, 7):
        out += f'<path d="M110 {y} h80" stroke="{mix(wood_c, "#000000", 0.25)}" stroke-width="1"/>'
    out += f'<path d="M100 198 L150 160 L200 198Z" fill="{"#FFFFFF" if m.get("snow") else mix(m["accent"], "#000000", 0.35)}"/>'
    out += f'<rect x="170" y="166" width="10" height="20" fill="#6E5A4A"/>'
    for i in range(3):
        out += f'<circle cx="{176 + i * 6}" cy="{158 - i * 10}" r="{5 + i * 2}" fill="#FFFFFF" opacity="{0.5 - i * 0.12:.2f}"/>'
    lit = m.get('night') or m['name'] in ('Dusk', 'Sunset', 'Winter', 'Misty')
    win = m['light'] if lit else '#BFD8E8'
    out += f'<rect x="120" y="208" width="18" height="16" fill="{win}"/><rect x="162" y="208" width="18" height="16" fill="{win}"/>'
    out += f'<rect x="143" y="220" width="14" height="26" fill="{mix(wood_c, "#000000", 0.4)}"/>'
    for x in range(20, 100, 12):
        out += f'<path d="M{x} 262 v-16" stroke="{wood_c}" stroke-width="3"/>'
    out += f'<path d="M14 252 h90 M14 258 h90" stroke="{wood_c}" stroke-width="2"/>'
    return out + mist(m)


def waterfall(m, r):
    out = sky(m, r)
    out += f'<path d="M0 60 L60 70 L110 90 L120 300 H0Z" fill="{m["near"]}"/>'
    out += f'<path d="M300 50 L240 66 L190 90 L180 300 H300Z" fill="{mix(m["near"], m["far"], 0.4)}"/>'
    out += f'<rect x="110" y="88" width="80" height="170" fill="{mix(m["water"][0], "#FFFFFF", 0.35)}"/>'
    for _ in range(14):
        x = r.uniform(114, 184)
        out += f'<path d="M{x:.0f} {r.uniform(90, 130):.0f} V{r.uniform(200, 258):.0f}" stroke="#FFFFFF" stroke-width="{r.uniform(1.5, 4):.1f}" opacity="0.6"/>'
    out += f'<path d="M60 258 Q150 240 240 258 V300 H60Z" fill="url(#water)"/>'
    for _ in range(9):
        out += f'<circle cx="{r.uniform(105, 195):.0f}" cy="{r.uniform(250, 266):.0f}" r="{r.uniform(5, 11):.0f}" fill="#FFFFFF" opacity="0.7"/>'
    if m['name'] in ('Sunny', 'Spring', 'Morning'):
        for i, c in enumerate(['#E85D4A', '#F2A93B', '#F2D33B', '#5FB36B', '#4F9DD9', '#7A5CC7']):
            out += f'<path d="M{70 + i * 4} 230 A{90 - i * 4} {90 - i * 4} 0 0 1 {230 - i * 4} 230" stroke="{c}" stroke-width="3" fill="none" opacity="0.45"/>'
    out += trees(m, r, 64, 90, 8, (14, 26))
    out += ''.join(f'<path d="M{x:.0f} {y:.0f} l6 -18 l6 18z" fill="{r.choice(m["tree"])}"/>' for x, y in [(200, 72), (214, 70), (250, 62), (270, 58)])
    out += f'<path d="M0 300 Q40 270 90 300Z M210 300 Q260 268 300 290 V300Z" fill="{m["ground"]}"/>'
    return out + mist(m)


def underwater(m, r):
    top = mix(m['water'][0], m['sky'][1], 0.35)
    bottom = mix(m['water'][1], '#06223A', 0.35)
    out = (f'<defs><linearGradient id="deep" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
           f'<stop offset="1" stop-color="{bottom}"/></linearGradient></defs><rect width="{S}" height="{S}" fill="url(#deep)"/>')
    for x in (40, 120, 210):
        out += f'<path d="M{x} 0 L{x + 30} 0 L{x + 70} 300 L{x + 20} 300Z" fill="#FFFFFF" opacity="0.07"/>'
    out += f'<path d="M0 255 Q80 240 160 258 T300 250 V300 H0Z" fill="{mix("#D9C08F", bottom, 0.3)}"/>'
    for x in (20, 60, 240, 275):
        out += f'<path d="M{x} 262 q-8 -20 0 -40 q8 -20 0 -45" stroke="{mix("#3E8A4A", bottom, 0.2)}" stroke-width="5" fill="none"/>'
    for cx, c in [(110, '#E8669A'), (150, '#F08A2E'), (190, m['accent'])]:
        for _ in range(5):
            out += f'<circle cx="{cx + r.uniform(-14, 14):.0f}" cy="{r.uniform(225, 255):.0f}" r="{r.uniform(5, 10):.0f}" fill="{c}"/>'
    for _ in range(7):
        x, y, s = r.uniform(20, 260), r.uniform(50, 200), r.uniform(8, 16)
        c = r.choice(['#F2C230', '#F08A2E', '#4F9DD9', '#E8669A', '#FFFFFF'])
        d = r.choice([1, -1])
        out += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{s:.0f}" ry="{s * 0.55:.0f}" fill="{c}"/>'
        out += f'<path d="M{x - d * s:.0f} {y:.0f} l{-d * s * 0.7:.0f} {-s * 0.5:.0f} v{s:.0f}z" fill="{c}"/>'
        out += f'<circle cx="{x + d * s * 0.5:.0f}" cy="{y - s * 0.12:.0f}" r="1.6" fill="#1A1A1A"/>'
    for _ in range(14):
        out += f'<circle cx="{r.uniform(0, 300):.0f}" cy="{r.uniform(10, 240):.0f}" r="{r.uniform(1.5, 4):.1f}" fill="none" stroke="#FFFFFF" opacity="0.6"/>'
    return out


def space(m, r):
    base = mix('#0B1026', m['sky'][0], 0.18)
    out = f'<rect width="{S}" height="{S}" fill="{base}"/>'
    for _ in range(90):
        out += f'<circle cx="{r.uniform(0, S):.1f}" cy="{r.uniform(0, S):.1f}" r="{r.uniform(0.4, 1.4):.1f}" fill="#FFFFFF" opacity="{r.uniform(0.3, 1):.2f}"/>'
    out += f'<circle cx="210" cy="110" r="58" fill="{mix(m["accent"], "#F2C230", 0.3)}"/>'
    out += f'<path d="M160 100 q50 -12 100 4 M158 122 q55 -10 104 2" stroke="{mix(m["accent"], "#000000", 0.25)}" stroke-width="6" fill="none" opacity="0.6"/>'
    out += f'<ellipse cx="210" cy="114" rx="92" ry="16" fill="none" stroke="{mix("#F4E3C4", m["sky"][1], 0.3)}" stroke-width="5" transform="rotate(-14 210 114)"/>'
    out += f'<circle cx="62" cy="230" r="34" fill="{mix("#8FA3B8", m["sky"][1], 0.2)}"/>'
    for cx, cy, rr in [(50, 222, 6), (72, 242, 4), (68, 214, 3)]:
        out += f'<circle cx="{cx}" cy="{cy}" r="{rr}" fill="#000000" opacity="0.18"/>'
    out += '<g transform="rotate(32 120 120)"><path d="M112 70 q8 -22 16 0 v42 h-16z" fill="#F4F1EA"/>'
    out += f'<circle cx="120" cy="86" r="5" fill="#4F9DD9" stroke="#5A6B7A" stroke-width="1.5"/><path d="M112 98 l-8 14 h8z M128 98 l8 14 h-8z" fill="{m["accent"]}"/>'
    out += '<path d="M114 112 q6 22 12 0z" fill="#F2A93B"/><path d="M117 112 q3 12 6 0z" fill="#FFF1C9"/></g>'
    out += f'<path d="M20 40 l60 22" stroke="#FFFFFF" stroke-width="2" opacity="0.6" stroke-linecap="round"/><circle cx="82" cy="63" r="3" fill="#FFFFFF"/>'
    return out


def garden(m, r):
    out = sky(m, r)
    out += f'<path d="M0 170 Q150 150 300 172 V300 H0Z" fill="{mix(m["ground"], m["near"], 0.25)}"/>'
    out += trees(m, r, 168, 178, 8, (30, 46))
    fence = mix('#F4F1EA', m['near'], 0.3)
    for x in range(-4, 304, 14):
        out += f'<path d="M{x} 212 v-26 l5 -6 l5 6 v26z" fill="{fence}"/>'
    out += f'<path d="M0 196 h300 M0 206 h300" stroke="{fence}" stroke-width="3"/>'
    out += f'<path d="M0 212 H300 V300 H0Z" fill="{m["ground"]}"/>'
    out += f'<path d="M120 300 Q140 250 150 212 Q160 250 200 300Z" fill="{mix("#C9A77A", m["ground"], 0.3)}"/>'
    petals = [m['accent'], '#F2C230', '#E8669A', '#FFFFFF', '#9B6BD3', '#F08A2E']
    for _ in range(26):
        x = r.choice([r.uniform(0, 120), r.uniform(190, 300)])
        y = r.uniform(222, 295)
        size = 3 + (y - 220) / 18
        c = r.choice(petals)
        out += f'<path d="M{x:.0f} {y:.0f} v{size * 2:.0f}" stroke="#3E8A4A" stroke-width="1.5"/>'
        for k in range(5):
            import math
            a = k * 72
            out += f'<circle cx="{x + size * 0.8 * math.cos(math.radians(a)):.1f}" cy="{y + size * 0.8 * math.sin(math.radians(a)):.1f}" r="{size * 0.6:.1f}" fill="{c}"/>'
        out += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{size * 0.4:.1f}" fill="#F2C230"/>'
    for _ in range(3):
        x, y = r.uniform(40, 260), r.uniform(120, 200)
        c = r.choice(petals)
        out += f'<path d="M{x:.0f} {y:.0f} q-8 -9 -10 2 q4 6 10 -2 q8 -9 10 2 q-4 6 -10 -2" fill="{c}"/>'
    out += f'<rect x="215" y="230" width="46" height="6" fill="#8A5A34"/><path d="M219 236 v12 M257 236 v12" stroke="#5B3F2A" stroke-width="3"/>'
    return out + mist(m)

# 15 scene types. The Dart code (lib/data/levels.dart) uses the same lists and formulas
# to give each level its name, so keep them in the same order.
PLACES = [
    ('Fields', countryside), ('Lake', lake), ('Harbour', seaside), ('Dunes', desert), ('Woods', forest),
    ('City', city), ('Lighthouse', lighthouse), ('Balloons', balloons), ('Castle', castle), ('Beach', beach),
    ('Cabin', cabin), ('Waterfall', waterfall), ('Reef', underwater), ('Space', space), ('Garden', garden),
]


def level_info(n):
    """Level n (1..50) -> (place index, mood index). Next level always shows a different scene."""
    # Every 15 levels the scenes come back, with the mood shifted so no picture repeats.
    return (n - 1) % len(PLACES), (n + 3 * ((n - 1) // len(PLACES))) % len(MOODS)


# Scenes where "Night Reef" or "Spring Space" would sound odd get their own words.
SPECIAL_WORDS = {
    'Reef': ['Coral', 'Sunlit', 'Bright', 'Golden', 'Hidden', 'Quiet', 'Cold', 'Deep', 'Blue', 'Secret'],
    'Space': ['Red', 'Ringed', 'Bright', 'Golden', 'Far', 'Silent', 'Frozen', 'Fiery', 'Purple', 'Deep'],
}


def level_title(n):
    p, mo = level_info(n)
    place = PLACES[p][0]
    word = SPECIAL_WORDS[place][mo] if place in SPECIAL_WORDS else MOODS[mo]['name']
    return f'{word} {place}'


if __name__ == '__main__':
    for n in range(1, 51):
        p, mo = level_info(n)
        r = random.Random(n * 97)
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" width="1024" height="1024">{PLACES[p][1](MOODS[mo], r)}</svg>'
        png = cairosvg.svg2png(bytestring=svg.encode(), output_width=1024, output_height=1024)
        Image.open(io.BytesIO(png)).convert('RGB').save(os.path.join(OUT, f'level_{n:02d}.jpg'), quality=84, optimize=True)
        print(f'level_{n:02d}.jpg  {level_title(n)}')
