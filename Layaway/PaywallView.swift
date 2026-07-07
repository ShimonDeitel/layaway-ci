import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(LWTheme.copper)
                    .padding(.top, 24)

                Text("Layaway Pro")
                    .font(LWTheme.titleFont)
                    .foregroundStyle(LWTheme.ink)

                VStack(alignment: .leading, spacing: 12) {
                    featureRow("Unlimited concurrent plans", icon: "infinity")
                    featureRow("Full payment history", icon: "clock.arrow.circlepath")
                    featureRow("Custom reminder lead time", icon: "bell.badge")
                }
                .padding(.horizontal, 24)

                if let product = purchases.product {
                    Text("\(product.displayPrice) / month, auto-renews, cancel anytime")
                        .font(.caption)
                        .foregroundStyle(LWTheme.inkFaded)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button {
                        Task { await purchases.purchase() }
                    } label: {
                        Text("Subscribe — \(product.displayPrice)/mo")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LWTheme.copper)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("subscribeButton")
                    .padding(.horizontal, 24)
                } else {
                    Text("$0.99 / month, auto-renews, cancel anytime")
                        .font(.caption)
                        .foregroundStyle(LWTheme.inkFaded)
                }

                Button("Restore Purchases") {
                    Task { await purchases.restore() }
                }
                .buttonStyle(.plain)
                .font(.caption)

                HStack(spacing: 16) {
                    Link("Terms of Use", destination: URL(string: "https://shimondeitel.github.io/layaway-site/terms.html")!)
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/layaway-site/privacy.html")!)
                }
                .font(.caption2)
                .foregroundStyle(LWTheme.inkFaded)

                Spacer()
            }
            .background(LWTheme.backdrop.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func featureRow(_ text: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(LWTheme.copper)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(LWTheme.ink)
        }
    }
}
