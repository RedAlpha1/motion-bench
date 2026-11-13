# motion-bench

The same two animation-heavy screens are built four times, in **React Native**, **Jetpack Compose (Kotlin)**, **SwiftUI** and **Flutter**. Each version uses that framework's idiomatic animation tools, so you can profile them side by side and see which one actually holds up.

| Screen | Why it's hard |
|---|---|
| **Player** | About 40 infinite animations at once (32 equaliser bars, spinning vinyl, drifting orbs, beat ring). One flag pauses or resumes all of them. A 10 Hz state update drives the progress bar and karaoke lyric scroll. Springs drive the tonearm and play button. |
| **Explore** | A shared-element expand: a masonry card animates its frame, corner radius, title size and three parallax mountain layers to full screen while the other cards fade out. Then a bottom sheet with staggered content and a self-drawing elevation chart. |

Every number (durations, curves, delays, colours, sizes) is in **[SPEC.md](SPEC.md)**, and all four apps follow it.

## Layout

```
SPEC.md            exact motion spec all apps follow
PROFILING.md       how to measure: Perfetto FrameTimeline (Android), Instruments hitches (iOS), result template
react-native/      Expo SDK 58 · RN 0.88 · Reanimated 4 · react-native-svg
android-compose/   Kotlin 2.2 · Compose BOM · JankStats
ios-swiftui/       SwiftUI, iOS 17+ · XcodeGen project spec
flutter/           Flutter 3.27+ · no third-party packages
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

## Status

- ✅ React Native typechecks (`npm run typecheck`).
- ⚠️ The Compose, SwiftUI and Flutter code was written without those toolchains on hand, so it has **not been compiled yet**. Expect a few small fixes on the first build.
- Known deviations from the spec:
  - Compose and SwiftUI have no skew on the CTA shimmer band.
  - Flutter's parallax layers reverse with the forward curve.
  - Fonts are system fonts everywhere.

The design reference is the "Framework Stress-Test Screens" canvas. Screens 01 (Wallet) and 03 (Activity) aren't implemented yet. They are good candidates for a second round.
