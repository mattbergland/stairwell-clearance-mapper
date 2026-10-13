import SwiftUI

@main
struct StairwellClearanceMapperApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $state.selectedTab) {
                NavigationStack {
                    RouteView()
                }
                .tabItem { Label("Route", systemImage: "map") }
                .tag(0)

                NavigationStack {
                    FitCheckView()
                }
                .tabItem { Label("Fit Check", systemImage: "checkmark.shield") }
                .tag(1)

                NavigationStack {
                    PianosView()
                }
                .tabItem { Label("Pianos", systemImage: "music.note.list") }
                .tag(2)

                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
            }
            .environment(state)
            .task { await state.loadLibrary() }
        }
    }
}
