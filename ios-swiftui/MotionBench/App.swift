import SwiftUI

@main
struct MotionBenchApp: App {
    var body: some Scene {
        WindowGroup { RootView().preferredColorScheme(.dark) }
    }
}

private struct Pill: View {
    let label: String
    let on: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(on ? C.bg : C.soft)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Capsule().fill(on ? C.text : C.bg))
                .overlay(Capsule().stroke(on ? C.text : C.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct RootView: View {
    @State private var screen = "player"
    @State private var bench = Bench()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Pill(label: "Player", on: screen == "player") { screen = "player" }
                Pill(label: "Explore", on: screen == "explore") { screen = "explore" }
                Spacer()
                Pill(label: "Load \(bench.load)×", on: bench.load == 4) { bench.load = bench.load == 1 ? 4 : 1 }
                Pill(label: "Auto", on: bench.auto) { bench.auto.toggle() }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            Rectangle().fill(C.border).frame(height: 1)
            ZStack {
                if screen == "player" { PlayerView(bench: bench) } else { ExploreView(bench: bench) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .background(C.bg.ignoresSafeArea())
    }
}
