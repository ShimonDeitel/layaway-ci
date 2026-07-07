import Foundation

struct Installment: Identifiable, Codable, Equatable {
    let id: UUID
    var amount: Double
    var dueDate: Date
    var isPaid: Bool
    var paidDate: Date?

    init(
        id: UUID = UUID(),
        amount: Double,
        dueDate: Date,
        isPaid: Bool = false,
        paidDate: Date? = nil
    ) {
        self.id = id
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.paidDate = paidDate
    }

    var isOverdue: Bool {
        !isPaid && dueDate < Calendar.current.startOfDay(for: Date())
    }

    var isDueSoon: Bool {
        guard !isPaid else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 999
        return days >= 0 && days <= 3
    }
}

struct InstallmentPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var merchant: String
    var totalAmount: Double
    var installments: [Installment]
    var createdDate: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        merchant: String = "",
        totalAmount: Double,
        installments: [Installment] = [],
        createdDate: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.merchant = merchant
        self.totalAmount = totalAmount
        self.installments = installments
        self.createdDate = createdDate
        self.isArchived = isArchived
    }

    var paidCount: Int { installments.filter { $0.isPaid }.count }
    var totalCount: Int { installments.count }

    var paidAmount: Double {
        installments.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    var remainingAmount: Double {
        max(0, totalAmount - paidAmount)
    }

    var percentPaid: Double {
        guard totalCount > 0 else { return 0 }
        return Double(paidCount) / Double(totalCount)
    }

    var isPaidOff: Bool {
        totalCount > 0 && paidCount == totalCount
    }

    var nextDueInstallment: Installment? {
        installments
            .filter { !$0.isPaid }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    var hasOverdue: Bool {
        installments.contains { $0.isOverdue }
    }

    mutating func sortInstallments() {
        installments.sort { $0.dueDate < $1.dueDate }
    }
}
