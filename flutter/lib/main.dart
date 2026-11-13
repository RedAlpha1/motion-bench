import 'package:flutter/material.dart';

import 'explore_screen.dart';
import 'player_screen.dart';
import 'theme.dart';

void main() => runApp(const MotionBenchApp());

class MotionBenchApp extends StatelessWidget {
  const MotionBenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motion Bench Flutter',
      debugShowCheckedModeBanner: false,
      // Set to true to draw Flutter's raster/UI frame graphs over the app.
      showPerformanceOverlay: const bool.fromEnvironment('PERF_OVERLAY'),
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: C.bg, useMaterial3: true),
      home: const Root(),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  String screen = 'player';
  Bench bench = const Bench();

  Widget pill(String label, bool on, VoidCallback onTap) => Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? C.text : C.bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? C.text : C.border),
            ),
            child: Text(label, style: TextStyle(color: on ? C.bg : C.soft, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              pill('Player', screen == 'player', () => setState(() => screen = 'player')),
              const SizedBox(width: 6),
              pill('Explore', screen == 'explore', () => setState(() => screen = 'explore')),
              const Spacer(),
              pill('Load ${bench.load}×', bench.load == 4, () => setState(() => bench = bench.copyWith(load: bench.load == 1 ? 4 : 1))),
              const SizedBox(width: 6),
              pill('Auto', bench.auto, () => setState(() => bench = bench.copyWith(auto: !bench.auto))),
            ]),
          ),
          Container(height: 1, color: C.border),
          Expanded(
            child: ClipRect(
              child: screen == 'player' ? PlayerScreen(bench: bench) : ExploreScreen(bench: bench),
            ),
          ),
        ]),
      ),
    );
  }
}
