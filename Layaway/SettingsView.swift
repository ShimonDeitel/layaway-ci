import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: LayawayStore
    @EnvironmentObject private var purchases: PurchaseManager

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderLeadDays") private var reminderLeadDays = 3
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Reminders") {
                    Toggle("Remind me before payments are due", isOn: $notificationsEnabled)
                        .accessibilityIdentifier("notificationsToggle")
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue { store.requestNotificationAuthorization() }
                            store.rescheduleNotifications(enabled: newValue, leadDays: reminderLeadDays)
                        }

                    if notificationsEnabled {
                        Stepper("Remind \(reminderLeadDays) day\(reminderLeadDays == 1 ? "" : "s") before", value: $reminderLeadDays, in: 1...14)
                            .accessibilityIdentifier("reminderLeadDaysStepper")
                            .onChange(of: reminderLeadDays) { _, newValue in
                                store.rescheduleNotifications(enabled: notificationsEnabled, leadDays: newValue)
                            }
                    }
                }

                Section("Feel") {
                    Toggle("Punch haptics", isOn: $hapticsEnabled)
                        .accessibilityIdentifier("hapticsToggle")
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }
                }

                Section("Layaway Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked — unlimited plans", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(LWTheme.copper)
                    } else {
                        Button("Upgrade to Pro") { showPaywall = true }
                            .buttonStyle(.plain)
                    }
                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("restorePurchasesButton")
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/layaway-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}
