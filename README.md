# motion-bench

The same two animation-heavy screens are built five times: in **React Native**, **Jetpack Compose (Kotlin)**, **SwiftUI** and **Flutter**, which are the baselines, and in **[Exact](https://github.com/expo/exact)**, Expo's new framework, which is the one under test. Each version uses that framework's idiomatic animation tools, so you can profile them side by side and see which one actually holds up.

| Screen | Why it's hard |
|---|---|
| **Player** | About 40 infinite animations at once (32 equaliser bars, spinning vinyl, drifting orbs, beat ring). One flag pauses or resumes all of them. A 10 Hz state update drives the progress bar and karaoke lyric scroll. Springs drive the tonearm and play button. |
| **Explore** | A shared-element expand: a masonry card animates its frame, corner radius, title size and three parallax mountain layers to full screen while the other cards fade out. Then a bottom sheet with staggered content and a self-drawing elevation chart. |

Every number (durations, curves, delays, colours, sizes) is in **[SPEC.md](SPEC.md)**, and all five apps follow it.

## Layout

```
SPEC.md            exact motion spec all apps follow
PROFILING.md       how to measure: Perfetto FrameTimeline (Android), Instruments hitches (iOS), result template
react-native/      Expo SDK 58 · RN 0.88 · Reanimated 4 · react-native-svg
android-compose/   Kotlin 2.2 · Compose BOM · JankStats
ios-swiftui/       SwiftUI, iOS 17+ · XcodeGen project spec
flutter/           Flutter 3.27+ · no third-party packages
exact/             Expo's Exact (pre-1.0) · Contract UI · UIKit on iOS, painted host on Android — see exact/README.md
traces/            put your .pftrace / .trace files here (git-ignored)
```

Each app has the same **bench bar** at the top:
- **Player / Explore** switches between the two screens.
- **Load 1×/4×** quadruples the equaliser bars and disc grooves.
- **Auto** makes Explore open and close cards in a fixed loop, so traces can be repeated.

## Run

> Always profile **release / profile builds** (see PROFILING.md). The commands below already do that.

**React Native**
```bash
cd react-native
npm install
npx expo run:android --variant release     # or: npx expo run:ios --configuration Release
```

**Jetpack Compose**
```bash
cd android-compose
gradle wrapper            # once, if you don't open it in Android Studio first
./gradlew installRelease
```

**SwiftUI**
```bash
brew install xcodegen
cd ios-swiftui && xcodegen && open MotionBench.xcodeproj
# Product → Profile (⌘I) builds Release and opens Instruments
```

**Exact** (Mac only to set up; full steps in `exact/README.md`)
```bash
git clone https://github.com/expo/exact ~/exact2 && (cd ~/exact2 && bun scripts/exact.mjs setup)
bun ~/exact2/scripts/exact.mjs new ~/motion-bench-exact --bundle-id dev.motionbench.exact --with ios,android
cp exact/{app.contract,app.test.contract,app.ts} ~/motion-bench-exact/ && cd ~/motion-bench-exact
bun exact.mjs test web && bun exact.mjs ios --run
```

**Flutter**
```bash
cd flutter
flutter create . --org dev.motionbench --project-name motion_bench --platforms android,ios
flutter run --profile
# Add the frame-graph overlay with: flutter run --profile --dart-define=PERF_OVERLAY=true
```

## How each framework drives the animations

Each version is written the way that framework is usually written. Don't port tricks from one to another, or the comparison stops being fair.

| | Continuous loops | One-shot / interruptible | Shared-element frame |
|---|---|---|---|
| RN | Reanimated `withRepeat` on the UI thread | `withTiming` / `withSpring`, custom `entering` worklets | `useAnimatedStyle` animating left/top/width/height |
| Compose | `Animatable` loops in `LaunchedEffect` | `animate*AsState`, springs | Custom `layout {}` modifier (reads state only in layout) |
| SwiftUI | `TimelineView(.animation(paused:))` plus pure functions of time | `.animation(_:value:)`, `interpolatingSpring`, `keyframeAnimator` | Implicit animation of `.frame` and `.offset` |
| Flutter | One `Ticker` → `ValueNotifier` → `ValueListenableBuilder` | `AnimationController` + `SpringSimulation`, `AnimatedSwitcher` | `Positioned.fromRect(Rect.lerp)` in `AnimatedBuilder` |
| Exact | CSS `@keyframes` (Core Animation plays them on Apple) | `transition` + `-exact-spring()`, root `task` timers | `-exact-layout-transition` |

## Status

- ✅ React Native typechecks (`npm run typecheck`).
- ⚠️ The Compose, SwiftUI, Flutter and Exact code was written without those toolchains on hand, so it has **not been compiled yet**. Expect a few small fixes on the first build.
- Exact's own documented motion rules force three deviations: during the shared-element expand the card's children jump to their final places, font size doesn't animate, and border radius doesn't animate. See `exact/README.md`. Those limits are part of what you're measuring.
- Known deviations from the spec:
  - Compose and SwiftUI have no skew on the CTA shimmer band.
  - Flutter's parallax layers reverse with the forward curve.
  - Fonts are system fonts everywhere.

The design reference is the "Framework Stress-Test Screens" canvas. Screens 01 (Wallet) and 03 (Activity) aren't implemented yet. They are good candidates for a second round.
