import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import 'theme.dart';

// Every continuous loop is a pure function of "play time", so pausing freezes
// everything in place and resuming continues from the same frame.
double _easeIO(double x) => x < .5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;
double _pingPong(double t, double dur) {
  final c = t / dur;
  final k = c.floor();
  final f = c - k;
  return _easeIO(k.isEven ? f : 1 - f);
}

Offset _orbOffset(double t, double dur, Offset mid, Offset end) {
  final half = dur / 2;
  final c = (t / half) % 4;
  final leg = c.floor();
  final f = _easeIO(c - leg);
  final pts = [Offset.zero, mid, end, mid, Offset.zero];
  return Offset.lerp(pts[leg], pts[leg + 1], f)!;
}

/// A value driven by a spring simulation (Flutter has no spring "to" helper).
class SpringValue {
  SpringValue(TickerProvider vsync, double initial, this.desc)
      : c = AnimationController.unbounded(vsync: vsync, value: initial);
  final AnimationController c;
  final SpringDescription desc;
  void to(double target) => c.animateWith(SpringSimulation(desc, c.value, target, c.velocity));
  void dispose() => c.dispose();
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.bench});
  final Bench bench;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  bool playing = true;
  double progress = 0.06;
  int track = 0;
  bool liked = false;

  final playTime = ValueNotifier<double>(0);
  double _acc = 0;
  late final Ticker _ticker;
  late final Timer _tick;
  late final SpringValue arm;
  late final SpringValue playRadius;
  late final SpringValue lyY;
  late final AnimationController pop;

  Track get t => tracks[track];
  int get idx => math.min(lyrics.length - 1, (progress * lyrics.length).floor());

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => playTime.value = _acc + e.inMicroseconds / 1e6)..start();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!playing) return;
      setState(() {
        if (progress + .0025 >= 1) {
          track = (track + 1) % 3;
          progress = 0;
        } else {
          progress += .0025;
        }
      });
      lyY.to(44.0 - idx * 44);
    });
    arm = SpringValue(this, 22, const SpringDescription(mass: 1, stiffness: 170, damping: 12));
    playRadius = SpringValue(this, 28, const SpringDescription(mass: 1, stiffness: 220, damping: 14));
    lyY = SpringValue(this, 44, const SpringDescription(mass: 1, stiffness: 140, damping: 14));
    pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.cancel();
    arm.dispose();
    playRadius.dispose();
    lyY.dispose();
    pop.dispose();
    super.dispose();
  }

  void togglePlay() {
    setState(() {
      if (playing) {
        _acc = playTime.value;
        _ticker.stop();
      } else {
        _ticker.start();
      }
      playing = !playing;
    });
    arm.to(playing ? 22 : 0);
    playRadius.to(playing ? 28 : 40);
  }

  void go(int dir) {
    setState(() {
      track = (track + dir + 3) % 3;
      progress = 0;
    });
    lyY.to(44);
  }

  String fmt(double s) => '${s ~/ 60}:${(s % 60).floor().toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: t.color),
      duration: const Duration(milliseconds: 800),
      builder: (context, accent, _) {
        final a = accent ?? t.color;
        return LayoutBuilder(builder: (context, box) {
          return Stack(clipBehavior: Clip.hardEdge, children: [
            _orbs(box.maxWidth),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(children: [
                _disc(a),
                const SizedBox(height: 16),
                _titleRow(),
                const SizedBox(height: 16),
                _eq(a),
                const SizedBox(height: 16),
                _seek(a),
                const SizedBox(height: 16),
                _controls(a),
                const SizedBox(height: 16),
                Expanded(child: _lyrics()),
              ]),
            ),
          ]);
        });
      },
    );
  }

  Widget _orb(Color c, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c.withValues(alpha: .5), c.withValues(alpha: 0)])),
      );

  Widget _orbs(double w) {
    return IgnorePointer(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: t.orbA),
        duration: const Duration(seconds: 1),
        builder: (context, ca, _) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: t.orbB),
          duration: const Duration(seconds: 1),
          builder: (context, cb, _) => ValueListenableBuilder<double>(
            valueListenable: playTime,
            builder: (context, tt, _) {
              final oa = _orbOffset(tt, 11, const Offset(60, 40), const Offset(-30, 90));
              final ob = _orbOffset(tt, 13, const Offset(-70, -30), const Offset(20, -80));
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(left: -120 + oa.dx, top: -60 + oa.dy, child: _orb(ca ?? t.orbA, 320)),
                Positioned(left: w - 170 + ob.dx, top: 260 + ob.dy, child: _orb(cb ?? t.orbB, 280)),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _disc(Color a) {
    return SizedBox(
      width: 268,
      height: 268,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        ValueListenableBuilder<double>(
          valueListenable: playTime,
          builder: (context, tt, _) {
            final b = _pingPong(tt, .47);
            return OverflowBox(
              maxWidth: 296,
              maxHeight: 296,
              child: Opacity(
                opacity: .45 + .4 * b,
                child: Transform.scale(
                  scale: .96 + .1 * b,
                  child: Container(width: 296, height: 296, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: a, width: 2))),
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<double>(
          valueListenable: playTime,
          child: RepaintBoundary(
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(size: const Size(268, 268), painter: _DiscPainter(widget.bench.load)),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(shape: BoxShape.circle, color: a),
                alignment: Alignment.center,
                child: Stack(alignment: Alignment.center, children: [
                  Text(t.mono, style: const TextStyle(color: C.bg, fontSize: 24, fontWeight: FontWeight.w700)),
                  Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: C.bg)),
                ]),
              ),
            ]),
          ),
          builder: (context, tt, child) => Transform.rotate(angle: (tt / 5 % 1) * 2 * math.pi, child: child),
        ),
        Positioned(
          left: 192,
          top: -26,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: arm.c,
              child: CustomPaint(size: const Size(120, 170), painter: _ArmPainter()),
              builder: (context, child) => Transform.rotate(
                angle: arm.c.value * math.pi / 180,
                alignment: const FractionalOffset(96 / 120, 22 / 170),
                child: child,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _titleRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            reverseDuration: Duration.zero,
            switchInCurve: easeSheet,
            layoutBuilder: (cur, prev) => Stack(alignment: Alignment.centerLeft, children: [if (cur != null) cur]),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: AnimatedBuilder(
                animation: anim,
                child: child,
                builder: (context, c) => Transform.translate(offset: Offset(0, 14 * (1 - anim.value)), child: c),
              ),
            ),
            child: Column(
              key: ValueKey(track),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: const TextStyle(color: C.text, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(t.artist, style: const TextStyle(color: Color(0xFFA3A3AF), fontSize: 14)),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: liked ? 'Remove from liked songs' : 'Add to liked songs',
          child: GestureDetector(
            onTap: () {
              setState(() => liked = !liked);
              pop.forward(from: 0);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)),
              child: ScaleTransition(
                scale: TweenSequence([
                  TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 180),
                  TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0).chain(CurveTween(curve: easeBack)), weight: 270),
                ]).animate(pop),
                child: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? C.heart : C.soft, size: 22),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _eq(Color a) {
    final n = 32 * widget.bench.load;
    final w = widget.bench.load == 4 ? 2.0 : 5.0;
    return SizedBox(
      height: 44,
      child: ValueListenableBuilder<double>(
        valueListenable: playTime,
        builder: (context, tt, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(n, (i) {
            final dur = .32 + ((i * 37) % 23) / 40;
            final phase = ((i * 53) % 17) / 20;
            final s = .12 + .88 * _pingPong(tt + phase * dur, dur);
            final c = i % 3 == 0 ? a : (i % 3 == 1 ? C.text.withValues(alpha: .55) : C.text.withValues(alpha: .25));
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(1, s, 1),
              child: Container(width: w, height: barH[i % 32], decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            );
          }),
        ),
      ),
    );
  }

  Widget _seek(Color a) {
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => setState(() => progress = (d.localPosition.dx / w).clamp(0, .999)),
          child: SizedBox(
            height: 22,
            child: Stack(alignment: Alignment.centerLeft, clipBehavior: Clip.none, children: [
              Container(height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(5))),
              Container(width: w * progress, height: 5, decoration: BoxDecoration(color: a, borderRadius: BorderRadius.circular(5))),
              Positioned(
                left: w * progress - 8,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: C.text)),
              ),
            ]),
          ),
        );
      }),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(fmt(progress * t.len), style: const TextStyle(color: C.muted, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
        Text(fmt(t.len), style: const TextStyle(color: C.muted, fontSize: 12)),
      ]),
    ]);
  }

  Widget _iconButton(IconData icon, String label, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(width: 56, height: 56, child: Icon(icon, color: C.text, size: 34)),
        ),
      );

  Widget _controls(Color a) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _iconButton(Icons.skip_previous_rounded, 'Previous track', () => go(-1)),
      const SizedBox(width: 36),
      Semantics(
        button: true,
        label: playing ? 'Pause' : 'Play',
        child: GestureDetector(
          onTap: togglePlay,
          child: AnimatedBuilder(
            animation: playRadius.c,
            builder: (context, child) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: a, borderRadius: BorderRadius.circular(playRadius.c.value)),
              alignment: Alignment.center,
              child: child,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              reverseDuration: Duration.zero,
              switchInCurve: easeBack,
              transitionBuilder: (child, anim) => AnimatedBuilder(
                animation: anim,
                child: child,
                builder: (context, c) {
                  final v = anim.value;
                  return Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.rotate(angle: -math.pi / 2 * (1 - v), child: Transform.scale(scale: .4 + .6 * v, child: c)),
                  );
                },
              ),
              child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, key: ValueKey(playing), color: C.bg, size: 36),
            ),
          ),
        ),
      ),
      const SizedBox(width: 36),
      _iconButton(Icons.skip_next_rounded, 'Next track', () => go(1)),
    ]);
  }

  Widget _lyrics() {
    final i0 = idx;
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: lyY.c,
        builder: (context, child) => Transform.translate(offset: Offset(0, lyY.c.value), child: child),
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < lyrics.length; i++)
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        opacity: (i - i0).abs() == 0 ? 1 : ((i - i0).abs() == 1 ? .4 : .18),
                        duration: const Duration(milliseconds: 500),
                        child: AnimatedScale(
                          scale: i == i0 ? 1.04 : 1,
                          alignment: Alignment.centerLeft,
                          duration: const Duration(milliseconds: 500),
                          curve: easeBack,
                          child: Text(
                            lyrics[i],
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: TextStyle(color: i == i0 ? Colors.white : C.soft, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscPainter extends CustomPainter {
  _DiscPainter(this.load);
  final int load;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2, Paint()..color = const Color(0xFF15151B));
    final n = 24 * load;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < n; i++) {
      p.color = i.isOdd ? const Color(0xFF1E1E27) : const Color(0xFF111116);
      canvas.drawCircle(c, 40 + 92 * i / (n - 1), p);
    }
    canvas.drawArc(Rect.fromCircle(center: c, radius: size.width / 2), -50 * math.pi / 180, 22 * math.pi / 180, true,
        Paint()..color = Colors.white.withValues(alpha: .06));
  }

  @override
  bool shouldRepaint(_DiscPainter old) => old.load != load;
}

class _ArmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(96, 22)
      ..lineTo(90, 120)
      ..lineTo(62, 150);
    canvas.drawPath(
        path,
        Paint()
          ..color = C.soft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.save();
    canvas.translate(61, 149);
    canvas.rotate(-40 * math.pi / 180);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-13, -9, 26, 18), const Radius.circular(4)), Paint()..color = const Color(0xFFE9E9EF));
    canvas.restore();
    canvas.drawCircle(const Offset(96, 22), 16, Paint()..color = const Color(0xFF23232D));
    canvas.drawCircle(
        const Offset(96, 22),
        16,
        Paint()
          ..color = const Color(0xFF3A3A47)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(const Offset(96, 22), 6, Paint()..color = const Color(0xFF6E6E7A));
  }

  @override
  bool shouldRepaint(_ArmPainter old) => false;
}
