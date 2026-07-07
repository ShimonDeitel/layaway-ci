import SwiftUI

@main
struct LayawayApp: App {
    @StateObject private var store = LayawayStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
