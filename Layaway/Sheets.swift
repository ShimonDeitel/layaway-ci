import SwiftUI

enum LayawaySheetMode: Identifiable {
    case addPlan
    case editPlan(Plan)
    case addPayment(UUID)
    case paywall

    var id: String {
        switch self {
        case .addPlan: return "addPlan"
        case .editPlan(let plan): return "editPlan_\(plan.id.uuidString)"
        case .addPayment(let planID): return "addPayment_\(planID.uuidString)"
        case .paywall: return "paywall"
        }
    }
}

struct PlanEditSheet: View {
    let mode: LayawaySheetMode
    let onSave: (String, Double, Int, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var itemName: String
    @State private var priceText: String
    @State private var installmentCountText: String
    @State private var dueDate: Date

    init(mode: LayawaySheetMode, onSave: @escaping (String, Double, Int, Date) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .editPlan(let plan) = mode {
            _itemName = State(initialValue: plan.itemName)
            _priceText = State(initialValue: String(format: "%.2f", plan.totalPrice))
            _installmentCountText = State(initialValue: String(plan.installmentCount))
            _dueDate = State(initialValue: plan.dueDate)
        } else {
            _itemName = State(initialValue: "")
            _priceText = State(initialValue: "")
            _installmentCountText = State(initialValue: "4")
            _dueDate = State(initialValue: Calendar.current.date(byAdding: .month, value: 3, to: Date())!)
        }
    }

    private var title: String {
        if case .editPlan = mode { return "Edit Plan" }
        return "New Plan"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item name (e.g. Dining Table)", text: $itemName)
                        .accessibilityIdentifier("planNameField")
                    TextField("Total price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("planPriceField")
                }
                Section("Schedule") {
                    TextField("Number of installments", text: $installmentCountText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("planInstallmentCountField")
                    DatePicker("Payoff due date", selection: $dueDate, displayedComponents: .date)
                        .accessibilityIdentifier("planDueDatePicker")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(itemName, Double(priceText) ?? 0, Int(installmentCountText) ?? 1, dueDate)
                        dismiss()
                    }
                    .accessibilityIdentifier("planSaveButton")
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(priceText) == nil)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}

struct PaymentAddSheet: View {
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment") {
                    TextField("Amount paid", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("paymentAmountField")
                }
            }
            .navigationTitle("Log a Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Double(amountText) {
                            onSave(amount)
                        }
                        dismiss()
                    }
                    .accessibilityIdentifier("paymentSaveButton")
                    .disabled(Double(amountText) == nil)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
