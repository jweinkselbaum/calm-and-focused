import SwiftUI

@main
struct CalmAndFocusedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
                .environmentObject(appDelegate.preferencesManager)
                .environmentObject(appDelegate.soundEngine)
        }
    }
}
