import AppKit
import ServiceManagement

@MainActor
final class PreferencesManager: ObservableObject {
    private static let defaultEnabledIDs = ["rain", "vinyl", "whiteNoise"]

    @Published var enabledSoundIDs: [String]
    @Published var volumes: [String: Double]
    @Published var activeStates: [String: Bool]
    @Published var themeID: ThemeID
    @Published var showInDock: Bool
    @Published var launchAtLogin: Bool

    init() {
        let ud = UserDefaults.standard

        enabledSoundIDs = ud.stringArray(forKey: "enabledSoundIDs") ?? Self.defaultEnabledIDs

        if let data = ud.data(forKey: "volumes"),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            volumes = decoded
        } else {
            volumes = Dictionary(uniqueKeysWithValues: SoundTrack.library.map { ($0.id, 0.5) })
        }

        if let data = ud.data(forKey: "activeStates"),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            activeStates = decoded
        } else {
            activeStates = [:]
        }

        themeID = ThemeID(rawValue: ud.string(forKey: "themeID") ?? "") ?? .wood
        showInDock = ud.bool(forKey: "showInDock")
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Sound management

    func enabledTracks() -> [SoundTrack] {
        enabledSoundIDs.compactMap { id in SoundTrack.library.first { $0.id == id } }
    }

    func setSoundEnabled(_ enabled: Bool, id: String) {
        if enabled {
            if !enabledSoundIDs.contains(id) {
                enabledSoundIDs.append(id)
                save(\.enabledSoundIDs, key: "enabledSoundIDs")
            }
        } else {
            enabledSoundIDs.removeAll { $0 == id }
            activeStates[id] = false
            save(\.enabledSoundIDs, key: "enabledSoundIDs")
            saveActiveStates()
        }
    }

    func moveSounds(from: IndexSet, to: Int) {
        enabledSoundIDs.move(fromOffsets: from, toOffset: to)
        save(\.enabledSoundIDs, key: "enabledSoundIDs")
    }

    func volume(for id: String) -> Double { volumes[id] ?? 0.5 }
    func isActive(_ id: String) -> Bool { activeStates[id] ?? false }

    func setVolume(_ v: Double, for id: String) {
        volumes[id] = v
        saveVolumes()
    }

    func setActive(_ active: Bool, for id: String) {
        activeStates[id] = active
        saveActiveStates()
    }

    // MARK: - App settings

    func setTheme(_ id: ThemeID) {
        themeID = id
        UserDefaults.standard.set(id.rawValue, forKey: "themeID")
    }

    func setShowInDock(_ show: Bool) {
        showInDock = show
        UserDefaults.standard.set(show, forKey: "showInDock")
        NSApp.setActivationPolicy(show ? .regular : .accessory)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("SMAppService: \(error)")
        }
    }

    // MARK: - Persistence

    private func saveVolumes() {
        if let data = try? JSONEncoder().encode(volumes) {
            UserDefaults.standard.set(data, forKey: "volumes")
        }
    }

    private func saveActiveStates() {
        if let data = try? JSONEncoder().encode(activeStates) {
            UserDefaults.standard.set(data, forKey: "activeStates")
        }
    }

    private func save(_ keyPath: KeyPath<PreferencesManager, [String]>, key: String) {
        UserDefaults.standard.set(self[keyPath: keyPath], forKey: key)
    }
}
