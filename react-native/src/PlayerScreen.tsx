import React, { useEffect, useMemo, useRef, useState } from 'react';
import { LayoutChangeEvent, Pressable, StyleSheet, Text, View } from 'react-native';
import Animated, {
  cancelAnimation, Easing, useAnimatedStyle, useSharedValue, withRepeat, withSequence, withSpring, withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Circle, Defs, Path, RadialGradient, Rect, Stop } from 'react-native-svg';
import { BAR_H, Bench, C, LYRICS, SPRING_ARM, TRACKS } from './theme';

const inOut = Easing.inOut(Easing.ease);

// Custom entering animations (exact values from SPEC.md)
const swapIn = () => {
  'worklet';
  return {
    initialValues: { opacity: 0, transform: [{ translateY: 14 }] },
    animations: {
      opacity: withTiming(1, { duration: 550 }),
      transform: [{ translateY: withTiming(0, { duration: 550, easing: Easing.bezier(0.22, 1, 0.36, 1) }) }],
    },
  };
};
const iconIn = () => {
  'worklet';
  return {
    initialValues: { opacity: 0, transform: [{ scale: 0.4 }, { rotate: '-90deg' }] },
    animations: {
      opacity: withTiming(1, { duration: 350 }),
      transform: [
        { scale: withTiming(1, { duration: 350, easing: Easing.bezier(0.34, 1.56, 0.64, 1) }) },
        { rotate: withTiming('0deg', { duration: 350 }) },
      ],
    },
  };
};

function Orb({ color, size, style, dur, mid, end, playing }: {
  color: string; size: number; style: object; dur: number; mid: [number, number]; end: [number, number]; playing: boolean;
}) {
  const x = useSharedValue(0);
  const y = useSharedValue(0);
  useEffect(() => {
    if (!playing) { cancelAnimation(x); cancelAnimation(y); return; }
    const half = dur / 2;
    x.value = withRepeat(withSequence(withTiming(mid[0], { duration: half, easing: inOut }), withTiming(end[0], { duration: half, easing: inOut })), -1, true);
    y.value = withRepeat(withSequence(withTiming(mid[1], { duration: half, easing: inOut }), withTiming(end[1], { duration: half, easing: inOut })), -1, true);
  }, [playing]);
  const a = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }, { translateY: y.value }] }));
  return (
    <Animated.View pointerEvents="none" style={[{ position: 'absolute', width: size, height: size }, style, a]}>
      <Svg width={size} height={size}>
        <Defs>
          <RadialGradient id="g" cx="50%" cy="50%" r="50%">
            <Stop offset="0" stopColor={color} stopOpacity={0.5} />
            <Stop offset="1" stopColor={color} stopOpacity={0} />
          </RadialGradient>
        </Defs>
        <Circle cx={size / 2} cy={size / 2} r={size / 2} fill="url(#g)" />
      </Svg>
    </Animated.View>
  );
}

function EqBar({ i, color, width, playing }: { i: number; color: string; width: number; playing: boolean }) {
  const dur = (0.32 + ((i * 37) % 23) / 40) * 1000;
  const phase = ((i * 53) % 17) / 20;
  const s = useSharedValue(0.12 + 0.88 * phase);
  useEffect(() => {
    if (!playing) { cancelAnimation(s); return; }
    const remaining = Math.max(16, dur * (1 - (s.value - 0.12) / 0.88));
    s.value = withSequence(
      withTiming(1, { duration: remaining, easing: inOut }),
      withRepeat(withSequence(withTiming(0.12, { duration: dur, easing: inOut }), withTiming(1, { duration: dur, easing: inOut })), -1, false),
    );
  }, [playing]);
  const a = useAnimatedStyle(() => ({ transform: [{ scaleY: s.value }] }));
  return <Animated.View style={[{ width, height: BAR_H[i % 32], borderRadius: 3, backgroundColor: color, transformOrigin: 'bottom' }, a]} />;
}

function LyricLine({ text, dist }: { text: string; dist: number }) {
  const op = dist === 0 ? 1 : dist === 1 ? 0.4 : 0.18;
  const sc = dist === 0 ? 1.04 : 1;
  const o = useSharedValue(op);
  const s = useSharedValue(sc);
  useEffect(() => {
    o.value = withTiming(op, { duration: 500 });
    s.value = withSpring(sc, { stiffness: 180, damping: 10 });
  }, [op, sc]);
  const a = useAnimatedStyle(() => ({ opacity: o.value, transform: [{ scale: s.value }] }));
  return (
    <Animated.Text style={[styles.lyric, { color: dist === 0 ? '#FFFFFF' : '#C9C9D3', transformOrigin: 'left' }, a]} numberOfLines={1}>
      {text}
    </Animated.Text>
  );
}

const fmt = (s: number) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;

export default function PlayerScreen({ bench }: { bench: Bench }) {
  const [playing, setPlaying] = useState(true);
  const [progress, setProgress] = useState(0.06);
  const [track, setTrack] = useState(0);
  const [liked, setLiked] = useState(false);
  const [barW, setBarW] = useState(1);
  const t = TRACKS[track];

  // 10 Hz JS-thread timer, deliberately on the JS thread (see SPEC).
  const playingRef = useRef(playing);
  playingRef.current = playing;
  useEffect(() => {
    const id = setInterval(() => {
      if (!playingRef.current) return;
      setProgress(p => {
        if (p + 0.0025 >= 1) { setTrack(x => (x + 1) % 3); return 0; }
        return p + 0.0025;
      });
    }, 100);
    return () => clearInterval(id);
  }, []);
  const go = (dir: number) => { setTrack(x => (x + dir + 3) % 3); setProgress(0); };

  // Disc rotation: resumes from current angle.
  const rot = useSharedValue(0);
  useEffect(() => {
    if (!playing) { cancelAnimation(rot); return; }
    const from = rot.value % 360;
    rot.value = from;
    rot.value = withRepeat(withTiming(from + 360, { duration: 5000, easing: Easing.linear }), -1, false);
  }, [playing]);
  const discA = useAnimatedStyle(() => ({ transform: [{ rotate: `${rot.value}deg` }] }));

  // Beat ring
  const beat = useSharedValue(0);
  useEffect(() => {
    if (!playing) { cancelAnimation(beat); return; }
    beat.value = withRepeat(withTiming(1, { duration: 470, easing: inOut }), -1, true);
  }, [playing]);
  const accent = useSharedValue(t.color);
  useEffect(() => { accent.value = withTiming(t.color, { duration: 800 }); }, [t.color]);
  const beatA = useAnimatedStyle(() => ({
    opacity: 0.45 + 0.4 * beat.value,
    transform: [{ scale: 0.96 + 0.1 * beat.value }],
    borderColor: accent.value,
  }));
  const accentBg = useAnimatedStyle(() => ({ backgroundColor: accent.value }));

  // Tonearm
  const arm = useSharedValue(22);
  useEffect(() => { arm.value = withSpring(playing ? 22 : 0, SPRING_ARM); }, [playing]);
  const armA = useAnimatedStyle(() => ({ transform: [{ rotate: `${arm.value}deg` }] }));

  // Play button radius
  const rad = useSharedValue(28);
  useEffect(() => { rad.value = withSpring(playing ? 28 : 40, { stiffness: 220, damping: 12 }); }, [playing]);
  const playA = useAnimatedStyle(() => ({ borderRadius: rad.value, backgroundColor: accent.value }));

  // Like pop
  const pop = useSharedValue(1);
  const likeA = useAnimatedStyle(() => ({ transform: [{ scale: pop.value }] }));
  const toggleLike = () => {
    setLiked(l => !l);
    pop.value = withSequence(withTiming(1.45, { duration: 180 }), withTiming(1, { duration: 270, easing: Easing.bezier(0.34, 1.56, 0.64, 1) }));
  };

  // Lyrics column
  const idx = Math.min(LYRICS.length - 1, Math.floor(progress * LYRICS.length));
  const ly = useSharedValue(44);
  useEffect(() => { ly.value = withSpring(44 - idx * 44, { stiffness: 140, damping: 14 }); }, [idx]);
  const lyA = useAnimatedStyle(() => ({ transform: [{ translateY: ly.value }] }));

  const nBars = 32 * bench.load;
  const barColors = useMemo(() => Array.from({ length: nBars }, (_, i) => (i % 3 === 0 ? t.color : i % 3 === 1 ? 'rgba(244,244,246,.55)' : 'rgba(244,244,246,.25)')), [nBars, t.color]);
  const grooves = useMemo(() => {
    const n = 24 * bench.load;
    return Array.from({ length: n }, (_, i) => 40 + (92 * i) / (n - 1));
  }, [bench.load]);

  return (
    <View style={styles.root}>
      <Orb color={t.orbA} size={320} style={{ left: -120, top: -60 }} dur={11000} mid={[60, 40]} end={[-30, 90]} playing={playing} />
      <Orb color={t.orbB} size={280} style={{ right: -110, top: 260 }} dur={13000} mid={[-70, -30]} end={[20, -80]} playing={playing} />

      <View style={styles.content}>
        <View style={styles.discWrap}>
          <Animated.View style={[styles.beat, beatA]} />
          <Animated.View style={[styles.disc, discA]}>
            <Svg width={268} height={268} style={StyleSheet.absoluteFill}>
              <Circle cx={134} cy={134} r={134} fill="#15151B" />
              {grooves.map((r, i) => (
                <Circle key={i} cx={134} cy={134} r={r} stroke={i % 2 ? '#1E1E27' : '#111116'} strokeWidth={1.5} fill="none" />
              ))}
              <Path d="M134 134 L220 30 A134 134 0 0 1 250 70 Z" fill="rgba(255,255,255,0.06)" />
            </Svg>
            <Animated.View style={[styles.label, accentBg]}>
              <Text style={styles.mono}>{t.mono}</Text>
              <View style={styles.spindle} />
            </Animated.View>
          </Animated.View>
          <Animated.View style={[styles.arm, armA]} pointerEvents="none">
            <Svg width={120} height={170}>
              <Circle cx={96} cy={22} r={16} fill="#23232D" stroke="#3A3A47" strokeWidth={2} />
              <Circle cx={96} cy={22} r={6} fill="#6E6E7A" />
              <Path d="M96 22 L90 120 L62 150" stroke="#C9C9D3" strokeWidth={5} strokeLinecap="round" strokeLinejoin="round" fill="none" />
              <Rect x={48} y={140} width={26} height={18} rx={4} fill="#E9E9EF" transform="rotate(-40 61 149)" />
            </Svg>
          </Animated.View>
        </View>

        <View style={styles.titleRow}>
          <Animated.View key={track} entering={swapIn} style={{ flex: 1 }}>
            <Text style={styles.title}>{t.title}</Text>
            <Text style={styles.artist}>{t.artist}</Text>
          </Animated.View>
          <Pressable onPress={toggleLike} style={styles.likeBtn} accessibilityLabel={liked ? 'Remove from liked songs' : 'Add to liked songs'}>
            <Animated.View style={likeA}>
              <Svg width={22} height={22} viewBox="0 0 24 24">
                <Path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z" fill={liked ? C.heart : 'none'} stroke={liked ? C.heart : '#C9C9D3'} strokeWidth={2} strokeLinejoin="round" />
              </Svg>
            </Animated.View>
          </Pressable>
        </View>

        <View style={styles.eq}>
          {barColors.map((c, i) => <EqBar key={`${bench.load}-${i}`} i={i} color={c} width={bench.load === 4 ? 2 : 5} playing={playing} />)}
        </View>

        <View>
          <Pressable
            onLayout={(e: LayoutChangeEvent) => setBarW(e.nativeEvent.layout.width)}
            onPress={e => setProgress(Math.max(0, Math.min(0.999, e.nativeEvent.locationX / barW)))}
            style={styles.seek}
            accessibilityLabel="Seek"
          >
            <View style={styles.track} />
            <Animated.View style={[styles.fill, { width: `${progress * 100}%` }, accentBg]} />
            <View style={[styles.knob, { left: progress * barW - 8 }]} />
          </Pressable>
          <View style={styles.times}>
            <Text style={styles.time}>{fmt(progress * t.len)}</Text>
            <Text style={styles.time}>{fmt(t.len)}</Text>
          </View>
        </View>

        <View style={styles.controls}>
          <Pressable onPress={() => go(-1)} style={styles.ctl} accessibilityLabel="Previous track">
            <Svg width={30} height={30} viewBox="0 0 24 24"><Path d="M6 5h2v14H6zM20 5v14L9.5 12z" fill={C.text} /></Svg>
          </Pressable>
          <Pressable onPress={() => setPlaying(p => !p)} accessibilityLabel={playing ? 'Pause' : 'Play'}>
            <Animated.View style={[styles.play, playA]}>
              <Animated.View key={String(playing)} entering={iconIn}>
                <Svg width={30} height={30} viewBox="0 0 24 24">
                  {playing
                    ? <><Rect x={6} y={4} width={4} height={16} rx={1.5} fill={C.bg} /><Rect x={14} y={4} width={4} height={16} rx={1.5} fill={C.bg} /></>
                    : <Path d="M7 4.5v15a1 1 0 0 0 1.5.86l12-7.5a1 1 0 0 0 0-1.72l-12-7.5A1 1 0 0 0 7 4.5z" fill={C.bg} />}
                </Svg>
              </Animated.View>
            </Animated.View>
          </Pressable>
          <Pressable onPress={() => go(1)} style={styles.ctl} accessibilityLabel="Next track">
            <Svg width={30} height={30} viewBox="0 0 24 24"><Path d="M16 5h2v14h-2zM4 5v14l10.5-7z" fill={C.text} /></Svg>
          </Pressable>
        </View>

        <View style={styles.lyricsBox}>
          <Animated.View style={[{ paddingHorizontal: 22 }, lyA]}>
            {LYRICS.map((l, i) => <LyricLine key={i} text={l} dist={Math.abs(i - idx)} />)}
          </Animated.View>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg, overflow: 'hidden' },
  content: { flex: 1, paddingHorizontal: 24, paddingTop: 20, paddingBottom: 16, gap: 16 },
  discWrap: { width: 268, height: 268, alignSelf: 'center' },
  beat: { position: 'absolute', left: -14, top: -14, right: -14, bottom: -14, borderRadius: 999, borderWidth: 2 },
  disc: { width: 268, height: 268, borderRadius: 134, overflow: 'hidden', alignItems: 'center', justifyContent: 'center' },
  label: { width: 104, height: 104, borderRadius: 52, alignItems: 'center', justifyContent: 'center' },
  mono: { color: C.bg, fontWeight: '700', fontSize: 24, letterSpacing: 1 },
  spindle: { position: 'absolute', width: 10, height: 10, borderRadius: 5, backgroundColor: C.bg },
  arm: { position: 'absolute', right: -44, top: -26, width: 120, height: 170, transformOrigin: [96, 22, 0] },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 12, marginTop: 6 },
  title: { color: C.text, fontSize: 26, fontWeight: '700' },
  artist: { color: '#A3A3AF', fontSize: 14, marginTop: 2 },
  likeBtn: { width: 48, height: 48, borderRadius: 24, backgroundColor: 'rgba(255,255,255,.06)', alignItems: 'center', justifyContent: 'center' },
  eq: { height: 44, flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between' },
  seek: { height: 22, justifyContent: 'center' },
  track: { position: 'absolute', left: 0, right: 0, height: 5, borderRadius: 5, backgroundColor: 'rgba(255,255,255,.12)' },
  fill: { position: 'absolute', left: 0, height: 5, borderRadius: 5 },
  knob: { position: 'absolute', width: 16, height: 16, borderRadius: 8, backgroundColor: C.text },
  times: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 6 },
  time: { color: C.muted, fontSize: 12, fontVariant: ['tabular-nums'] },
  controls: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 36 },
  ctl: { width: 56, height: 56, alignItems: 'center', justifyContent: 'center' },
  play: { width: 80, height: 80, alignItems: 'center', justifyContent: 'center' },
  lyricsBox: { flex: 1, minHeight: 132, borderRadius: 24, backgroundColor: 'rgba(255,255,255,.04)', borderWidth: 1, borderColor: 'rgba(255,255,255,.06)', overflow: 'hidden' },
  lyric: { height: 44, lineHeight: 44, fontSize: 18, fontWeight: '600' },
});
