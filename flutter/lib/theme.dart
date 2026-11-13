import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

class C {
  static const bg = Color(0xFF0B0B0F);
  static const surface = Color(0xFF14141B);
  static const border = Color(0xFF1F1F29);
  static const text = Color(0xFFF4F4F6);
  static const muted = Color(0xFF9A9AA6);
  static const lime = Color(0xFFC6F432);
  static const heart = Color(0xFFFF5C7A);
  static const soft = Color(0xFFC9C9D3);
}

const easeFrame = Cubic(0.2, 0.9, 0.1, 1);
const easeSheet = Cubic(0.22, 1, 0.36, 1);
const easeDraw = Cubic(0.65, 0, 0.35, 1);
const easeBack = Cubic(0.34, 1.56, 0.64, 1);
const easeInOut = Cubic(0.42, 0, 0.58, 1);

class Bench {
  final int load;
  final bool auto;
  const Bench({this.load = 1, this.auto = false});
  Bench copyWith({int? load, bool? auto}) => Bench(load: load ?? this.load, auto: auto ?? this.auto);
}

class Track {
  final String title, artist, mono;
  final Color color, orbA, orbB;
  final double len;
  const Track(this.title, this.artist, this.mono, this.color, this.orbA, this.orbB, this.len);
}

const tracks = [
  Track('Neon Monsoon', 'Kavya & The Static', 'NM', Color(0xFFC6F432), Color(0xFF5B4BFF), Color(0xFFC6F432), 222),
  Track('Paper Satellites', 'Low Orbit Club', 'PS', Color(0xFF8B7CFF), Color(0xFFFF7A59), Color(0xFF8B7CFF), 198),
  Track('Saltwater Static', 'Mira Okafor', 'SS', Color(0xFFFF7A59), Color(0xFF4FD1C5), Color(0xFFFF7A59), 245),
];

const lyrics = [
  'City lights are melting in the rain',
  'Every signal turning into gold',
  'We ride the hum of the last train',
  'Holding on to stories never told',
  'Neon rivers running through the night',
  'Your laugh is louder than the thunder',
  'Count the seconds, hold the light',
  'Let the monsoon pull us under',
];

const barH = <double>[18, 30, 22, 40, 34, 44, 26, 38, 20, 42, 30, 36, 24, 44, 32, 28, 40, 22, 36, 44, 26, 34, 18, 40, 30, 42, 24, 38, 20, 32, 28, 16];

class Trek {
  final String name, alt, days, diff, season, blurb;
  final Color sky1, sky2, sun, m1, m2, m3, ink, accent;
  final bool night;
  final List<double> prof;
  final int col;
  final double dy, h;
  const Trek({
    required this.name, required this.alt, required this.days, required this.diff, required this.season, required this.blurb,
    required this.sky1, required this.sky2, required this.sun, required this.m1, required this.m2, required this.m3,
    required this.ink, required this.accent, required this.night, required this.prof, required this.col, required this.dy, required this.h,
  });
}

const treks = [
  Trek(name: 'Buran Ghati', alt: '4,575 m', days: '8 days', diff: 'Hard', season: 'May–Jun',
      blurb: 'Kinnaur, Himachal. Meadows to a high snow pass, then a long snow-slope descent into the Pabbar valley.',
      sky1: Color(0xFF1B1F3B), sky2: Color(0xFFE07A5F), sun: Color(0xFFFFD6A5), m1: Color(0xFF5A3D5C), m2: Color(0xFF3A2740), m3: Color(0xFF17111D),
      ink: Color(0xFFFFFFFF), accent: Color(0xFFFF9F80), night: true, prof: [2500, 2800, 3100, 3300, 3500, 3700, 4575, 3900, 3200, 2600, 2200], col: 0, dy: 0, h: 250),
  Trek(name: 'Kedarkantha', alt: '3,810 m', days: '6 days', diff: 'Easy', season: 'Dec–Apr',
      blurb: 'Uttarakhand. A classic winter summit climb through pine forest and snow-covered clearings.',
      sky1: Color(0xFF9EC5EA), sky2: Color(0xFFEAF2FA), sun: Color(0xFFFFFFFF), m1: Color(0xFFE6EEF6), m2: Color(0xFF7E96B2), m3: Color(0xFF22334A),
      ink: C.bg, accent: Color(0xFF7FB5FF), night: false, prof: [1900, 2400, 2900, 3200, 3400, 3810, 3400, 2900, 2400, 1900], col: 1, dy: 0, h: 200),
  Trek(name: 'Hampta Pass', alt: '4,270 m', days: '5 days', diff: 'Moderate', season: 'Jun–Sep',
      blurb: 'Kullu to Lahaul. Green valleys on one side of the pass, stark high-desert on the other.',
      sky1: Color(0xFFF6C177), sky2: Color(0xFFF28C6B), sun: Color(0xFFFFF1C9), m1: Color(0xFF9A5B67), m2: Color(0xFF5E3448), m3: Color(0xFF22162A),
      ink: C.bg, accent: Color(0xFFF6C177), night: false, prof: [2900, 3200, 3500, 3700, 4270, 3800, 3600, 3900, 3300], col: 0, dy: 262, h: 200),
  Trek(name: 'Valley of Flowers', alt: '3,658 m', days: '6 days', diff: 'Easy', season: 'Jul–Sep',
      blurb: 'Chamoli, Uttarakhand. Alpine meadows that burst into bloom during the monsoon months.',
      sky1: Color(0xFFBFE3CB), sky2: Color(0xFFF4F1DE), sun: Color(0xFFFFF7D6), m1: Color(0xFF8DB580), m2: Color(0xFF4E7A45), m3: Color(0xFF1F3A26),
      ink: C.bg, accent: Color(0xFF9BD88A), night: false, prof: [1800, 2200, 3000, 3300, 3658, 3400, 3000, 2600, 2000], col: 1, dy: 212, h: 250),
];

const far = <double>[0, 100, 0, 55, 15, 35, 28, 50, 45, 18, 60, 45, 72, 28, 88, 48, 100, 36, 100, 100];
const mid = <double>[0, 100, 0, 60, 20, 38, 35, 58, 55, 28, 75, 55, 90, 40, 100, 52, 100, 100];
const near = <double>[0, 100, 0, 48, 25, 28, 50, 52, 70, 34, 100, 58, 100, 100];
