import SwiftUI

/// Main screen: each plan renders as a "bead necklace" — one bead per
/// planned installment, lighting up gold as payments log. The quirky
/// gimmick is "Pay the Next Bead": a single tap logs exactly the expected
/// installment amount and animates that bead lighting up, so paying down a
/// plan feels like a tactile string of beads rather than a spreadsheet row.
struct PlanListView: View {
    @EnvironmentObject private var store: LayawayStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var sheetMode: LayawaySheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if store.plans.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(store.plans) { plan in
                                planCard(plan)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Layaway")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if store.canAddPlan(isPro: purchases.isPro) {
                            sheetMode = .addPlan
                        } else {
                            sheetMode = .paywall
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addPlanButton")
                }
            }
            .dismissKeyboardOnTap()
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .addPlan, .editPlan:
                    PlanEditSheet(mode: mode) { name, price, count, due in
                        switch mode {
                        case .addPlan:
                            store.addPlan(itemName: name, totalPrice: price, installmentCount: count, dueDate: due, isPro: purchases.isPro)
                        case .editPlan(let plan):
                            store.updatePlan(plan.id, itemName: name, totalPrice: price, installmentCount: count, dueDate: due)
                        default: break
                        }
                    }
                case .addPayment(let planID):
                    PaymentAddSheet { amount in
                        store.addPayment(toPlan: planID, amount: amount)
                    }
                }
            }
        }
    }

    private func planCard(_ plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(plan.itemName)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(plan.isPaidOff ? "Paid off!" : "\(plan.daysUntilDue) days until due")
                        .font(.caption)
                        .foregroundStyle(plan.isPaidOff ? Theme.gold : .secondary)
                }
                Spacer()
                Button {
                    sheetMode = .editPlan(plan)
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("editPlan_\(plan.itemName)")
            }

            necklace(plan)

            HStack {
                Text("$\(String(format: "%.2f", plan.paidTotal)) of $\(String(format: "%.2f", plan.totalPrice))")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.slate)
                Spacer()
                Text("$\(String(format: "%.2f", plan.remaining)) left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !plan.isPaidOff {
                HStack(spacing: 12) {
                    Button {
                        store.payNextBead(planID: plan.id)
                    } label: {
                        Label("Pay Next Bead", systemImage: "circle.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.gold)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("payNextBead_\(plan.itemName)")

                    Button {
                        sheetMode = .addPayment(plan.id)
                    } label: {
                        Label("Custom", systemImage: "creditcard")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.slate)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("customPayment_\(plan.itemName)")
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deletePlan(plan.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func necklace(_ plan: Plan) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<max(1, plan.installmentCount), id: \.self) { index in
                Circle()
                    .fill(index < plan.beadsLit ? Theme.gold : Theme.beadEmpty)
                    .frame(width: 22, height: 22)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: plan.beadsLit)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("necklace_\(plan.itemName)")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 48))
                .foregroundStyle(Theme.slate)
            Text("No payment plans yet. Add one to start tracking installments.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    PlanListView()
        .environmentObject(LayawayStore())
        .environmentObject(PurchaseManager())
}
