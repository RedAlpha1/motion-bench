# Motion spec

Every implementation must match these numbers. If a framework can't do something exactly, write the deviation in that app's README. Otherwise the comparison is not fair.

Design source: the "Framework Stress-Test Screens" canvas (screens 02 Player and 04 Explore).

## Tokens

| Token | Value |
|---|---|
| bg | `#0B0B0F` |
| surface | `#14141B` |
| border | `#1F1F29` |
| text | `#F4F4F6` |
| muted | `#9A9AA6` |
| lime | `#C6F432` |
| violet | `#8B7CFF` |
| coral | `#FF7A59` |
| teal | `#4FD1C5` |
| heart | `#FF5C7A` |

The fonts are Space Grotesk (display) and Inter (body). Using the platform's system font is acceptable; benchmark fonts are not the point.

## Bench controls (shared by every app)

A thin bar at the top has:
- **Screen**: Player | Explore
- **Load**: `1×` | `4×`. This multiplies the equaliser bars (32 → 128) and the grooves on the disc (24 → 96).
- **Auto**: on/off. On the Player it does nothing. On Explore it opens a card, waits 1600 ms, closes it, waits 900 ms, and moves to the next card, looping forever. Use it to get repeatable traces.

## 02 · Player

| Element | Motion |
|---|---|
| Disc (268 dp) | Rotates 360° every **5000 ms**, linear, forever. When paused it freezes on its current angle and resumes from there. |
| Grooves | Concentric rings, radius 40 → 132 dp, evenly spaced. 24 rings, or 96 at 4×. |
| Beat ring | Ring 14 dp outside the disc. Scale .96 ↔ 1.06 and opacity .45 ↔ .85, **470 ms**, ease-in-out, alternating. |
| Orbs | Two soft radial blobs (track `orbA` 320 dp, `orbB` 280 dp). Each drifts on its own loop: A for **11 s** to (+60, +40) and then (−30, +90); B for **13 s** to (−70, −30) and then (+20, −80). Ease-in-out, alternating. |
| EQ bars | N bars spread evenly across the row, 5 dp wide at 1× and 2 dp wide at 4× (128 bars at 5 dp won't fit), in a 44 dp tall row. Bar *i*: height = `H[i % 32]`, duration = `0.32 + ((i*37) % 23)/40` s, scaleY .12 ↔ 1 from the bottom, ease-in-out, alternating. Its phase starts at `((i*53) % 17)/20` of the cycle. Colour cycles accent, 55 % white, 25 % white. |
| Tonearm | Rotates 22° when playing and 0° when paused. Spring with stiffness ≈ 170 and damping ≈ 12 (it should overshoot slightly). |
| Play button | 80 dp. Corner radius 28 dp when playing and 40 dp when paused, spring. The icon swaps with scale .4 → 1 and rotate −90° → 0 over 350 ms. |
| Like | Scale 1 → 1.45 → 1 over **450 ms**. Colour `#FF5C7A` when liked. |
| Track change | Title block fades and slides in (y +14 → 0, opacity 0 → 1) over **550 ms**. Accent colour cross-fades over 800 ms. |
| Progress | Ticks every **100 ms** by +0.0025 (one full track takes 40 s). Tap the bar to seek. |
| Lyrics | 8 lines, 44 dp each. Active line index = `floor(progress*8)`. The column translates so the active line sits in row 2, with a spring that overshoots slightly. Active line opacity is 1 at scale 1.04, neighbours .4, the rest .18. |

`H = [18,30,22,40,34,44,26,38,20,42,30,36,24,44,32,28,40,22,36,44,26,34,18,40,30,42,24,38,20,32,28,16]`

Tracks:

| title | artist | mono | accent | orbA | orbB | length |
|---|---|---|---|---|---|---|
| Neon Monsoon | Kavya & The Static | NM | `#C6F432` | `#5B4BFF` | `#C6F432` | 222 s |
| Paper Satellites | Low Orbit Club | PS | `#8B7CFF` | `#FF7A59` | `#8B7CFF` | 198 s |
| Saltwater Static | Mira Okafor | SS | `#FF7A59` | `#4FD1C5` | `#FF7A59` | 245 s |

Lyrics (original text):
1. City lights are melting in the rain
2. Every signal turning into gold
3. We ride the hum of the last train
4. Holding on to stories never told
5. Neon rivers running through the night
6. Your laugh is louder than the thunder
7. Count the seconds, hold the light
8. Let the monsoon pull us under

## 04 · Explore (shared-element expand)

Grid: 24 dp side padding, 12 dp gutter, column width `colW = (W − 60) / 2`, grid top `T = 200`.

| Card | x | y | h |
|---|---|---|---|
| Buran Ghati | 24 | T | 250 |
| Kedarkantha | 24+colW+12 | T | 200 |
| Hampta Pass | 24 | T+262 | 200 |
| Valley of Flowers | 24+colW+12 | T+212 | 250 |

**Opening card *i*** (all at **700 ms**, `cubic-bezier(.2,.9,.1,1)`, unless noted):
- The frame animates to the full screen: x, y, width, height, and corner radius 26 → 0.
- The other cards fade to 0 and scale to .88 over **350 ms**.
- The header fades out and moves up 20 dp.
- The mountain layers move up by −150 (far), −190 (mid) and −232 (near) dp over **900 ms**, with 0 / 50 / 100 ms delays. This is the parallax.
- The title animates left 14 → 24, top (h−62) → 84 and font size 18 → 38. Its colour switches to the card's `ink`.
- The sun grows 30 → 64 dp.
- The bottom sheet (452 dp tall, 32 dp top radius) slides up from below over **750 ms** after a 180 ms delay, with `cubic-bezier(.22,1,.36,1)`.
- Inside the sheet, each item fades in and rises 22 dp over 600 ms. The description starts at 450 ms. The stats start at 500, 570, 640 and 710 ms. The elevation card starts at 700 ms. The CTA starts at 850 ms.
- The elevation path draws in (stroke dash offset) over **1600 ms** after an 850 ms delay, with `cubic-bezier(.65,0,.35,1)`.
- The CTA has a shimmer: a 60 dp light band crosses it over 2400 ms, looping, starting at 1.4 s.
- The close and save buttons scale .6 → 1 at 450 and 550 ms.

**Closing** reverses the frame, siblings, header, parallax and title. The sheet disappears immediately.

Stars on Buran Ghati: 6 dots, opacity .2 ↔ 1, each with its own period (1.6 to 2.6 s).

| Trek | alt | days | grade | season | sky1 → sky2 | sun | m1 / m2 / m3 | ink | accent | profile (m) |
|---|---|---|---|---|---|---|---|---|---|---|
| Buran Ghati | 4,575 m | 8 | Hard | May–Jun | `#1B1F3B → #E07A5F` | `#FFD6A5` | `#5A3D5C / #3A2740 / #17111D` | white | `#FF9F80` | 2500,2800,3100,3300,3500,3700,4575,3900,3200,2600,2200 |
| Kedarkantha | 3,810 m | 6 | Easy | Dec–Apr | `#9EC5EA → #EAF2FA` | `#FFFFFF` | `#E6EEF6 / #7E96B2 / #22334A` | `#0B0B0F` | `#7FB5FF` | 1900,2400,2900,3200,3400,3810,3400,2900,2400,1900 |
| Hampta Pass | 4,270 m | 5 | Moderate | Jun–Sep | `#F6C177 → #F28C6B` | `#FFF1C9` | `#9A5B67 / #5E3448 / #22162A` | `#0B0B0F` | `#F6C177` | 2900,3200,3500,3700,4270,3800,3600,3900,3300 |
| Valley of Flowers | 3,658 m | 6 | Easy | Jul–Sep | `#BFE3CB → #F4F1DE` | `#FFF7D6` | `#8DB580 / #4E7A45 / #1F3A26` | `#0B0B0F` | `#9BD88A` | 1800,2200,3000,3300,3658,3400,3000,2600,2000 |

Mountain polygons are in a 0–100 viewBox, stretched to fill (no aspect ratio is kept). Each layer is anchored to the bottom of the card, and its height is a share of the card's height:
- far (70 %): `0,100 0,55 15,35 28,50 45,18 60,45 72,28 88,48 100,36 100,100`
- mid (50 %): `0,100 0,60 20,38 35,58 55,28 75,55 90,40 100,52 100,100`
- near (34 %): `0,100 0,48 25,28 50,52 70,34 100,58 100,100`
