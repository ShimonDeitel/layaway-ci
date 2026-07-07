import Foundation

/// A single installment payment toward a plan.
struct Installment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var amount: Double
    var date: Date
}

/// A payment-plan item (layaway or BNPL-style), tracked manually — no bank
/// integration, purely a personal ledger of what's owed and what's paid.
struct Plan: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var itemName: String
    var totalPrice: Double
    var installmentCount: Int
    var dueDate: Date
    var payments: [Installment] = []

    var paidTotal: Double {
        payments.reduce(0) { $0 + $1.amount }
    }

    var remaining: Double {
        max(0, totalPrice - paidTotal)
    }

    var progressFraction: Double {
        guard totalPrice > 0 else { return 0 }
        return min(1.0, paidTotal / totalPrice)
    }

    var isPaidOff: Bool {
        remaining <= 0.005
    }

    var expectedInstallmentAmount: Double {
        guard installmentCount > 0 else { return totalPrice }
        return totalPrice / Double(installmentCount)
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    /// Bead count for the "necklace" visual — one bead per planned installment.
    var beadsLit: Int {
        min(installmentCount, payments.count)
    }
}
