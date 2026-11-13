import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'theme.dart';

const _gridTop = 200.0;
const _chips = ['All', 'Himachal', 'Uttarakhand', 'Winter', 'Beginner'];

double _lerp(double a, double b, double t) => a + (b - a) * t;

class _Polygon extends CustomPainter {
  _Polygon(this.pts, this.color);
  final List<double> pts;
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..moveTo(pts[0] / 100 * s.width, pts[1] / 100 * s.height);
    for (var i = 2; i < pts.length; i += 2) {
      p.lineTo(pts[i] / 100 * s.width, pts[i + 1] / 100 * s.height);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Polygon o) => o.color != color;
}

class _Star extends StatefulWidget {
  const _Star(this.x, this.y, this.size, this.periodMs, this.delayMs);
  final double x, y, size;
  final int periodMs, delayMs;
  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.periodMs ~/ 2));
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.delayMs), () => c.repeat(reverse: true));
  }

  @override
  void dispose() {
    _t?.cancel();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: FractionalOffset(widget.x, widget.y),
        child: FadeTransition(
          opacity: Tween(begin: .2, end: 1.0).animate(CurvedAnimation(parent: c, curve: easeInOut)),
          child: Container(width: widget.size, height: widget.size, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
        ),
      );
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.bench});
  final Bench bench;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  int open = -1;
  int morphing = -1; // the card that is (or was last) expanding
  int chip = 0;
  int _autoGen = 0;

  late final frame = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  late final parallax = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final header = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  late final frameT = CurvedAnimation(parent: frame, curve: easeFrame, reverseCurve: easeFrame.flipped);
  late final pl1 = CurvedAnimation(parent: parallax, curve: const Interval(0, .9, curve: easeFrame));
  late final pl2 = CurvedAnimation(parent: parallax, curve: const Interval(.05, .95, curve: easeFrame));
  late final pl3 = CurvedAnimation(parent: parallax, curve: const Interval(.1, 1, curve: easeFrame));
  late final headerT = CurvedAnimation(parent: header, curve: easeSheet);

  @override
  void initState() {
    super.initState();
    if (widget.bench.auto) _runAuto();
  }

  @override
  void didUpdateWidget(ExploreScreen old) {
    super.didUpdateWidget(old);
    if (old.bench.auto != widget.bench.auto) {
      _autoGen++;
      if (widget.bench.auto) {
        _runAuto();
      } else {
        setOpen(-1);
      }
    }
  }

  Future<void> _runAuto() async {
    final gen = ++_autoGen;
    var i = 0;
    while (mounted && gen == _autoGen) {
      setOpen(i);
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted || gen != _autoGen) return;
      setOpen(-1);
      await Future.delayed(const Duration(milliseconds: 900));
      i = (i + 1) % treks.length;
    }
  }

  void setOpen(int i) {
    setState(() {
      open = i;
      if (i >= 0) morphing = i;
    });
    if (i >= 0) {
      frame.forward();
      fade.forward();
      parallax.forward();
      header.forward();
    } else {
      frame.reverse();
      fade.reverse();
      parallax.reverse();
      header.reverse();
    }
  }

  @override
  void dispose() {
    _autoGen++;
    for (final c in [frame, fade, parallax, header]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final full = Size(box.maxWidth, box.maxHeight);
      final order = [for (var i = 0; i < treks.length; i++) if (i != morphing) i, if (morphing >= 0) morphing];
      return Stack(children: [
        _header(),
        for (final i in order) _card(i, full),
        if (open >= 0) _Sheet(key: ValueKey(open), k: treks[open], onClose: () => setOpen(-1)),
      ]);
    });
  }

  Widget _header() {
    return AnimatedBuilder(
      animation: headerT,
      builder: (context, child) => Opacity(
        opacity: 1 - headerT.value,
        child: Transform.translate(offset: Offset(0, -20 * headerT.value), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('HIMALAYA · WINTER 2026', style: TextStyle(color: C.muted, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          const Text('Explore treks', style: TextStyle(color: C.text, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
            alignment: Alignment.centerLeft,
            child: const TextField(
              style: TextStyle(color: C.text, fontSize: 15),
              decoration: InputDecoration.collapsed(
                hintText: 'Search treks, passes, regions',
                hintStyle: TextStyle(color: Color(0xFF8C8C99)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var i = 0; i < _chips.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => chip = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == chip ? C.text : const Color(0xFF121218),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: i == chip ? C.text : const Color(0xFF23232D)),
                      ),
                      child: Text(_chips[i], style: TextStyle(color: i == chip ? C.bg : C.soft, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _layer(List<double> pts, double frac, double lift, Animation<double> a, Color color) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: frac,
            widthFactor: 1,
            child: AnimatedBuilder(
              animation: a,
              builder: (context, child) => Transform.translate(offset: Offset(0, -lift * a.value), child: child),
              child: CustomPaint(painter: _Polygon(pts, color)),
            ),
          ),
        ),
      );

  Widget _card(int i, Size full) {
    final k = treks[i];
    final colW = (full.width - 60) / 2;
    final rect = Rect.fromLTWH(24 + k.col * (colW + 12), _gridTop + k.dy, colW, k.h);
    final isMorph = i == morphing;
    final zero = const AlwaysStoppedAnimation(0.0);

    return AnimatedBuilder(
      animation: Listenable.merge([frameT, fade]),
      builder: (context, _) {
        final t = isMorph ? frameT.value : 0.0;
        final f = (open >= 0 && i != open) ? fade.value : (open < 0 && !isMorph ? fade.value : 0.0);
        final r = Rect.lerp(rect, Offset.zero & full, t)!;
        final ink = Color.lerp(Colors.white, k.ink, t)!;
        final sun = _lerp(30, 64, t);
        return Positioned.fromRect(
          rect: r,
          child: Opacity(
            opacity: 1 - f,
            child: Transform.scale(
              scale: 1 - .12 * f,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26 * (1 - t)),
                child: Stack(children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [k.sky1, k.sky2])),
                    ),
                  ),
                  if (k.night)
                    const Positioned.fill(
                      child: Stack(children: [
                        _Star(.18, .09, 3, 2100, 0),
                        _Star(.42, .05, 2, 1600, 400),
                        _Star(.70, .13, 3, 2600, 900),
                        _Star(.86, .06, 2, 1900, 200),
                        _Star(.30, .18, 2, 2300, 1100),
                        _Star(.58, .22, 2, 1700, 700),
                      ]),
                    ),
                  Positioned(
                    left: r.width * (.6 + .08 * t),
                    top: r.height * (.14 + .01 * t),
                    child: Container(
                      width: sun,
                      height: sun,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: k.sun,
                        boxShadow: [BoxShadow(color: k.sun.withValues(alpha: .6), blurRadius: 30, spreadRadius: 6)],
                      ),
                    ),
                  ),
                  _layer(far, .70, 150, isMorph ? pl1 : zero, k.m1),
                  _layer(mid, .50, 190, isMorph ? pl2 : zero, k.m2),
                  _layer(near, .34, 232, isMorph ? pl3 : zero, k.m3),
                  Positioned(
                    left: _lerp(14, 24, t),
                    top: _lerp(k.h - 62, 84, t),
                    right: 14,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(k.name, style: TextStyle(color: ink, fontSize: _lerp(18, 38, t), height: 1.05, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${k.alt} · ${k.days}', style: TextStyle(color: ink.withValues(alpha: .85), fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  if (open < 0)
                    Positioned.fill(
                      child: Semantics(
                        button: true,
                        label: 'Open ${k.name}',
                        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setOpen(i)),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet + floating buttons. One 2450 ms timeline; every staggered item is an Interval on it.
class _Sheet extends StatefulWidget {
  const _Sheet({super.key, required this.k, required this.onClose});
  final Trek k;
  final VoidCallback onClose;
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> with TickerProviderStateMixin {
  static const total = 2450.0;
  late final tl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2450))..forward();
  late final shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  Timer? _t;

  Animation<double> at(int delayMs, int durMs, Curve curve) =>
      CurvedAnimation(parent: tl, curve: Interval(delayMs / total, (delayMs + durMs) / total, curve: curve));

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1400), () => shimmer.repeat());
  }

  @override
  void dispose() {
    _t?.cancel();
    tl.dispose();
    shimmer.dispose();
    super.dispose();
  }

  Widget rise(int delay, Widget child) {
    final a = at(delay, 600, easeSheet);
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, c) => Opacity(opacity: a.value, child: Transform.translate(offset: Offset(0, 22 * (1 - a.value)), child: c)),
    );
  }

  Widget popIn(int delay, Widget child) {
    final a = at(delay, 400, easeBack);
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, c) => Opacity(opacity: a.value.clamp(0.0, 1.0), child: Transform.scale(scale: .6 + .4 * a.value, child: c)),
    );
  }

  Widget roundBtn(IconData icon, String label, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(width: 44, height: 44, color: C.bg.withValues(alpha: .55), child: Icon(icon, color: Colors.white, size: 20)),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final k = widget.k;
    final up = at(180, 750, easeSheet);
    final draw = at(850, 1600, easeDraw);
    const box = BoxDecoration(color: C.surface, borderRadius: BorderRadius.all(Radius.circular(16)), border: Border.fromBorderSide(BorderSide(color: C.border)));

    return Stack(children: [
      Positioned(
        top: 24,
        left: 24,
        right: 24,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          popIn(450, roundBtn(Icons.close_rounded, 'Close trek details', widget.onClose)),
          popIn(550, roundBtn(Icons.bookmark_border_rounded, 'Save trek', () {})),
        ]),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 452,
        child: AnimatedBuilder(
          animation: up,
          builder: (context, c) => Transform.translate(offset: Offset(0, 480 * (1 - up.value)), child: c),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            decoration: const BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF2A2A36), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              rise(450, Text(k.blurb, style: const TextStyle(color: Color(0xFFB8B8C4), fontSize: 14, height: 1.5))),
              const SizedBox(height: 16),
              Row(children: [
                for (final (j, kv) in [('ALTITUDE', k.alt), ('DURATION', k.days), ('GRADE', k.diff), ('SEASON', k.season)].indexed) ...[
                  if (j > 0) const SizedBox(width: 8),
                  Expanded(
                    child: rise(
                      500 + j * 70,
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: box,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(kv.$1, style: const TextStyle(color: C.muted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(kv.$2, style: const TextStyle(color: C.text, fontSize: 14, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 16),
              rise(
                700,
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: box.copyWith(borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Elevation profile', style: TextStyle(color: C.muted, fontSize: 12)),
                      Text('${k.alt} summit', style: const TextStyle(color: C.muted, fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 84,
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: draw,
                        builder: (context, _) => CustomPaint(painter: _ElevationPainter(k.prof, k.accent, draw.value)),
                      ),
                    ),
                  ]),
                ),
              ),
              const Spacer(),
              rise(
                850,
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 56,
                    color: C.lime,
                    child: LayoutBuilder(
                      builder: (context, bx) => Stack(alignment: Alignment.center, children: [
                        AnimatedBuilder(
                          animation: shimmer,
                          builder: (context, c) => Positioned(
                            left: _lerp(-100, bx.maxWidth + 20, easeInOut.transform(shimmer.value)),
                            top: -10,
                            bottom: -10,
                            child: Transform(transform: Matrix4.skewX(-.35), child: c),
                          ),
                          child: Container(width: 60, color: Colors.white.withValues(alpha: .45)),
                        ),
                        const Text('Check batch dates  →', style: TextStyle(color: C.bg, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _ElevationPainter extends CustomPainter {
  _ElevationPainter(this.prof, this.color, this.t);
  final List<double> prof;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    const pad = 6.0;
    final mx = prof.reduce((a, b) => a > b ? a : b), mn = prof.reduce((a, b) => a < b ? a : b);
    final line = Path();
    for (var i = 0; i < prof.length; i++) {
      final x = i * s.width / (prof.length - 1);
      final y = s.height - pad - (prof[i] - mn) / (mx - mn) * (s.height - pad * 2);
      i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
    }
    final area = Path.from(line)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: .12));
    final m = line.computeMetrics().first;
    canvas.drawPath(
        m.extractPath(0, m.length * t),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_ElevationPainter o) => o.t != t;
}
