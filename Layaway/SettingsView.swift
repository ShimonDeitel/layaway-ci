import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: LayawayStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("layaway_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("layaway_due_reminder_enabled") private var dueReminderEnabled: Bool = false

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: LayawaySheetMode?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if purchases.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.gold)
                            Text("Layaway Pro active")
                        }
                    } else {
                        Button {
                            sheetMode = .paywall
                        } label: {
                            HStack {
                                Image(systemName: "star.fill").foregroundStyle(Theme.gold)
                                Text("Unlock Layaway Pro")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsUnlockProButton")
                    }
                }

                Section("Plans") {
                    Text("\(store.plans.count) plan\(store.plans.count == 1 ? "" : "s") \(purchases.isPro ? "" : "(free: \(LayawayStore.freePlanLimit))")")
                        .foregroundStyle(.secondary)
                }

                Section("Preferences") {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Haptics", systemImage: "hand.tap.fill")
                    }
                    .tint(Theme.gold)

                    Toggle(isOn: $dueReminderEnabled) {
                        Label("Remind me near due dates", systemImage: "bell.badge.fill")
                    }
                    .tint(Theme.gold)
                    .accessibilityIdentifier("dueReminderToggle")

                    Button {
                        Task { await purchases.restore() }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }

                Section("About") {
                    Link(destination: URL(string: "https://shimondeitel.github.io/layaway-site/privacy.html")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://shimondeitel.github.io/layaway-site/terms.html")!) {
                        Label("Terms of Use", systemImage: "doc.text.fill")
                    }
                    Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .sheet(item: $sheetMode) { mode in
                if case .paywall = mode {
                    PaywallView().environmentObject(purchases)
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every plan and payment. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    SettingsView()
        .environmentObject(LayawayStore())
        .environmentObject(PurchaseManager())
}
