import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            PlanListView()
                .tabItem {
                    Label("Home", systemImage: "creditcard.and.123")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Theme.gold)
    }
}

#Preview {
    RootTabView()
        .environmentObject(LayawayStore())
        .environmentObject(PurchaseManager())
}
