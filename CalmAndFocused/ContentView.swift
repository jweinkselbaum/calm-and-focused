import SwiftUI

struct ContentView: View {
    @ObservedObject var engine: SoundEngine

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .background(Color.white.opacity(0.08))
            trackList
        }
        .frame(width: 280)
        .background(panelBackground)
    }

    private var header: some View {
        HStack {
            Text("Calm and Focused")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.85))
            Spacer()
            Circle()
                .fill(anyActive ? Color.green.opacity(0.7) : Color.white.opacity(0.15))
                .frame(width: 7, height: 7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var trackList: some View {
        VStack(spacing: 2) {
            ForEach($engine.tracks) { $track in
                TrackRow(track: $track, engine: engine)
            }
        }
        .padding(.vertical, 8)
    }

    private var panelBackground: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14)
            // Subtle noise texture
            Canvas { ctx, size in
                for _ in 0..<2000 {
                    let x = Double.random(in: 0...size.width)
                    let y = Double.random(in: 0...size.height)
                    let alpha = Double.random(in: 0.01...0.04)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                             with: .color(.white.opacity(alpha)))
                }
            }
        }
    }

    private var anyActive: Bool {
        engine.tracks.contains { $0.isActive }
    }
}

struct TrackRow: View {
    @Binding var track: SoundTrack
    let engine: SoundEngine

    var body: some View {
        HStack(spacing: 12) {
            Button {
                engine.setActive(!track.isActive, for: track.id)
            } label: {
                Image(systemName: track.symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(track.isActive ? .white : Color.white.opacity(0.35))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(track.name)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(track.isActive ? Color.white.opacity(0.9) : Color.white.opacity(0.4))
                .frame(width: 80, alignment: .leading)

            SkeSlider(value: Binding(
                get: { track.volume },
                set: { engine.setVolume($0, for: track.id) }
            ), isEnabled: track.isActive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            track.isActive
                ? Color.white.opacity(0.04)
                : Color.clear
        )
        .cornerRadius(6)
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.15), value: track.isActive)
    }
}

struct SkeSlider: View {
    @Binding var value: Double
    let isEnabled: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track groove
                Capsule()
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.8), lineWidth: 1)
                    )
                    .frame(height: 4)
                    .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [Color(red: 0.4, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.65, blue: 0.5)]
                                : [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, geo.size.width * value), height: 4)
                    .animation(.easeOut(duration: 0.08), value: value)

                // Thumb
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.92), Color(white: 0.78)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    .offset(x: max(0, min(geo.size.width - 14, geo.size.width * value - 7)))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let newVal = (drag.location.x) / geo.size.width
                                value = max(0, min(1, newVal))
                            }
                    )
            }
            .frame(height: 14)
        }
        .frame(height: 14)
        .opacity(isEnabled ? 1.0 : 0.4)
    }
}
