import SwiftUI

enum LayawaySheet: Identifiable {
    case addPlan
    case editPlan(InstallmentPlan)
    case addInstallment(InstallmentPlan)

    var id: String {
        switch self {
        case .addPlan: return "addPlan"
        case .editPlan(let plan): return "editPlan-\(plan.id)"
        case .addInstallment(let plan): return "addInstallment-\(plan.id)"
        }
    }
}

struct AddPlanSheet: View {
    @EnvironmentObject private var store: LayawayStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var merchant = ""
    @State private var totalAmount = ""
    @State private var showLimitAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    TextField("Name (e.g. Couch)", text: $name)
                        .accessibilityIdentifier("planNameField")
                    TextField("Merchant (optional)", text: $merchant)
                        .accessibilityIdentifier("planMerchantField")
                    TextField("Total amount", text: $totalAmount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("planTotalField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let amount = Double(totalAmount) ?? 0
                        guard store.canAddPlan(isPro: purchases.isPro) else {
                            showLimitAlert = true
                            return
                        }
                        if store.addPlan(name: name, merchant: merchant, totalAmount: amount, installments: [], isPro: purchases.isPro) {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("savePlanButton")
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Free plan limit reached", isPresented: $showLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Upgrade to Layaway Pro for unlimited concurrent plans.")
            }
        }
    }
}

struct AddInstallmentSheet: View {
    @EnvironmentObject private var store: LayawayStore
    @Environment(\.dismiss) private var dismiss
    let plan: InstallmentPlan

    @State private var amount = ""
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Installment") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("installmentAmountField")
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        .accessibilityIdentifier("installmentDueDatePicker")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Add Installment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addInstallment(to: plan.id, amount: Double(amount) ?? 0, dueDate: dueDate)
                        dismiss()
                    }
                    .accessibilityIdentifier("saveInstallmentButton")
                    .disabled(Double(amount) == nil)
                }
            }
        }
    }
}
