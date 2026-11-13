import { Easing } from 'react-native-reanimated';

export const C = {
  bg: '#0B0B0F',
  surface: '#14141B',
  border: '#1F1F29',
  text: '#F4F4F6',
  muted: '#9A9AA6',
  lime: '#C6F432',
  violet: '#8B7CFF',
  coral: '#FF7A59',
  teal: '#4FD1C5',
  heart: '#FF5C7A',
};

export const EASE_FRAME = Easing.bezier(0.2, 0.9, 0.1, 1);
export const EASE_SHEET = Easing.bezier(0.22, 1, 0.36, 1);
export const EASE_DRAW = Easing.bezier(0.65, 0, 0.35, 1);
export const SPRING_ARM = { stiffness: 170, damping: 12, mass: 1 };

export type Bench = { load: 1 | 4; auto: boolean };

export const TRACKS = [
  { title: 'Neon Monsoon', artist: 'Kavya & The Static', mono: 'NM', color: '#C6F432', orbA: '#5B4BFF', orbB: '#C6F432', len: 222 },
  { title: 'Paper Satellites', artist: 'Low Orbit Club', mono: 'PS', color: '#8B7CFF', orbA: '#FF7A59', orbB: '#8B7CFF', len: 198 },
  { title: 'Saltwater Static', artist: 'Mira Okafor', mono: 'SS', color: '#FF7A59', orbA: '#4FD1C5', orbB: '#FF7A59', len: 245 },
];

export const LYRICS = [
  'City lights are melting in the rain',
  'Every signal turning into gold',
  'We ride the hum of the last train',
  'Holding on to stories never told',
  'Neon rivers running through the night',
  'Your laugh is louder than the thunder',
  'Count the seconds, hold the light',
  'Let the monsoon pull us under',
];

export const BAR_H = [18, 30, 22, 40, 34, 44, 26, 38, 20, 42, 30, 36, 24, 44, 32, 28, 40, 22, 36, 44, 26, 34, 18, 40, 30, 42, 24, 38, 20, 32, 28, 16];

export type Trek = {
  name: string; alt: string; days: string; diff: string; season: string; blurb: string;
  sky1: string; sky2: string; sun: string; m1: string; m2: string; m3: string;
  ink: string; night: boolean; accent: string; prof: number[]; col: 0 | 1; dy: number; h: number;
};

export const TREKS: Trek[] = [
  { name: 'Buran Ghati', alt: '4,575 m', days: '8 days', diff: 'Hard', season: 'May–Jun',
    blurb: 'Kinnaur, Himachal. Meadows to a high snow pass, then a long snow-slope descent into the Pabbar valley.',
    sky1: '#1B1F3B', sky2: '#E07A5F', sun: '#FFD6A5', m1: '#5A3D5C', m2: '#3A2740', m3: '#17111D', ink: '#FFFFFF', night: true, accent: '#FF9F80',
    prof: [2500, 2800, 3100, 3300, 3500, 3700, 4575, 3900, 3200, 2600, 2200], col: 0, dy: 0, h: 250 },
  { name: 'Kedarkantha', alt: '3,810 m', days: '6 days', diff: 'Easy', season: 'Dec–Apr',
    blurb: 'Uttarakhand. A classic winter summit climb through pine forest and snow-covered clearings.',
    sky1: '#9EC5EA', sky2: '#EAF2FA', sun: '#FFFFFF', m1: '#E6EEF6', m2: '#7E96B2', m3: '#22334A', ink: '#0B0B0F', night: false, accent: '#7FB5FF',
    prof: [1900, 2400, 2900, 3200, 3400, 3810, 3400, 2900, 2400, 1900], col: 1, dy: 0, h: 200 },
  { name: 'Hampta Pass', alt: '4,270 m', days: '5 days', diff: 'Moderate', season: 'Jun–Sep',
    blurb: 'Kullu to Lahaul. Green valleys on one side of the pass, stark high-desert on the other.',
    sky1: '#F6C177', sky2: '#F28C6B', sun: '#FFF1C9', m1: '#9A5B67', m2: '#5E3448', m3: '#22162A', ink: '#0B0B0F', night: false, accent: '#F6C177',
    prof: [2900, 3200, 3500, 3700, 4270, 3800, 3600, 3900, 3300], col: 0, dy: 262, h: 200 },
  { name: 'Valley of Flowers', alt: '3,658 m', days: '6 days', diff: 'Easy', season: 'Jul–Sep',
    blurb: 'Chamoli, Uttarakhand. Alpine meadows that burst into bloom during the monsoon months.',
    sky1: '#BFE3CB', sky2: '#F4F1DE', sun: '#FFF7D6', m1: '#8DB580', m2: '#4E7A45', m3: '#1F3A26', ink: '#0B0B0F', night: false, accent: '#9BD88A',
    prof: [1800, 2200, 3000, 3300, 3658, 3400, 3000, 2600, 2000], col: 1, dy: 212, h: 250 },
];

export const MOUNTAINS = {
  far: '0,100 0,55 15,35 28,50 45,18 60,45 72,28 88,48 100,36 100,100',
  mid: '0,100 0,60 20,38 35,58 55,28 75,55 90,40 100,52 100,100',
  near: '0,100 0,48 25,28 50,52 70,34 100,58 100,100',
};
