import SwiftUI

struct ContentView: View {
    @EnvironmentObject var prefs: PreferencesManager
    @EnvironmentObject var engine: SoundEngine
    var onOpenPreferences: () -> Void
    var onQuit: () -> Void

    private var theme: AppTheme { AppTheme.current(for: prefs.themeID) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.18)
            trackList
            Divider().opacity(0.18)
            footer
        }
        .frame(width: 280)
        .background(PanelBackground(theme: theme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Calm and Focused")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.80))
            Spacer()
            Circle()
                .fill(anyActive ? theme.accent : Color.white.opacity(0.14))
                .frame(width: 7, height: 7)
                .animation(.easeInOut(duration: 0.3), value: anyActive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: Track list

    private var trackList: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(prefs.enabledTracks()) { track in
                    TrackRow(track: track, theme: theme)
                        .environmentObject(prefs)
                        .environmentObject(engine)
                }
            }
            .padding(.vertical, 6)
        }
        .frame(maxHeight: 52 * CGFloat(min(prefs.enabledSoundIDs.count, 5)))
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button { onOpenPreferences() } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Preferences")

            Button { onQuit() } label: {
                Image(systemName: "power")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var anyActive: Bool {
        prefs.enabledTracks().contains { prefs.isActive($0.id) }
    }
}

// MARK: - Track Row

private struct TrackRow: View {
    let track: SoundTrack
    let theme: AppTheme
    @EnvironmentObject var prefs: PreferencesManager
    @EnvironmentObject var engine: SoundEngine

    private var isActive: Bool { prefs.isActive(track.id) }
    private var volume: Double { prefs.volume(for: track.id) }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                let next = !isActive
                engine.setActive(next, for: track.id)
                prefs.setActive(next, for: track.id)
                if next { engine.setVolume(volume, for: track.id) }
            } label: {
                Image(systemName: track.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isActive ? theme.accent : Color.white.opacity(0.30))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: isActive)

            Text(track.name)
                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                .foregroundStyle(isActive ? Color.white.opacity(0.88) : Color.white.opacity(0.35))
                .frame(width: 78, alignment: .leading)
                .animation(.easeInOut(duration: 0.15), value: isActive)

            WoodSlider(
                value: Binding(
                    get: { volume },
                    set: { v in
                        prefs.setVolume(v, for: track.id)
                        engine.setVolume(v, for: track.id)
                    }
                ),
                accent: theme.accent,
                isEnabled: isActive
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(isActive ? Color.white.opacity(0.045) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 6)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

// MARK: - Skeuomorphic Slider

private struct WoodSlider: View {
    @Binding var value: Double
    let accent: Color
    let isEnabled: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Inset groove
                Capsule()
                    .fill(Color.black.opacity(0.45))
                    .frame(height: 4)
                    .shadow(color: .black.opacity(0.7), radius: 1, y: 1)

                // Fill bar
                Capsule()
                    .fill(LinearGradient(
                        colors: isEnabled
                            ? [accent.opacity(0.9), accent.opacity(0.55)]
                            : [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(4, geo.size.width * value), height: 4)

                // Thumb knob
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(white: 0.90), Color(white: 0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                    .offset(x: max(0, min(geo.size.width - 14, geo.size.width * value - 7)))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                value = max(0, min(1, drag.location.x / geo.size.width))
                            }
                    )
            }
            .frame(height: 14)
        }
        .frame(height: 14)
        .opacity(isEnabled ? 1.0 : 0.38)
        .animation(.easeOut(duration: 0.1), value: value)
    }
}

// MARK: - Panel Background

struct PanelBackground: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            theme.base

            switch theme.grain {
            case .wood:   WoodGrain().drawingGroup()
            case .subtle: SubtleNoise().drawingGroup()
            case .none:   EmptyView()
            }

            // Vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.30)],
                center: .center,
                startRadius: 60,
                endRadius: 160
            )
        }
    }
}

private struct WoodGrain: View {
    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(seed: 1337)

            // Horizontal grain lines
            for _ in 0..<110 {
                let baseY = rng.next() * size.height
                let opacity = rng.next() * 0.07 + 0.025
                let lineW = rng.next() * 1.2 + 0.4
                let period = rng.next() * 80 + 40
                let amplitude = rng.next() * size.height * 0.012
                let phase = rng.next() * .pi * 2
                let r = 0.42 + rng.next() * 0.18
                let g = 0.24 + rng.next() * 0.10
                let b = 0.06 + rng.next() * 0.06

                var path = Path()
                let steps = Int(size.width / 2) + 1
                for s in 0..<steps {
                    let x = Double(s) * 2
                    let y = baseY + amplitude * sin(2 * .pi * x / period + phase)
                    if s == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }

                ctx.stroke(path, with: .color(Color(red: r, green: g, blue: b).opacity(opacity)),
                           style: StrokeStyle(lineWidth: lineW, lineCap: .round))
            }

            // Knot rings (2)
            for _ in 0..<2 {
                let cx = rng.next() * size.width
                let cy = rng.next() * size.height
                for ring in 0..<5 {
                    let rx = (Double(ring) + 1) * (size.width * 0.06)
                    let ry = (Double(ring) + 1) * (size.height * 0.03)
                    let opacity = (0.06 - Double(ring) * 0.01)
                    let path = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
                    ctx.stroke(path, with: .color(Color(red: 0.45, green: 0.25, blue: 0.07).opacity(opacity)),
                               lineWidth: 0.8)
                }
            }
        }
    }
}

private struct SubtleNoise: View {
    var body: some View {
        Canvas { ctx, size in
            for _ in 0..<1800 {
                let x = Double.random(in: 0...size.width)
                let y = Double.random(in: 0...size.height)
                let a = Double.random(in: 0.015...0.045)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                         with: .color(.white.opacity(a)))
            }
        }
    }
}

// MARK: - Seeded RNG (for stable woodgrain between redraws)

private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(UInt64(1) << 31)
    }
}
