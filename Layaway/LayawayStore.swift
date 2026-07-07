import Foundation

@MainActor
final class LayawayStore: ObservableObject {
    @Published private(set) var plans: [Plan] = []

    static let freePlanLimit = 2

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("layaway_plans.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if plans.isEmpty {
            seedDefault()
        }
    }

    private func seedDefault() {
        plans = [
            Plan(itemName: "Dining Table", totalPrice: 600, installmentCount: 6,
                 dueDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                 payments: [Installment(amount: 100, date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!)])
        ]
        save()
    }

    func canAddPlan(isPro: Bool) -> Bool {
        isPro || plans.count < Self.freePlanLimit
    }

    @discardableResult
    func addPlan(itemName: String, totalPrice: Double, installmentCount: Int, dueDate: Date, isPro: Bool) -> Bool {
        let trimmed = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddPlan(isPro: isPro), totalPrice > 0, installmentCount > 0 else { return false }
        let plan = Plan(itemName: trimmed, totalPrice: totalPrice, installmentCount: installmentCount, dueDate: dueDate)
        plans.append(plan)
        save()
        return true
    }

    func updatePlan(_ id: UUID, itemName: String, totalPrice: Double, installmentCount: Int, dueDate: Date) {
        guard let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        plans[idx].itemName = trimmed
        plans[idx].totalPrice = max(0.01, totalPrice)
        plans[idx].installmentCount = max(1, installmentCount)
        plans[idx].dueDate = dueDate
        save()
    }

    func deletePlan(_ id: UUID) {
        plans.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func addPayment(toPlan planID: UUID, amount: Double) -> Bool {
        guard let idx = plans.firstIndex(where: { $0.id == planID }), amount > 0 else { return false }
        plans[idx].payments.append(Installment(amount: amount, date: Date()))
        save()
        return true
    }

    /// Quirky feature: "Pay the next bead" — one tap logs exactly the
    /// expected per-installment amount, lighting up the next bead on the
    /// necklace visual without having to type an amount.
    @discardableResult
    func payNextBead(planID: UUID) -> Bool {
        guard let idx = plans.firstIndex(where: { $0.id == planID }) else { return false }
        let amount = plans[idx].expectedInstallmentAmount
        guard amount > 0 else { return false }
        plans[idx].payments.append(Installment(amount: amount, date: Date()))
        save()
        return true
    }

    func deletePayment(_ paymentID: UUID, fromPlan planID: UUID) {
        guard let idx = plans.firstIndex(where: { $0.id == planID }) else { return }
        plans[idx].payments.removeAll { $0.id == paymentID }
        save()
    }

    func deleteAllData() {
        plans = []
        seedDefault()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var plans: [Plan]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            plans = decoded.plans
        }
    }

    private func save() {
        let snapshot = Snapshot(plans: plans)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
