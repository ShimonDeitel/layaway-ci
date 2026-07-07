import SwiftUI

struct PlanListView: View {
    @EnvironmentObject private var store: LayawayStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: LayawaySheet?
    @State private var expandedPlanID: UUID?
    @State private var showPaywall = false
    @State private var punchedID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                Color.clear.frame(height: 0).dismissKeyboardOnTap()

                LazyVStack(spacing: 14) {
                    if store.activePlans.isEmpty && store.paidOffPlans.isEmpty {
                        emptyState
                    } else {
                        if !store.activePlans.isEmpty {
                            sectionHeader("Active Plans")
                            ForEach(store.activePlans) { plan in
                                planCard(plan)
                            }
                        }
                        if !store.paidOffPlans.isEmpty {
                            sectionHeader("Paid Off")
                            ForEach(store.paidOffPlans) { plan in
                                planCard(plan)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(LWTheme.backdrop.ignoresSafeArea())
            .navigationTitle("Layaway")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddPlan(isPro: purchases.isPro) {
                            activeSheet = .addPlan
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addPlanButton")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addPlan:
                    AddPlanSheet()
                case .addInstallment(let plan):
                    AddInstallmentSheet(plan: plan)
                case .editPlan:
                    EmptyView()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(LWTheme.headlineFont)
            .foregroundStyle(LWTheme.inkFaded)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
            .accessibilityIdentifier("sectionHeader_\(text)")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 44))
                .foregroundStyle(LWTheme.copper)
            Text("No payment plans yet")
                .font(LWTheme.titleFont)
                .foregroundStyle(LWTheme.ink)
            Text("Add a layaway or buy-now-pay-later plan to start tracking installments.")
                .font(.subheadline)
                .foregroundStyle(LWTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("emptyStateView")
    }

    private func planCard(_ plan: InstallmentPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name)
                        .font(LWTheme.titleFont)
                        .foregroundStyle(LWTheme.ink)
                    if !plan.merchant.isEmpty {
                        Text(plan.merchant)
                            .font(.caption)
                            .foregroundStyle(LWTheme.inkFaded)
                    }
                }
                Spacer()
                Text("$\(String(format: "%.2f", plan.remainingAmount)) left")
                    .font(LWTheme.monoFont)
                    .foregroundStyle(plan.hasOverdue ? LWTheme.overdue : LWTheme.copper)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("planHeader_\(plan.name)")

            punchCardRow(plan)

            ProgressView(value: plan.percentPaid)
                .tint(LWTheme.copper)

            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        expandedPlanID = expandedPlanID == plan.id ? nil : plan.id
                    }
                } label: {
                    Label(expandedPlanID == plan.id ? "Hide installments" : "Show installments", systemImage: "chevron.down")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(LWTheme.copperBright)

                Spacer()

                if !plan.isPaidOff {
                    Button {
                        activeSheet = .addInstallment(plan)
                    } label: {
                        Label("Add installment", systemImage: "plus")
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(LWTheme.copperBright)
                }
            }

            if expandedPlanID == plan.id {
                ForEach(plan.installments.sorted(by: { $0.dueDate < $1.dueDate })) { installment in
                    installmentRow(plan: plan, installment: installment)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(LWTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(LWTheme.rule, lineWidth: 1))
    }

    private func punchCardRow(_ plan: InstallmentPlan) -> some View {
        HStack(spacing: 8) {
            ForEach(plan.installments.sorted(by: { $0.dueDate < $1.dueDate })) { installment in
                Circle()
                    .fill(installment.isPaid ? LWTheme.copper : LWTheme.punchHole)
                    .overlay(Circle().stroke(LWTheme.rule, lineWidth: 1))
                    .frame(width: 20, height: 20)
                    .scaleEffect(punchedID == installment.id ? 1.35 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: punchedID)
            }
        }
        .accessibilityIdentifier("punchCardRow_\(plan.name)")
    }

    private func installmentRow(plan: InstallmentPlan, installment: Installment) -> some View {
        HStack {
            Button {
                punchedID = installment.id
                Haptics.punch()
                store.togglePaid(planID: plan.id, installmentID: installment.id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if punchedID == installment.id { punchedID = nil }
                }
            } label: {
                Image(systemName: installment.isPaid ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(installment.isPaid ? LWTheme.paidGreen : LWTheme.inkFaded)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("toggleInstallment_\(installment.id)")

            Text(installment.dueDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(installment.isOverdue ? LWTheme.overdue : LWTheme.inkFaded)

            Spacer()

            Text("$\(String(format: "%.2f", installment.amount))")
                .font(LWTheme.monoFont)
                .foregroundStyle(LWTheme.ink)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("installmentRow_\(installment.id)")
    }
}
