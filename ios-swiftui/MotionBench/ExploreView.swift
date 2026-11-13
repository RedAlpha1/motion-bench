import SwiftUI

private let GRID_TOP: CGFloat = 200
private let CHIPS = ["All", "Himachal", "Uttarakhand", "Winter", "Beginner"]

private struct Star: View {
    let x, y, size, period, delay: Double
    @State private var on = false
    var body: some View {
        GeometryReader { g in
            Circle().fill(.white).frame(width: size, height: size)
                .opacity(on ? 1 : 0.2)
                .position(x: g.size.width * x, y: g.size.height * y)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: period / 2).repeatForever(autoreverses: true).delay(delay)) { on = true }
        }
    }
}

private struct TrekCard: View {
    let k: Trek
    let i: Int
    let open: Int
    let lastOpened: Int
    let full: CGSize
    let onOpen: () -> Void

    var body: some View {
        let me = open == i
        let colW = (full.width - 60) / 2
        let x: CGFloat = 24 + CGFloat(k.col) * (colW + 12)
        let y: CGFloat = GRID_TOP + k.dy
        let w = me ? full.width : colW
        let h = me ? full.height : k.h
        let sun: CGFloat = me ? 64 : 30
        let fade = open >= 0 && !me

        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [k.sky1, k.sky2], startPoint: .top, endPoint: .bottom)
            if k.night {
                ZStack {
                    Star(x: 0.18, y: 0.09, size: 3, period: 2.1, delay: 0)
                    Star(x: 0.42, y: 0.05, size: 2, period: 1.6, delay: 0.4)
                    Star(x: 0.70, y: 0.13, size: 3, period: 2.6, delay: 0.9)
                    Star(x: 0.86, y: 0.06, size: 2, period: 1.9, delay: 0.2)
                    Star(x: 0.30, y: 0.18, size: 2, period: 2.3, delay: 1.1)
                    Star(x: 0.58, y: 0.22, size: 2, period: 1.7, delay: 0.7)
                }
            }
            Circle().fill(k.sun)
                .frame(width: sun, height: sun)
                .shadow(color: k.sun.opacity(0.7), radius: 20)
                .offset(x: w * (me ? 0.68 : 0.6), y: h * (me ? 0.15 : 0.14))
            layer(FAR, 0.70, lift: me ? 150 : 0, color: k.m1, h: h, delay: 0)
            layer(MID, 0.50, lift: me ? 190 : 0, color: k.m2, h: h, delay: 0.05)
            layer(NEAR, 0.34, lift: me ? 232 : 0, color: k.m3, h: h, delay: 0.10)
            VStack(alignment: .leading, spacing: 4) {
                Text(k.name).modifier(AnimatableFontSize(size: me ? 38 : 18))
                Text("\(k.alt) · \(k.days)").font(.system(size: 12, weight: .medium)).opacity(0.85)
            }
            .foregroundStyle(me ? k.ink : .white)
            .padding(.trailing, 14)
            .offset(x: me ? 24 : 14, y: me ? 84 : k.h - 62)
        }
        .frame(width: w, height: h, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: me ? 0 : 26, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { if open < 0 { onOpen() } }
        .accessibilityLabel("Open \(k.name)")
        .accessibilityAddTraits(.isButton)
        .offset(x: me ? 0 : x, y: me ? 0 : y)
        .animation(Ease.frame, value: open)
        .opacity(fade ? 0 : 1)
        .scaleEffect(fade ? 0.88 : 1)
        .animation(.easeInOut(duration: 0.35), value: open)
        .zIndex(lastOpened == i ? 30 : 1)
    }

    private func layer(_ pts: [CGPoint], _ frac: CGFloat, lift: CGFloat, color: Color, h: CGFloat, delay: Double) -> some View {
        Polygon(pts: pts).fill(color)
            .frame(height: h * frac)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .offset(y: -lift)
            .animation(.timingCurve(0.2, 0.9, 0.1, 1, duration: 0.9).delay(delay), value: lift)
    }
}

private struct Elevation: Shape {
    let prof: [Double]
    let closed: Bool
    func path(in r: CGRect) -> Path {
        let pad: CGFloat = 6
        let mx = prof.max()!, mn = prof.min()!
        var p = Path()
        for (i, v) in prof.enumerated() {
            let pt = CGPoint(x: r.minX + CGFloat(i) * r.width / CGFloat(prof.count - 1),
                             y: r.maxY - pad - CGFloat((v - mn) / (mx - mn)) * (r.height - pad * 2))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        if closed { p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath() }
        return p
    }
}

private struct Rise: ViewModifier {
    let shown: Bool
    let delay: Double
    func body(content: Content) -> some View {
        content.opacity(shown ? 1 : 0).offset(y: shown ? 0 : 22)
            .animation(Ease.sheet(0.6).delay(delay), value: shown)
    }
}

private struct SheetView: View {
    let k: Trek
    let onClose: () -> Void
    @State private var shown = false
    @State private var shimmer = false

    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                roundButton("xmark", label: "Close trek details", action: onClose).popIn(shown, delay: 0.45)
                Spacer()
                roundButton("bookmark", label: "Save trek", action: {}).popIn(shown, delay: 0.55)
            }
            .padding(24)

            VStack(alignment: .leading, spacing: 16) {
                Capsule().fill(Color(hex: 0x2A2A36)).frame(width: 40, height: 4).frame(maxWidth: .infinity)
                Text(k.blurb).font(.system(size: 14)).foregroundStyle(Color(hex: 0xB8B8C4)).lineSpacing(4)
                    .modifier(Rise(shown: shown, delay: 0.45))
                HStack(spacing: 8) {
                    ForEach(Array([("ALTITUDE", k.alt), ("DURATION", k.days), ("GRADE", k.diff), ("SEASON", k.season)].enumerated()), id: \.offset) { j, kv in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(kv.0).font(.system(size: 10)).foregroundStyle(C.muted)
                            Text(kv.1).font(.system(size: 14, weight: .bold)).foregroundStyle(C.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10).padding(.horizontal, 8)
                        .background(RoundedRectangle(cornerRadius: 16).fill(C.surface).overlay(RoundedRectangle(cornerRadius: 16).stroke(C.border)))
                        .modifier(Rise(shown: shown, delay: 0.5 + Double(j) * 0.07))
                    }
                }
                VStack(spacing: 8) {
                    HStack { Text("Elevation profile"); Spacer(); Text("\(k.alt) summit") }
                        .font(.system(size: 12)).foregroundStyle(C.muted)
                    ZStack {
                        Elevation(prof: k.prof, closed: true).fill(k.accent.opacity(0.12))
                        Elevation(prof: k.prof, closed: false)
                            .trim(from: 0, to: shown ? 1 : 0)
                            .stroke(k.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            .animation(Ease.draw.delay(0.85), value: shown)
                    }
                    .frame(height: 84)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 20).fill(C.surface).overlay(RoundedRectangle(cornerRadius: 20).stroke(C.border)))
                .modifier(Rise(shown: shown, delay: 0.7))
                Spacer(minLength: 0)
                Button {} label: {
                    ZStack {
                        GeometryReader { g in
                            Rectangle().fill(.white.opacity(0.45)).frame(width: 60)
                                .rotationEffect(.degrees(20))
                                .offset(x: shimmer ? g.size.width + 20 : -100)
                        }
                        Text("Check batch dates  →").font(.system(size: 16, weight: .bold)).foregroundStyle(C.bg)
                    }
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(C.lime)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .modifier(Rise(shown: shown, delay: 0.85))
            }
            .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 24)
            .frame(height: 452)
            .background(UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32).fill(C.bg))
            .frame(maxHeight: .infinity, alignment: .bottom)
            .offset(y: shown ? 0 : 480)
            .animation(Ease.sheet(0.75).delay(0.18), value: shown)
        }
        .onAppear {
            shown = true
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: false).delay(1.4)) { shimmer = true }
        }
    }

    private func roundButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private extension View {
    func popIn(_ shown: Bool, delay: Double) -> some View {
        self.scaleEffect(shown ? 1 : 0.6).opacity(shown ? 1 : 0)
            .animation(Ease.back.delay(delay), value: shown)
    }
}

struct ExploreView: View {
    let bench: Bench
    @State private var open = -1
    @State private var lastOpened = -1
    @State private var chip = 0
    @State private var query = ""

    private func setOpen(_ i: Int) {
        if i >= 0 { lastOpened = i }
        open = i
    }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("HIMALAYA · WINTER 2026").font(.system(size: 12)).tracking(1).foregroundStyle(C.muted)
                    Text("Explore treks").font(.system(size: 28, weight: .bold)).foregroundStyle(C.text).padding(.top, -8)
                    TextField("", text: $query, prompt: Text("Search treks, passes, regions").foregroundStyle(Color(hex: 0x8C8C99)))
                        .foregroundStyle(C.text).font(.system(size: 15))
                        .padding(.horizontal, 16).frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 16).fill(C.surface).overlay(RoundedRectangle(cornerRadius: 16).stroke(C.border)))
                        .accessibilityLabel("Search treks")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(CHIPS.enumerated()), id: \.offset) { i, c in
                                Button { chip = i } label: {
                                    Text(c).font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(i == chip ? C.bg : C.soft)
                                        .padding(.horizontal, 16).frame(height: 36)
                                        .background(Capsule().fill(i == chip ? C.text : Color(hex: 0x121218)))
                                        .overlay(Capsule().stroke(i == chip ? C.text : Color(hex: 0x23232D)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.top, 16)
                .opacity(open >= 0 ? 0 : 1)
                .offset(y: open >= 0 ? -20 : 0)
                .animation(Ease.sheet(0.5), value: open)

                ForEach(Array(TREKS.enumerated()), id: \.offset) { i, k in
                    TrekCard(k: k, i: i, open: open, lastOpened: lastOpened, full: g.size) { setOpen(i) }
                }

                if open >= 0 {
                    SheetView(k: TREKS[open]) { setOpen(-1) }
                        .id(open)
                        .zIndex(40)
                        .transition(.identity)
                }
            }
        }
        .background(C.bg)
        .task(id: bench.auto) {
            guard bench.auto else { return }
            var i = 0
            defer { setOpen(-1) }
            while !Task.isCancelled {
                setOpen(i)
                try? await Task.sleep(for: .milliseconds(1600))
                if Task.isCancelled { break }
                setOpen(-1)
                try? await Task.sleep(for: .milliseconds(900))
                i = (i + 1) % TREKS.count
            }
        }
    }
}
