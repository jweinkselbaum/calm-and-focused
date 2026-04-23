import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var prefs: PreferencesManager
    @EnvironmentObject var engine: SoundEngine

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }
                .environmentObject(prefs)

            AppearanceTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
                .environmentObject(prefs)

            SoundsTab()
                .tabItem { Label("Sounds", systemImage: "speaker.wave.2") }
                .environmentObject(prefs)
                .environmentObject(engine)
        }
        .frame(width: 460, height: 320)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @EnvironmentObject var prefs: PreferencesManager

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { prefs.launchAtLogin },
                    set: { prefs.setLaunchAtLogin($0) }
                ))
                Toggle("Show icon in Dock", isOn: Binding(
                    get: { prefs.showInDock },
                    set: { prefs.setShowInDock($0) }
                ))
            }

            Section {
                Link("View on GitHub",
                     destination: URL(string: "https://github.com/jweinkselbaum/calm-and-focused")!)
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}

// MARK: - Appearance

private struct AppearanceTab: View {
    @EnvironmentObject var prefs: PreferencesManager
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ThemeID.allCases, id: \.self) { id in
                    ThemeSwatch(id: id, selected: prefs.themeID == id)
                        .onTapGesture { prefs.setTheme(id) }
                }
            }
            Spacer()
        }
        .padding(20)
    }
}

private struct ThemeSwatch: View {
    let id: ThemeID
    let selected: Bool
    private var theme: AppTheme { AppTheme.current(for: id) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.base)
                    .frame(width: 60, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selected ? theme.accent : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
                    )

                HStack(spacing: 3) {
                    ForEach([0.5, 1.0, 0.7], id: \.self) { h in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.accent.opacity(0.9))
                            .frame(width: 5, height: 22 * h)
                    }
                }
            }
            Text(id.displayName)
                .font(.system(size: 11))
                .foregroundStyle(selected ? .primary : .secondary)
        }
    }
}

// MARK: - Sounds

private struct SoundsTab: View {
    @EnvironmentObject var prefs: PreferencesManager
    @EnvironmentObject var engine: SoundEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose which sounds appear in the menu bar. Drag to reorder.")
                .foregroundStyle(.secondary)
                .font(.callout)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            List {
                ForEach(SoundTrack.library) { track in
                    SoundLibraryRow(track: track)
                        .environmentObject(prefs)
                        .environmentObject(engine)
                }
                .onMove { from, to in
                    // Only reorder within enabled sounds
                    var enabled = prefs.enabledSoundIDs
                    let all = SoundTrack.library
                    let fromIDs = from.map { all[$0].id }
                    // Move in enabled list if all source items are enabled
                    let movingEnabled = fromIDs.allSatisfy { enabled.contains($0) }
                    if movingEnabled {
                        let enabledFrom = IndexSet(fromIDs.compactMap { enabled.firstIndex(of: $0) })
                        let enabledTo = min(to, enabled.count)
                        enabled.move(fromOffsets: enabledFrom, toOffset: enabledTo)
                        prefs.enabledSoundIDs = enabled
                    }
                }
            }
            .listStyle(.inset)
        }
    }
}

private struct SoundLibraryRow: View {
    let track: SoundTrack
    @EnvironmentObject var prefs: PreferencesManager
    @EnvironmentObject var engine: SoundEngine

    private var isEnabled: Bool { prefs.enabledSoundIDs.contains(track.id) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(isEnabled ? Color.secondary : Color.secondary.opacity(0.3))
                .font(.system(size: 13))

            Image(systemName: track.symbol)
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
                .frame(width: 20)

            Text(track.name)
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { on in
                    if !on { engine.setActive(false, for: track.id) }
                    prefs.setSoundEnabled(on, id: track.id)
                }
            ))
            .labelsHidden()
        }
    }
}
