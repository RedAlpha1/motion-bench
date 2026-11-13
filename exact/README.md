# Exact (Expo) — Player + Explore

[Exact](https://github.com/expo/exact) is Expo's new framework, by Charlie Cheever, and is pre-1.0. You write the UI in **Contract**, a small declarative language. A Rust runner and a CSS layout kernel then draw it with **UIKit** on iOS, AppKit on macOS, the DOM on the web, and a painted host on Android (early support).

Here the Player and Explore screens follow `../SPEC.md`, written the way Exact intends:

| Spec element | How it's done in Exact |
|---|---|
| Infinite loops (disc, EQ bars, orbs, beat ring, stars) | CSS `@keyframes` → `animation`. On Apple, Core Animation plays them, so no engine frame is needed per tick. Pause = `animation-play-state` computed into the shorthand. |
| Springs (tonearm, lyric scroll, active line) | `transition="rotate -exact-spring(170, 12, 1)"` etc. |
| 10 Hz progress clock | Root `task tick when playing … every(100, step)` |
| Shared-element expand | `-exact-layout-transition` on the card frame (700 ms, `cubic-bezier(.2,.9,.1,1)`) |
| Staggered sheet, path draw, shimmer | Keyframes with delays. The path uses `pathLength=1` + `stroke-dashoffset` |
| Auto mode | Two gated root tasks: `after(900)` opens a card, `after(1600)` closes it |
| Tap-to-seek | `pointerdown` → `PointerEvent.offsetX / frame("seek").width` |

## Run it

Exact has no npm package or releases. An app uses a checkout of the repo by path. You need a Mac with Xcode, Rust, Bun and Chrome, plus the Android SDK if you want Android.

```bash
git clone https://github.com/expo/exact ~/exact2
cd ~/exact2 && bun scripts/exact.mjs setup           # once, a few minutes

bun ~/exact2/scripts/exact.mjs new ~/motion-bench-exact \
  --name MotionBench --bundle-id dev.motionbench.exact --with ios,android
cp <this repo>/exact/{app.contract,app.test.contract,app.ts} ~/motion-bench-exact/
cd ~/motion-bench-exact

bun exact.mjs contract build app.contract --json --errors-only   # [] = compiles
bun exact.mjs test web                                           # runs app.test.contract
bun exact.mjs ios --run                                          # simulator; the first build takes 10-15 min
```

**Profiling build** (release, as for every other framework):

```bash
DEVELOPMENT_TEAM=<team-id> bun exact.mjs ios --device --phone <udid> --release   # real iPhone → Instruments
EXACT_UPDATE_TRUST=production bun exact.mjs android --release                    # APK → Perfetto
```

`app.json` from `exact new` needs `"deploy": { "store": { "ios": "0", "linux": "0" } }` for a release without an update server (see Exact's `docs/recipes/mobile-build.md`).

## Measuring

- **iOS:** Instruments → Animation Hitches, exactly as in `../PROFILING.md`. Exact draws with UIKit, so the same template applies.
- **Android:** Perfetto FrameTimeline with `--app dev.motionbench.exact`. Exact's Android host is the newest one, so expect rough edges and record them.
- **Exact's own tools** cover what the others can't do:
  - `bun exact.mjs agent ios "tap tab-explore" "tap auto" "screenshot .exact/e1.png over 3000 every 50"` films motion on a virtual clock, so you get a contact sheet with no timing flakes.
  - `perf <target> during "<op>"` measures a subtree's work for one operation.
  - A development build writes a trace from the iOS dev menu (**Save Trace**), and `bun ~/exact2/scripts/agent.mjs trace --phone` copies it off the phone.

## Known differences from the spec

These come from Exact's documented motion rules (`docs/recipes/motion.md`), not from shortcuts:

1. **The shared-element children jump.** A layout transition moves and resizes the card's *surface*, and its laid-out children take their final places at once. To compensate, the title, subtitle and mountain layers ride on their own `translate`/`scale` transitions, and the sun uses `scale`. The sun's position and the mountains' height (both percentages of the card) still jump. This is the most important finding for this framework: watch it in E1.
2. **Font size doesn't animate.** The card title is drawn at 38 and scaled 0.4737 → 1.
3. **Border radius doesn't animate.** The play button's 28 ↔ 40 radius and the card's 26 → 0 corners jump.
4. No exit animation is used for the sheet. That matches the spec, where the sheet disappears immediately.
5. The EQ bars use a two-value `scale` ("1 0.12"). If the compiler refuses it, use `scale=0.12` on a box with `transform-origin="50% 100%"`.

## Status

⚠️ **Not compiled yet.** I wrote this from Exact's guides and its example apps (`motion-gallery`, `shared-elements`, `sparkline`, `svg-gallery`), but couldn't build Exact's compiler here. The first `contract build` will probably report a few errors. It names each one and says what to write instead, so expect a short fix loop. Exact asks you to report anything confusing with `bun exact.mjs feedback note "…"`.
