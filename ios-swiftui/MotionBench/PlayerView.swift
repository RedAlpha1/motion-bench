import SwiftUI

// Time-based helpers: every continuous loop is a pure function of "play time",
// so pausing freezes everything in place and resuming continues from there.
private func easeInOut(_ x: Double) -> Double { x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2 }
private func pingPong(_ t: Double, _ dur: Double) -> Double {
    let c = t / dur
    let k = floor(c)
    let f = c - k
    return easeInOut(Int(k) % 2 == 0 ? f : 1 - f)
}
private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat { a + (b - a) * CGFloat(t) }

/// 0 → mid → end → mid → 0, each leg `dur/2`.
private func orbOffset(_ t: Double, dur: Double, mid: CGSize, end: CGSize) -> CGSize {
    let half = dur / 2
    let c = (t / half).truncatingRemainder(dividingBy: 4)
    let leg = Int(c)
    let f = easeInOut(c - Double(leg))
    let pts = [CGSize.zero, mid, end, mid, .zero]
    let a = pts[leg], b = pts[leg + 1]
    return CGSize(width: lerp(a.width, b.width, f), height: lerp(a.height, b.height, f))
}

struct PlayerView: View {
    let bench: Bench

    @State private var playing = true
    @State private var progress: Double = 0.06
    @State private var track = 0
    @State private var liked = false
    @State private var likeTaps = 0
    @State private var accumulated: Double = 0
    @State private var resumedAt: Date? = Date()

    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private var t: Track { TRACKS[track] }

    private func playTime(_ d: Date) -> Double { accumulated + (resumedAt.map { d.timeIntervalSince($0) } ?? 0) }

    private func togglePlay() {
        if playing { accumulated = playTime(Date()); resumedAt = nil } else { resumedAt = Date() }
        playing.toggle()
    }

    private func go(_ dir: Int) {
        withAnimation(Ease.sheet(0.55)) { track = (track + dir + 3) % 3 }
        progress = 0
    }

    private var idx: Int { min(LYRICS.count - 1, Int(progress * Double(LYRICS.count))) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Orbs
            TimelineView(.animation(paused: !playing)) { ctx in
                let tt = playTime(ctx.date)
                ZStack(alignment: .topLeading) {
                    orb(t.orbA, 320).offset(orbOffset(tt, dur: 11, mid: CGSize(width: 60, height: 40), end: CGSize(width: -30, height: 90)))
                        .offset(x: -120, y: -60)
                    GeometryReader { g in
                        orb(t.orbB, 280).offset(orbOffset(tt, dur: 13, mid: CGSize(width: -70, height: -30), end: CGSize(width: 20, height: -80)))
                            .offset(x: g.size.width - 170, y: 260)
                    }
                }
            }
            .allowsHitTesting(false)
            .animation(.linear(duration: 1), value: track)

            VStack(spacing: 16) {
                disc
                titleRow
                equalizer
                seekBar
                controls
                lyrics
            }
            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 16)
        }
        .onReceive(tick) { _ in
            guard playing else { return }
            if progress + 0.0025 >= 1 { go(1) } else { progress += 0.0025 }
        }
    }

    private func orb(_ c: Color, _ s: CGFloat) -> some View {
        Circle().fill(RadialGradient(colors: [c.opacity(0.5), c.opacity(0)], center: .center, startRadius: 0, endRadius: s / 2))
            .frame(width: s, height: s)
    }

    private var disc: some View {
        ZStack(alignment: .topLeading) {
            TimelineView(.animation(paused: !playing)) { ctx in
                let tt = playTime(ctx.date)
                let b = pingPong(tt, 0.47)
                ZStack {
                    Circle().stroke(t.color, lineWidth: 2)
                        .frame(width: 296, height: 296)
                        .scaleEffect(0.96 + 0.1 * b).opacity(0.45 + 0.4 * b)
                    ZStack {
                        Canvas { cx, size in
                            let c = CGPoint(x: size.width / 2, y: size.height / 2)
                            cx.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x15151B)))
                            let n = 24 * bench.load
                            for i in 0..<n {
                                let r = 40 + 92 * CGFloat(i) / CGFloat(n - 1)
                                cx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                                          with: .color(i % 2 == 1 ? Color(hex: 0x1E1E27) : Color(hex: 0x111116)), lineWidth: 1.5)
                            }
                            var w = Path(); w.move(to: c)
                            w.addArc(center: c, radius: 134, startAngle: .degrees(-50), endAngle: .degrees(-28), clockwise: false)
                            w.closeSubpath()
                            cx.fill(w, with: .color(.white.opacity(0.06)))
                        }
                        ZStack {
                            Circle().fill(t.color)
                            Text(t.mono).font(.system(size: 24, weight: .bold)).foregroundStyle(C.bg)
                            Circle().fill(C.bg).frame(width: 10, height: 10)
                        }
                        .frame(width: 104, height: 104)
                    }
                    .frame(width: 268, height: 268)
                    .rotationEffect(.degrees((tt / 5).truncatingRemainder(dividingBy: 1) * 360))
                }
                .frame(width: 268, height: 268)
            }
            tonearm
                .frame(width: 120, height: 170)
                .rotationEffect(.degrees(playing ? 22 : 0), anchor: UnitPoint(x: 96.0 / 120, y: 22.0 / 170))
                .animation(.interpolatingSpring(stiffness: 170, damping: 12), value: playing)
                .offset(x: 192, y: -26)
                .allowsHitTesting(false)
        }
        .frame(width: 268, height: 268)
        .animation(.linear(duration: 0.8), value: track)
        .frame(maxWidth: .infinity)
    }

    private var tonearm: some View {
        ZStack(alignment: .topLeading) {
            Path { p in p.move(to: CGPoint(x: 96, y: 22)); p.addLine(to: CGPoint(x: 90, y: 120)); p.addLine(to: CGPoint(x: 62, y: 150)) }
                .stroke(C.soft, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xE9E9EF)).frame(width: 26, height: 18)
                .rotationEffect(.degrees(-40)).position(x: 61, y: 149)
            Circle().fill(Color(hex: 0x23232D)).overlay(Circle().stroke(Color(hex: 0x3A3A47), lineWidth: 2))
                .frame(width: 32, height: 32).position(x: 96, y: 22)
            Circle().fill(Color(hex: 0x6E6E7A)).frame(width: 12, height: 12).position(x: 96, y: 22)
        }
    }

    private var titleRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(t.title).font(.system(size: 26, weight: .bold)).foregroundStyle(C.text)
                Text(t.artist).font(.system(size: 14)).foregroundStyle(Color(hex: 0xA3A3AF))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(track)
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 14)), removal: .identity))

            Button { liked.toggle(); likeTaps += 1 } label: {
                Image(systemName: liked ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(liked ? C.heart : C.soft)
                    .keyframeAnimator(initialValue: 1.0, trigger: likeTaps) { v, s in v.scaleEffect(s) } keyframes: { _ in
                        LinearKeyframe(1.45, duration: 0.18)
                        SpringKeyframe(1.0, duration: 0.27)
                    }
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(liked ? "Remove from liked songs" : "Add to liked songs")
        }
        .padding(.top, 6)
    }

    private var equalizer: some View {
        let n = 32 * bench.load
        let w: CGFloat = bench.load == 4 ? 2 : 5
        return TimelineView(.animation(paused: !playing)) { ctx in
            let tt = playTime(ctx.date)
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<n, id: \.self) { i in
                    let dur = 0.32 + Double((i * 37) % 23) / 40
                    let phase = Double((i * 53) % 17) / 20
                    let s = 0.12 + 0.88 * pingPong(tt + phase * dur, dur)
                    let c: Color = i % 3 == 0 ? t.color : (i % 3 == 1 ? C.text.opacity(0.55) : C.text.opacity(0.25))
                    RoundedRectangle(cornerRadius: 3).fill(c)
                        .frame(width: w, height: BAR_H[i % 32])
                        .scaleEffect(x: 1, y: s, anchor: .bottom)
                    if i < n - 1 { Spacer(minLength: 0) }
                }
            }
            .frame(height: 44)
        }
    }

    private var seekBar: some View {
        VStack(spacing: 6) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12)).frame(height: 5)
                    Capsule().fill(t.color).frame(width: g.size.width * progress, height: 5)
                    Circle().fill(C.text).frame(width: 16, height: 16).offset(x: g.size.width * progress - 8)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { loc in progress = min(0.999, max(0, loc.x / g.size.width)) }
            }
            .frame(height: 22)
            HStack {
                Text(fmt(progress * t.len)); Spacer(); Text(fmt(t.len))
            }
            .font(.system(size: 12).monospacedDigit()).foregroundStyle(C.muted)
        }
    }

    private var controls: some View {
        HStack(spacing: 36) {
            Button { go(-1) } label: { Image(systemName: "backward.end.fill").font(.system(size: 26)).frame(width: 56, height: 56) }
                .accessibilityLabel("Previous track")
            Button(action: togglePlay) {
                ZStack {
                    RoundedRectangle(cornerRadius: playing ? 28 : 40, style: .continuous).fill(t.color)
                        .animation(.interpolatingSpring(stiffness: 220, damping: 14), value: playing)
                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 28)).foregroundStyle(C.bg)
                        .id(playing)
                        .transition(.asymmetric(insertion: .modifier(active: IconSwap(p: 0), identity: IconSwap(p: 1)), removal: .identity))
                        .animation(Ease.back, value: playing)
                }
                .frame(width: 80, height: 80)
            }
            .accessibilityLabel(playing ? "Pause" : "Play")
            Button { go(1) } label: { Image(systemName: "forward.end.fill").font(.system(size: 26)).frame(width: 56, height: 56) }
                .accessibilityLabel("Next track")
        }
        .buttonStyle(.plain)
        .foregroundStyle(C.text)
        .animation(.linear(duration: 0.8), value: track)
    }

    private var lyrics: some View {
        RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.06), lineWidth: 1))
            .frame(maxHeight: .infinity)
            .frame(minHeight: 132)
            // overlay so the 352-pt column never changes the box's size
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(LYRICS.enumerated()), id: \.offset) { i, line in
                        let d = abs(i - idx)
                        Text(line)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(d == 0 ? Color.white : C.soft)
                            .lineLimit(1)
                            .frame(height: 44)
                            .scaleEffect(d == 0 ? 1.04 : 1, anchor: .leading)
                            .opacity(d == 0 ? 1 : (d == 1 ? 0.4 : 0.18))
                            .animation(.interpolatingSpring(stiffness: 180, damping: 10), value: idx)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 22)
                .offset(y: CGFloat(44 - idx * 44))
                .animation(.interpolatingSpring(stiffness: 140, damping: 14), value: idx)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func fmt(_ s: Double) -> String { String(format: "%d:%02d", Int(s) / 60, Int(s) % 60) }
}
