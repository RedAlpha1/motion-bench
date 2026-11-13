import React, { useEffect, useState } from 'react';
import { LayoutChangeEvent, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import Animated, {
  Easing, interpolate, interpolateColor, useAnimatedProps, useAnimatedStyle, useSharedValue,
  withDelay, withRepeat, withSequence, withTiming, type SharedValue,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import Svg, { Path, Polygon } from 'react-native-svg';
import { Bench, C, EASE_DRAW, EASE_FRAME, EASE_SHEET, MOUNTAINS, TREKS, Trek } from './theme';

const AnimatedPath = Animated.createAnimatedComponent(Path);
const T = 200;
const CHIPS = ['All', 'Himachal', 'Uttarakhand', 'Winter', 'Beginner'];

const rise = (delay: number) => () => {
  'worklet';
  return {
    initialValues: { opacity: 0, transform: [{ translateY: 22 }] },
    animations: {
      opacity: withDelay(delay, withTiming(1, { duration: 600, easing: EASE_SHEET })),
      transform: [{ translateY: withDelay(delay, withTiming(0, { duration: 600, easing: EASE_SHEET })) }],
    },
  };
};
const sheetUp = () => {
  'worklet';
  return {
    initialValues: { transform: [{ translateY: 480 }] },
    animations: { transform: [{ translateY: withDelay(180, withTiming(0, { duration: 750, easing: EASE_SHEET })) }] },
  };
};
const popIn = (delay: number) => () => {
  'worklet';
  return {
    initialValues: { opacity: 0, transform: [{ scale: 0.6 }] },
    animations: {
      opacity: withDelay(delay, withTiming(1, { duration: 400 })),
      transform: [{ scale: withDelay(delay, withTiming(1, { duration: 400, easing: Easing.bezier(0.34, 1.56, 0.64, 1) })) }],
    },
  };
};

function Star({ left, top, size, period, delay }: { left: string; top: string; size: number; period: number; delay: number }) {
  const o = useSharedValue(0.2);
  useEffect(() => {
    o.value = withDelay(delay, withRepeat(withTiming(1, { duration: period / 2, easing: Easing.inOut(Easing.ease) }), -1, true));
  }, []);
  const a = useAnimatedStyle(() => ({ opacity: o.value }));
  return <Animated.View style={[{ position: 'absolute', left: left as any, top: top as any, width: size, height: size, borderRadius: size, backgroundColor: '#FFF' }, a]} />;
}

function Layer({ points, heightPct, lift, pl, color }: { points: string; heightPct: string; lift: number; pl: SharedValue<number>; color: string }) {
  const a = useAnimatedStyle(() => ({ transform: [{ translateY: -lift * pl.value }] }));
  return (
    <Animated.View pointerEvents="none" style={[{ position: 'absolute', left: 0, right: 0, bottom: 0, height: heightPct as any }, a]}>
      <Svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none">
        <Polygon points={points} fill={color} />
      </Svg>
    </Animated.View>
  );
}

function Card({ k, i, open, W, H, onOpen }: { k: Trek; i: number; open: number; W: number; H: number; onOpen: () => void }) {
  const colW = (W - 60) / 2;
  const x = 24 + k.col * (colW + 12);
  const y = T + k.dy;
  const me = open === i;
  const p = useSharedValue(0);
  const f = useSharedValue(0);
  const pl1 = useSharedValue(0), pl2 = useSharedValue(0), pl3 = useSharedValue(0);

  useEffect(() => {
    const to = me ? 1 : 0;
    p.value = withTiming(to, { duration: 700, easing: EASE_FRAME });
    f.value = withTiming(open >= 0 && !me ? 1 : 0, { duration: 350 });
    pl1.value = withTiming(to, { duration: 900, easing: EASE_FRAME });
    pl2.value = withDelay(50, withTiming(to, { duration: 900, easing: EASE_FRAME }));
    pl3.value = withDelay(100, withTiming(to, { duration: 900, easing: EASE_FRAME }));
  }, [open]);

  const frame = useAnimatedStyle(() => ({
    left: interpolate(p.value, [0, 1], [x, 0]),
    top: interpolate(p.value, [0, 1], [y, 0]),
    width: interpolate(p.value, [0, 1], [colW, W]),
    height: interpolate(p.value, [0, 1], [k.h, H]),
    borderRadius: interpolate(p.value, [0, 1], [26, 0]),
    zIndex: p.value > 0.001 ? 30 : 1,
    opacity: 1 - f.value,
    transform: [{ scale: 1 - 0.12 * f.value }],
  }));
  const sun = useAnimatedStyle(() => {
    const w = interpolate(p.value, [0, 1], [colW, W]);
    const h = interpolate(p.value, [0, 1], [k.h, H]);
    const s = interpolate(p.value, [0, 1], [30, 64]);
    return { width: s, height: s, borderRadius: s / 2, left: w * (0.6 + 0.08 * p.value), top: h * (0.14 + 0.01 * p.value) };
  });
  const title = useAnimatedStyle(() => ({
    left: interpolate(p.value, [0, 1], [14, 24]),
    top: interpolate(p.value, [0, 1], [k.h - 62, 84]),
  }));
  const titleText = useAnimatedStyle(() => ({
    fontSize: interpolate(p.value, [0, 1], [18, 38]),
    lineHeight: interpolate(p.value, [0, 1], [19, 40]),
    color: interpolateColor(p.value, [0, 1], ['#FFFFFF', k.ink]),
  }));
  const sub = useAnimatedStyle(() => ({ color: interpolateColor(p.value, [0, 1], ['#FFFFFF', k.ink]) }));

  return (
    <Animated.View style={[styles.card, frame]}>
      <LinearGradient colors={[k.sky1, k.sky2]} style={StyleSheet.absoluteFill} />
      {k.night && (
        <View style={StyleSheet.absoluteFill} pointerEvents="none">
          <Star left="18%" top="9%" size={3} period={2100} delay={0} />
          <Star left="42%" top="5%" size={2} period={1600} delay={400} />
          <Star left="70%" top="13%" size={3} period={2600} delay={900} />
          <Star left="86%" top="6%" size={2} period={1900} delay={200} />
          <Star left="30%" top="18%" size={2} period={2300} delay={1100} />
          <Star left="58%" top="22%" size={2} period={1700} delay={700} />
        </View>
      )}
      <Animated.View style={[{ position: 'absolute', backgroundColor: k.sun, shadowColor: k.sun, shadowOpacity: 0.7, shadowRadius: 24 }, sun]} />
      <Layer points={MOUNTAINS.far} heightPct="70%" lift={150} pl={pl1} color={k.m1} />
      <Layer points={MOUNTAINS.mid} heightPct="50%" lift={190} pl={pl2} color={k.m2} />
      <Layer points={MOUNTAINS.near} heightPct="34%" lift={232} pl={pl3} color={k.m3} />
      <Animated.View style={[{ position: 'absolute', right: 14 }, title]} pointerEvents="none">
        <Animated.Text style={[styles.cardTitle, titleText]}>{k.name}</Animated.Text>
        <Animated.Text style={[styles.cardSub, sub]}>{k.alt} · {k.days}</Animated.Text>
      </Animated.View>
      {open < 0 && <Pressable onPress={onOpen} style={StyleSheet.absoluteFill} accessibilityRole="button" accessibilityLabel={`Open ${k.name}`} />}
    </Animated.View>
  );
}

function Elevation({ trek }: { trek: Trek }) {
  const W = 300, H = 84, pad = 6;
  const max = Math.max(...trek.prof), min = Math.min(...trek.prof);
  const pts = trek.prof.map((v, i) => [(i * W) / (trek.prof.length - 1), H - pad - ((v - min) / (max - min)) * (H - pad * 2)]);
  const line = pts.map((pt, i) => `${i ? 'L' : 'M'}${pt[0].toFixed(1)} ${pt[1].toFixed(1)}`).join(' ');
  const off = useSharedValue(700);
  useEffect(() => { off.value = withDelay(850, withTiming(0, { duration: 1600, easing: EASE_DRAW })); }, []);
  const ap = useAnimatedProps(() => ({ strokeDashoffset: off.value }));
  return (
    <Svg width="100%" height={84} viewBox="0 0 300 84">
      <Path d={`${line} L300 84 L0 84 Z`} fill={trek.accent} fillOpacity={0.12} />
      <AnimatedPath d={line} stroke={trek.accent} strokeWidth={2.5} strokeLinejoin="round" strokeLinecap="round" fill="none" strokeDasharray="700" animatedProps={ap} />
    </Svg>
  );
}

function Shimmer() {
  const x = useSharedValue(0);
  useEffect(() => { x.value = withDelay(1400, withRepeat(withTiming(1, { duration: 2400, easing: Easing.inOut(Easing.ease) }), -1, false)); }, []);
  const a = useAnimatedStyle(() => ({ transform: [{ translateX: interpolate(x.value, [0, 1], [-100, 360]) }, { skewX: '-20deg' }] }));
  return <Animated.View pointerEvents="none" style={[{ position: 'absolute', top: 0, bottom: 0, width: 60, backgroundColor: 'rgba(255,255,255,.45)' }, a]} />;
}

export default function ExploreScreen({ bench }: { bench: Bench }) {
  const [open, setOpen] = useState(-1);
  const [chip, setChip] = useState(0);
  const [size, setSize] = useState({ W: 390, H: 800 });
  const hdr = useSharedValue(0);
  useEffect(() => { hdr.value = withTiming(open >= 0 ? 1 : 0, { duration: 500, easing: EASE_SHEET }); }, [open]);
  const hdrA = useAnimatedStyle(() => ({ opacity: 1 - hdr.value, transform: [{ translateY: -20 * hdr.value }] }));

  // Auto mode: open 1600 ms -> close -> 900 ms -> next card.
  useEffect(() => {
    if (!bench.auto) return;
    let i = 0;
    let timer: ReturnType<typeof setTimeout>;
    const cycle = () => {
      setOpen(i);
      timer = setTimeout(() => {
        setOpen(-1);
        timer = setTimeout(() => { i = (i + 1) % TREKS.length; cycle(); }, 900);
      }, 1600);
    };
    cycle();
    return () => { clearTimeout(timer); setOpen(-1); };
  }, [bench.auto]);

  const sel = TREKS[Math.max(0, open)];

  return (
    <View style={styles.root} onLayout={(e: LayoutChangeEvent) => setSize({ W: e.nativeEvent.layout.width, H: e.nativeEvent.layout.height })}>
      <Animated.View style={[styles.header, hdrA]}>
        <Text style={styles.eyebrow}>HIMALAYA · WINTER 2026</Text>
        <Text style={styles.h1}>Explore treks</Text>
        <TextInput placeholder="Search treks, passes, regions" placeholderTextColor="#8C8C99" style={styles.search} accessibilityLabel="Search treks" />
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8 }}>
          {CHIPS.map((c, i) => (
            <Pressable key={c} onPress={() => setChip(i)} style={[styles.chip, i === chip && styles.chipOn]}>
              <Text style={[styles.chipText, i === chip && { color: C.bg }]}>{c}</Text>
            </Pressable>
          ))}
        </ScrollView>
      </Animated.View>

      {TREKS.map((k, i) => <Card key={k.name} k={k} i={i} open={open} W={size.W} H={size.H} onOpen={() => setOpen(i)} />)}

      {open >= 0 && (
        <View style={[StyleSheet.absoluteFill, { zIndex: 40 }]} pointerEvents="box-none" key={open}>
          <View style={styles.topBtns} pointerEvents="box-none">
            <Animated.View entering={popIn(450)}>
              <Pressable onPress={() => setOpen(-1)} style={styles.round} accessibilityLabel="Close trek details">
                <Svg width={20} height={20} viewBox="0 0 24 24"><Path d="M18 6 6 18M6 6l12 12" stroke="#FFF" strokeWidth={2.2} strokeLinecap="round" /></Svg>
              </Pressable>
            </Animated.View>
            <Animated.View entering={popIn(550)}>
              <Pressable style={styles.round} accessibilityLabel="Save trek">
                <Svg width={20} height={20} viewBox="0 0 24 24"><Path d="M6 3h12v18l-6-4-6 4z" stroke="#FFF" strokeWidth={2} strokeLinejoin="round" fill="none" /></Svg>
              </Pressable>
            </Animated.View>
          </View>

          <Animated.View entering={sheetUp} style={styles.sheet}>
            <View style={styles.handle} />
            <Animated.Text entering={rise(450)} style={styles.blurb}>{sel.blurb}</Animated.Text>
            <View style={{ flexDirection: 'row', gap: 8 }}>
              {[['Altitude', sel.alt], ['Duration', sel.days], ['Grade', sel.diff], ['Season', sel.season]].map(([kk, v], j) => (
                <Animated.View key={kk} entering={rise(500 + j * 70)} style={styles.stat}>
                  <Text style={styles.statK}>{kk.toUpperCase()}</Text>
                  <Text style={styles.statV}>{v}</Text>
                </Animated.View>
              ))}
            </View>
            <Animated.View entering={rise(700)} style={styles.elev}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                <Text style={styles.statK}>Elevation profile</Text>
                <Text style={styles.statK}>{sel.alt} summit</Text>
              </View>
              <Elevation trek={sel} />
            </Animated.View>
            <Animated.View entering={rise(850)} style={{ marginTop: 'auto' }}>
              <Pressable style={styles.cta}>
                <Shimmer />
                <Text style={styles.ctaText}>Check batch dates  →</Text>
              </Pressable>
            </Animated.View>
          </Animated.View>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg, overflow: 'hidden' },
  header: { position: 'absolute', left: 24, right: 24, top: 16, gap: 12 },
  eyebrow: { color: C.muted, fontSize: 12, letterSpacing: 1 },
  h1: { color: C.text, fontSize: 28, fontWeight: '700', marginTop: -8 },
  search: { height: 48, borderRadius: 16, backgroundColor: C.surface, borderWidth: 1, borderColor: C.border, paddingHorizontal: 16, color: C.text, fontSize: 15 },
  chip: { height: 36, paddingHorizontal: 16, borderRadius: 999, borderWidth: 1, borderColor: '#23232D', backgroundColor: '#121218', justifyContent: 'center' },
  chipOn: { backgroundColor: C.text, borderColor: C.text },
  chipText: { color: '#C9C9D3', fontSize: 13, fontWeight: '600' },
  card: { position: 'absolute', overflow: 'hidden' },
  cardTitle: { fontWeight: '700' },
  cardSub: { fontSize: 12, fontWeight: '500', opacity: 0.85, marginTop: 4 },
  topBtns: { position: 'absolute', top: 24, left: 24, right: 24, flexDirection: 'row', justifyContent: 'space-between' },
  round: { width: 44, height: 44, borderRadius: 22, backgroundColor: 'rgba(11,11,15,.55)', alignItems: 'center', justifyContent: 'center' },
  sheet: { position: 'absolute', left: 0, right: 0, bottom: 0, height: 452, backgroundColor: C.bg, borderTopLeftRadius: 32, borderTopRightRadius: 32, paddingHorizontal: 24, paddingTop: 14, paddingBottom: 24, gap: 16 },
  handle: { alignSelf: 'center', width: 40, height: 4, borderRadius: 4, backgroundColor: '#2A2A36' },
  blurb: { color: '#B8B8C4', fontSize: 14, lineHeight: 21 },
  stat: { flex: 1, backgroundColor: C.surface, borderWidth: 1, borderColor: C.border, borderRadius: 16, paddingVertical: 10, paddingHorizontal: 8, gap: 4 },
  statK: { color: C.muted, fontSize: 10, letterSpacing: 0.6 },
  statV: { color: C.text, fontSize: 14, fontWeight: '700' },
  elev: { backgroundColor: C.surface, borderWidth: 1, borderColor: C.border, borderRadius: 20, padding: 14, gap: 8 },
  cta: { height: 56, borderRadius: 18, backgroundColor: C.lime, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  ctaText: { color: C.bg, fontSize: 16, fontWeight: '700' },
});
