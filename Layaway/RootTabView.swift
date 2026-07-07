import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            PlanListView()
                .tabItem { Label("Plans", systemImage: "ticket.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(LWTheme.copper)
    }
}
