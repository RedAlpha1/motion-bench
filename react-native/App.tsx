import React, { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { C, Bench } from './src/theme';
import PlayerScreen from './src/PlayerScreen';
import ExploreScreen from './src/ExploreScreen';

type ScreenName = 'player' | 'explore';

function Pill({ label, on, onPress }: { label: string; on: boolean; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={[styles.pill, on && styles.pillOn]} accessibilityRole="button" accessibilityState={{ selected: on }}>
      <Text style={[styles.pillText, on && styles.pillTextOn]}>{label}</Text>
    </Pressable>
  );
}

export default function App() {
  const [screen, setScreen] = useState<ScreenName>('player');
  const [bench, setBench] = useState<Bench>({ load: 1, auto: false });

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <SafeAreaView style={styles.root} edges={['top', 'bottom']}>
        <View style={styles.bar}>
          <Pill label="Player" on={screen === 'player'} onPress={() => setScreen('player')} />
          <Pill label="Explore" on={screen === 'explore'} onPress={() => setScreen('explore')} />
          <View style={{ flex: 1 }} />
          <Pill label={`Load ${bench.load}×`} on={bench.load === 4} onPress={() => setBench(b => ({ ...b, load: b.load === 1 ? 4 : 1 }))} />
          <Pill label="Auto" on={bench.auto} onPress={() => setBench(b => ({ ...b, auto: !b.auto }))} />
        </View>
        <View style={{ flex: 1 }}>
          {screen === 'player' ? <PlayerScreen bench={bench} /> : <ExploreScreen bench={bench} />}
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg },
  bar: { flexDirection: 'row', gap: 6, paddingHorizontal: 12, paddingVertical: 6, borderBottomWidth: 1, borderBottomColor: C.border },
  pill: { height: 32, paddingHorizontal: 12, borderRadius: 999, borderWidth: 1, borderColor: C.border, justifyContent: 'center' },
  pillOn: { backgroundColor: C.text, borderColor: C.text },
  pillText: { color: '#C9C9D3', fontSize: 12, fontWeight: '600' },
  pillTextOn: { color: C.bg },
});
