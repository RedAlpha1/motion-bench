import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

enum C {
    static let bg = Color(hex: 0x0B0B0F)
    static let surface = Color(hex: 0x14141B)
    static let border = Color(hex: 0x1F1F29)
    static let text = Color(hex: 0xF4F4F6)
    static let muted = Color(hex: 0x9A9AA6)
    static let lime = Color(hex: 0xC6F432)
    static let heart = Color(hex: 0xFF5C7A)
    static let soft = Color(hex: 0xC9C9D3)
}

enum Ease {
    static let frame = Animation.timingCurve(0.2, 0.9, 0.1, 1, duration: 0.7)
    static func sheet(_ d: Double) -> Animation { .timingCurve(0.22, 1, 0.36, 1, duration: d) }
    static let draw = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 1.6)
    static let back = Animation.timingCurve(0.34, 1.56, 0.64, 1, duration: 0.35)
}

struct Bench: Equatable {
    var load = 1
    var auto = false
}

struct Track {
    let title, artist, mono: String
    let color, orbA, orbB: Color
    let len: Double
}

let TRACKS = [
    Track(title: "Neon Monsoon", artist: "Kavya & The Static", mono: "NM", color: Color(hex: 0xC6F432), orbA: Color(hex: 0x5B4BFF), orbB: Color(hex: 0xC6F432), len: 222),
    Track(title: "Paper Satellites", artist: "Low Orbit Club", mono: "PS", color: Color(hex: 0x8B7CFF), orbA: Color(hex: 0xFF7A59), orbB: Color(hex: 0x8B7CFF), len: 198),
    Track(title: "Saltwater Static", artist: "Mira Okafor", mono: "SS", color: Color(hex: 0xFF7A59), orbA: Color(hex: 0x4FD1C5), orbB: Color(hex: 0xFF7A59), len: 245),
]

let LYRICS = [
    "City lights are melting in the rain",
    "Every signal turning into gold",
    "We ride the hum of the last train",
    "Holding on to stories never told",
    "Neon rivers running through the night",
    "Your laugh is louder than the thunder",
    "Count the seconds, hold the light",
    "Let the monsoon pull us under",
]

let BAR_H: [CGFloat] = [18, 30, 22, 40, 34, 44, 26, 38, 20, 42, 30, 36, 24, 44, 32, 28, 40, 22, 36, 44, 26, 34, 18, 40, 30, 42, 24, 38, 20, 32, 28, 16]

struct Trek {
    let name, alt, days, diff, season, blurb: String
    let sky1, sky2, sun, m1, m2, m3, ink, accent: Color
    let night: Bool
    let prof: [Double]
    let col: Int
    let dy, h: CGFloat
}

let TREKS = [
    Trek(name: "Buran Ghati", alt: "4,575 m", days: "8 days", diff: "Hard", season: "May–Jun",
         blurb: "Kinnaur, Himachal. Meadows to a high snow pass, then a long snow-slope descent into the Pabbar valley.",
         sky1: Color(hex: 0x1B1F3B), sky2: Color(hex: 0xE07A5F), sun: Color(hex: 0xFFD6A5), m1: Color(hex: 0x5A3D5C), m2: Color(hex: 0x3A2740), m3: Color(hex: 0x17111D),
         ink: .white, accent: Color(hex: 0xFF9F80), night: true, prof: [2500, 2800, 3100, 3300, 3500, 3700, 4575, 3900, 3200, 2600, 2200], col: 0, dy: 0, h: 250),
    Trek(name: "Kedarkantha", alt: "3,810 m", days: "6 days", diff: "Easy", season: "Dec–Apr",
         blurb: "Uttarakhand. A classic winter summit climb through pine forest and snow-covered clearings.",
         sky1: Color(hex: 0x9EC5EA), sky2: Color(hex: 0xEAF2FA), sun: .white, m1: Color(hex: 0xE6EEF6), m2: Color(hex: 0x7E96B2), m3: Color(hex: 0x22334A),
         ink: C.bg, accent: Color(hex: 0x7FB5FF), night: false, prof: [1900, 2400, 2900, 3200, 3400, 3810, 3400, 2900, 2400, 1900], col: 1, dy: 0, h: 200),
    Trek(name: "Hampta Pass", alt: "4,270 m", days: "5 days", diff: "Moderate", season: "Jun–Sep",
         blurb: "Kullu to Lahaul. Green valleys on one side of the pass, stark high-desert on the other.",
         sky1: Color(hex: 0xF6C177), sky2: Color(hex: 0xF28C6B), sun: Color(hex: 0xFFF1C9), m1: Color(hex: 0x9A5B67), m2: Color(hex: 0x5E3448), m3: Color(hex: 0x22162A),
         ink: C.bg, accent: Color(hex: 0xF6C177), night: false, prof: [2900, 3200, 3500, 3700, 4270, 3800, 3600, 3900, 3300], col: 0, dy: 262, h: 200),
    Trek(name: "Valley of Flowers", alt: "3,658 m", days: "6 days", diff: "Easy", season: "Jul–Sep",
         blurb: "Chamoli, Uttarakhand. Alpine meadows that burst into bloom during the monsoon months.",
         sky1: Color(hex: 0xBFE3CB), sky2: Color(hex: 0xF4F1DE), sun: Color(hex: 0xFFF7D6), m1: Color(hex: 0x8DB580), m2: Color(hex: 0x4E7A45), m3: Color(hex: 0x1F3A26),
         ink: C.bg, accent: Color(hex: 0x9BD88A), night: false, prof: [1800, 2200, 3000, 3300, 3658, 3400, 3000, 2600, 2000], col: 1, dy: 212, h: 250),
]

let FAR: [CGPoint] = [(0, 100), (0, 55), (15, 35), (28, 50), (45, 18), (60, 45), (72, 28), (88, 48), (100, 36), (100, 100)].map { CGPoint(x: $0.0, y: $0.1) }
let MID: [CGPoint] = [(0, 100), (0, 60), (20, 38), (35, 58), (55, 28), (75, 55), (90, 40), (100, 52), (100, 100)].map { CGPoint(x: $0.0, y: $0.1) }
let NEAR: [CGPoint] = [(0, 100), (0, 48), (25, 28), (50, 52), (70, 34), (100, 58), (100, 100)].map { CGPoint(x: $0.0, y: $0.1) }

/// Polygon in a 0–100 box, stretched to fill (no aspect ratio kept).
struct Polygon: Shape {
    let pts: [CGPoint]
    func path(in r: CGRect) -> Path {
        var p = Path()
        for (i, pt) in pts.enumerated() {
            let q = CGPoint(x: r.minX + pt.x / 100 * r.width, y: r.minY + pt.y / 100 * r.height)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath()
        return p
    }
}

/// Animatable font size (Font itself is not animatable).
struct AnimatableFontSize: ViewModifier, Animatable {
    var size: CGFloat
    var animatableData: CGFloat { get { size } set { size = newValue } }
    func body(content: Content) -> some View { content.font(.system(size: size, weight: .bold)) }
}

/// Scale + rotate + fade used for the play/pause icon swap.
struct IconSwap: ViewModifier {
    let p: Double
    func body(content: Content) -> some View {
        content.scaleEffect(0.4 + 0.6 * p).rotationEffect(.degrees(-90 * (1 - p))).opacity(p)
    }
}
