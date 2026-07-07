import XCTest
@testable import Layaway

@MainActor
final class LayawayTests: XCTestCase {

    func testInstallmentRemainingAndPaidAmounts() {
        var plan = InstallmentPlan(name: "Couch", totalAmount: 1200, installments: [
            Installment(amount: 300, dueDate: Date(), isPaid: true),
            Installment(amount: 300, dueDate: Date()),
            Installment(amount: 300, dueDate: Date()),
            Installment(amount: 300, dueDate: Date())
        ])
        XCTAssertEqual(plan.paidAmount, 300, accuracy: 0.001)
        XCTAssertEqual(plan.remainingAmount, 900, accuracy: 0.001)
        XCTAssertEqual(plan.percentPaid, 0.25, accuracy: 0.001)
        XCTAssertFalse(plan.isPaidOff)

        for i in plan.installments.indices { plan.installments[i].isPaid = true }
        XCTAssertTrue(plan.isPaidOff)
        XCTAssertEqual(plan.remainingAmount, 0, accuracy: 0.001)
    }

    func testOverdueAndDueSoonDetection() {
        let cal = Calendar.current
        let overdue = Installment(amount: 100, dueDate: cal.date(byAdding: .day, value: -1, to: Date())!)
        let dueSoon = Installment(amount: 100, dueDate: cal.date(byAdding: .day, value: 2, to: Date())!)
        let farOut = Installment(amount: 100, dueDate: cal.date(byAdding: .day, value: 30, to: Date())!)

        XCTAssertTrue(overdue.isOverdue)
        XCTAssertFalse(dueSoon.isOverdue)
        XCTAssertTrue(dueSoon.isDueSoon)
        XCTAssertFalse(farOut.isDueSoon)
    }

    func testNextDueInstallmentIsEarliestUnpaid() {
        let cal = Calendar.current
        var plan = InstallmentPlan(name: "Phone", totalAmount: 800, installments: [
            Installment(amount: 200, dueDate: cal.date(byAdding: .day, value: 30, to: Date())!),
            Installment(amount: 200, dueDate: cal.date(byAdding: .day, value: 5, to: Date())!),
            Installment(amount: 200, dueDate: cal.date(byAdding: .day, value: -1, to: Date())!, isPaid: true)
        ])
        plan.sortInstallments()
        XCTAssertEqual(plan.nextDueInstallment?.amount, 200)
        XCTAssertEqual(
            cal.dateComponents([.day], from: Date(), to: plan.nextDueInstallment!.dueDate).day,
            5
        )
    }

    func testStoreResetsOnUITestLaunchArgument() {
        let store = LayawayStore()
        XCTAssertFalse(store.plans.isEmpty, "Store should seed default plans after a -uiTestReset wipe")
    }

    func testFreeTierActivePlanLimitGatesAdding() {
        let store = LayawayStore()
        store.deleteAllData()
        XCTAssertFalse(store.canAddPlan(isPro: false))
        XCTAssertTrue(store.canAddPlan(isPro: true))
    }

    func testTogglePaidSetsAndClearsPaidDate() {
        let store = LayawayStore()
        store.deleteAllData()
        guard let plan = store.plans.first, let installment = plan.installments.first(where: { !$0.isPaid }) else {
            XCTFail("Expected a seeded plan with an unpaid installment")
            return
        }
        store.togglePaid(planID: plan.id, installmentID: installment.id)
        let updated = store.plans.first { $0.id == plan.id }!.installments.first { $0.id == installment.id }!
        XCTAssertTrue(updated.isPaid)
        XCTAssertNotNil(updated.paidDate)

        store.togglePaid(planID: plan.id, installmentID: installment.id)
        let reverted = store.plans.first { $0.id == plan.id }!.installments.first { $0.id == installment.id }!
        XCTAssertFalse(reverted.isPaid)
        XCTAssertNil(reverted.paidDate)
    }
}
