import Foundation
import UserNotifications

@MainActor
final class LayawayStore: ObservableObject {
    @Published private(set) var plans: [InstallmentPlan] = []

    static let freeActivePlanLimit = 2

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
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let cal = Calendar.current
        let today = Date()
        var couch = InstallmentPlan(
            name: "Couch",
            merchant: "City Furniture",
            totalAmount: 1200,
            installments: [
                Installment(amount: 300, dueDate: cal.date(byAdding: .day, value: -30, to: today)!, isPaid: true, paidDate: cal.date(byAdding: .day, value: -30, to: today)),
                Installment(amount: 300, dueDate: cal.date(byAdding: .day, value: -2, to: today)!, isPaid: true, paidDate: cal.date(byAdding: .day, value: -2, to: today)),
                Installment(amount: 300, dueDate: cal.date(byAdding: .day, value: 28, to: today)!),
                Installment(amount: 300, dueDate: cal.date(byAdding: .day, value: 58, to: today)!)
            ]
        )
        couch.sortInstallments()

        var phone = InstallmentPlan(
            name: "iPhone",
            merchant: "Best Buy BNPL",
            totalAmount: 800,
            installments: [
                Installment(amount: 200, dueDate: cal.date(byAdding: .day, value: -1, to: today)!, isPaid: true, paidDate: cal.date(byAdding: .day, value: -1, to: today)),
                Installment(amount: 200, dueDate: cal.date(byAdding: .day, value: 14, to: today)!),
                Installment(amount: 200, dueDate: cal.date(byAdding: .day, value: 44, to: today)!),
                Installment(amount: 200, dueDate: cal.date(byAdding: .day, value: 74, to: today)!)
            ]
        )
        phone.sortInstallments()

        plans = [couch, phone]
        save()
    }

    func canAddPlan(isPro: Bool) -> Bool {
        isPro || activePlans.count < Self.freeActivePlanLimit
    }

    var activePlans: [InstallmentPlan] {
        plans.filter { !$0.isArchived && !$0.isPaidOff }
    }

    var paidOffPlans: [InstallmentPlan] {
        plans.filter { $0.isPaidOff }
    }

    @discardableResult
    func addPlan(name: String, merchant: String, totalAmount: Double, installments: [Installment], isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddPlan(isPro: isPro) else { return false }
        var plan = InstallmentPlan(name: trimmed, merchant: merchant, totalAmount: max(0, totalAmount), installments: installments)
        plan.sortInstallments()
        plans.append(plan)
        save()
        return true
    }

    func updatePlan(_ id: UUID, name: String, merchant: String, totalAmount: Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[idx].name = trimmed
        plans[idx].merchant = merchant
        plans[idx].totalAmount = max(0, totalAmount)
        save()
    }

    func deletePlan(_ id: UUID) {
        plans.removeAll { $0.id == id }
        save()
    }

    func addInstallment(to planID: UUID, amount: Double, dueDate: Date) {
        guard let idx = plans.firstIndex(where: { $0.id == planID }) else { return }
        plans[idx].installments.append(Installment(amount: max(0, amount), dueDate: dueDate))
        plans[idx].sortInstallments()
        save()
    }

    func deleteInstallment(planID: UUID, installmentID: UUID) {
        guard let idx = plans.firstIndex(where: { $0.id == planID }) else { return }
        plans[idx].installments.removeAll { $0.id == installmentID }
        save()
    }

    /// The signature interaction: punch (mark paid) or un-punch an installment.
    func togglePaid(planID: UUID, installmentID: UUID) {
        guard let planIdx = plans.firstIndex(where: { $0.id == planID }),
              let instIdx = plans[planIdx].installments.firstIndex(where: { $0.id == installmentID }) else { return }
        let wasPaid = plans[planIdx].installments[instIdx].isPaid
        plans[planIdx].installments[instIdx].isPaid.toggle()
        plans[planIdx].installments[instIdx].paidDate = wasPaid ? nil : Date()
        save()
    }

    func moveActivePlans(from source: IndexSet, to destination: Int) {
        var active = activePlans
        active.move(fromOffsets: source, toOffset: destination)
        let archivedOrPaid = plans.filter { $0.isArchived || $0.isPaidOff }
        plans = active + archivedOrPaid
        save()
    }

    func deleteAllData() {
        plans = []
        seedDefaults()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var plans: [InstallmentPlan]
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

    // MARK: - Notification scheduling (Pro bonus feature)

    func rescheduleNotifications(enabled: Bool, leadDays: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        for plan in plans where !plan.isArchived && !plan.isPaidOff {
            for installment in plan.installments where !installment.isPaid {
                let fireDate = Calendar.current.date(byAdding: .day, value: -max(0, leadDays), to: installment.dueDate)
                guard let fireDate, fireDate > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Payment coming up"
                content.body = "\(plan.name): $\(String(format: "%.2f", installment.amount)) due soon."
                content.sound = .default

                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: installment.id.uuidString, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
