# Profiling playbook

The aim is to compare the **same motion** across frameworks, so the method matters more than any one number. Follow this exactly for every framework.

## Ground rules

1. **Profile release builds, never debug.** Debug Compose, debug RN (with Metro), and Flutter debug (JIT) are all several times slower than what ships.
   - React Native: `npx expo run:android --variant release` or `npx expo run:ios --configuration Release`
   - Compose: `./gradlew installRelease` (it is signed with the debug key so it installs without setup)
   - SwiftUI: in Xcode press Product → Profile (⌘I), which builds Release
   - Flutter: `flutter run --profile`. Profile mode is AOT with tracing, as close to release as you can trace.
2. **Use the same device every time.** Run each Android framework on one mid-range phone, not a flagship. Weak GPUs are where the frameworks differ. Write down the device model, OS version and refresh rate.
3. **Fix the refresh rate.** Lock the display to 60 Hz (or 120 Hz) in developer options for the whole session.
4. Charge the battery above 50 %. Turn off battery saver. Let the phone cool between runs.
5. **Run every scenario 3 times** and report the median.

## Scenarios

| ID | Screen | Load | Auto | Duration | What it isolates |
|---|---|---|---|---|---|
| P1 | Player | 1× | – | 30 s | Many simultaneous infinite animations plus a 10 Hz state update |
| P2 | Player | 4× | – | 30 s | How that scales: 128 bars and 96 grooves |
| P3 | Player | 1× | – | 20 s | Tap play/pause every 2 s: pause/resume cost and spring interruption |
| E1 | Explore | 1× | on | 30 s | About 12 shared-element expand/collapse cycles plus the staggered sheet. This is the hardest test. |
| E2 | Explore | 1× | off | manual | Open a card, close it mid-animation, open another. Check that interruption is clean. |
| S | – | – | – | – | Cold start time (see below) |

## Android: one method for every framework (Perfetto FrameTimeline)

`dumpsys gfxinfo` only sees frames drawn by the system UI renderer (HWUI), so it misses Flutter's frames. **Perfetto FrameTimeline** is measured at SurfaceFlinger, which covers every app whatever renders it. It needs Android 12 or later.

```bash
# 1. Record (start the scenario on the phone right after running this)
adb shell perfetto -o /data/misc/perfetto-traces/mb.pftrace -t 30s \
  sched freq gfx view am wm dalvik input \
  --app dev.motionbench.compose        # use the package of the app under test
adb pull /data/misc/perfetto-traces/mb.pftrace traces/compose-E1-run1.pftrace
```

The `--app` flag also enables app-level atrace (Compose and RN tracing sections). Open the trace at <https://ui.perfetto.dev>, or query it:

```sql
-- Paste into the Query (SQL) tab in ui.perfetto.dev
SELECT p.name                                         AS app,
       COUNT(*)                                       AS frames,
       SUM(a.jank_type != 'None')                     AS janky_frames,
       ROUND(100.0 * SUM(a.jank_type != 'None') / COUNT(*), 2) AS jank_pct,
       ROUND(AVG(a.dur) / 1e6, 2)                     AS avg_frame_ms,
       ROUND(MAX(a.dur) / 1e6, 2)                     AS worst_frame_ms
FROM actual_frame_timeline_slice a
JOIN process p USING (upid)
WHERE p.name LIKE 'dev.motionbench%'
GROUP BY p.name;
```

Package names:

| App | Package / activity |
|---|---|
| React Native | `dev.motionbench.rn/.MainActivity` |
| Compose | `dev.motionbench.compose/.MainActivity` |
| Flutter | `dev.motionbench.motion_bench/.MainActivity` (after `flutter create --org dev.motionbench`) |

### Other numbers to collect

```bash
# Cold start (3 runs; kill the app between runs)
adb shell am force-stop <pkg> && adb shell am start -W -n <pkg>/.MainActivity | grep TotalTime

# Memory after 30 s on P2 (look at TOTAL PSS)
adb shell dumpsys meminfo <pkg> | grep -E "TOTAL PSS|TOTAL:"

# CPU while running P2 (average the app's %CPU over ~10 samples)
adb shell top -d 1 -n 10 | grep motionbench

# APK size (release)
ls -lh <path-to-release.apk>
```

### What each framework shows you inside the trace

- **Compose:** `Recomposer:recompose`, `Compose:measure` and `Compose:draw` slices. JankStats also logs janky frames to logcat (`adb logcat -s MotionBench`). On Explore, look for recomposition every frame. The frame size is read only during layout, so if you see a recomposition on every frame, that is a finding.
- **React Native:** separate the JS thread (`mqt_v_js` / `mqt_js`) from the UI thread. Reanimated animations should run with *no* JS activity. The 10 Hz progress timer is deliberately on JS, so you should see small spikes every 100 ms. Large JS slices during the Explore expand mean a worklet is not on the UI thread.
- **Flutter:** `1.ui` (build/layout) and `1.raster` (GPU) threads. For more detail use `flutter run --profile` and DevTools → Performance. Raster-thread spikes on Explore usually come from `ClipRRect` + `BackdropFilter`.

## iOS (SwiftUI, React Native, Flutter)

Use **Instruments → Animation Hitches** on a physical device. The simulator gives you meaningless numbers.

```bash
# Command line version (Xcode 15+). The app must already be installed and running.
xcrun xctrace record --template 'Animation Hitches' --device <UDID> \
  --attach 'MotionBench' --time-limit 30s --output traces/swiftui-E1-run1.trace
```

Record these:
- **Hitch time ratio** (ms of hitch per second). Under 5 ms/s is good, 5–10 is noticeable and over 10 is bad.
- **Number of hitches** and the longest hitch.
- Whether hitches are **commit** hitches (the app took too long) or **render** hitches (the render server or GPU took too long).
- For SwiftUI, add the **SwiftUI** instrument to count view body evaluations. The Player redraws its TimelineView subtrees every frame, and the count shows what that costs.

## Results template

Copy this into `RESULTS.md` once per device.

```
Device: ________  OS: ____  Refresh: __ Hz  Date: ____

| Scenario | Metric            | RN | Compose | SwiftUI | Flutter |
|----------|-------------------|----|---------|---------|---------|
| P1       | jank % / hitch ms/s |    |         |         |         |
| P2       | jank % / hitch ms/s |    |         |         |         |
| P2       | CPU % (avg)       |    |         |         |         |
| P2       | Memory PSS (MB)   |    |         |         |         |
| P3       | worst frame (ms)  |    |         |         |         |
| E1       | jank % / hitch ms/s |    |         |         |         |
| E1       | worst frame (ms)  |    |         |         |         |
| E2       | interruption clean? (y/n) |  |      |         |         |
| S        | cold start (ms)   |    |         |         |         |
| –        | release size (MB) |    |         |         |         |
| –        | lines of code (2 screens) |  |    |         |         |
```

Lines of code are worth recording, because developer cost is part of the answer:

```bash
find react-native/src react-native/App.tsx -name '*.ts*' | xargs wc -l | tail -1
find android-compose/app/src -name '*.kt' | xargs wc -l | tail -1
find ios-swiftui/MotionBench -name '*.swift' | xargs wc -l | tail -1
find flutter/lib -name '*.dart' | xargs wc -l | tail -1
```
