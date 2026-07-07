import XCTest
@testable import Layaway

final class LayawayTests: XCTestCase {
    func testRemainingComputesFromPayments() {
        var plan = Plan(itemName: "Test", totalPrice: 500, installmentCount: 5, dueDate: Date())
        plan.payments = [Installment(amount: 100, date: Date())]
        XCTAssertEqual(plan.remaining, 400, accuracy: 0.001)
        XCTAssertEqual(plan.progressFraction, 0.2, accuracy: 0.001)
    }

    func testIsPaidOffWhenFullyPaid() {
        var plan = Plan(itemName: "Test", totalPrice: 200, installmentCount: 2, dueDate: Date())
        plan.payments = [Installment(amount: 100, date: Date()), Installment(amount: 100, date: Date())]
        XCTAssertTrue(plan.isPaidOff)
    }

    func testExpectedInstallmentAmount() {
        let plan = Plan(itemName: "Test", totalPrice: 300, installmentCount: 3, dueDate: Date())
        XCTAssertEqual(plan.expectedInstallmentAmount, 100, accuracy: 0.001)
    }

    func testBeadsLitMatchesPaymentCount() {
        var plan = Plan(itemName: "Test", totalPrice: 400, installmentCount: 4, dueDate: Date())
        plan.payments = [Installment(amount: 100, date: Date()), Installment(amount: 100, date: Date())]
        XCTAssertEqual(plan.beadsLit, 2)
    }

    func testBeadsLitCapsAtInstallmentCount() {
        var plan = Plan(itemName: "Test", totalPrice: 200, installmentCount: 2, dueDate: Date())
        plan.payments = [Installment(amount: 50, date: Date()), Installment(amount: 50, date: Date()), Installment(amount: 100, date: Date())]
        XCTAssertEqual(plan.beadsLit, 2)
    }

    @MainActor
    func testStoreAddPlanRespectsFreeLimit() {
        let store = LayawayStore()
        for plan in store.plans { store.deletePlan(plan.id) }
        XCTAssertTrue(store.addPlan(itemName: "A", totalPrice: 100, installmentCount: 2, dueDate: Date(), isPro: false))
        XCTAssertTrue(store.addPlan(itemName: "B", totalPrice: 100, installmentCount: 2, dueDate: Date(), isPro: false))
        XCTAssertFalse(store.addPlan(itemName: "C", totalPrice: 100, installmentCount: 2, dueDate: Date(), isPro: false))
        XCTAssertTrue(store.addPlan(itemName: "C", totalPrice: 100, installmentCount: 2, dueDate: Date(), isPro: true))
    }

    @MainActor
    func testPayNextBeadUsesExpectedAmount() {
        let store = LayawayStore()
        for plan in store.plans { store.deletePlan(plan.id) }
        store.addPlan(itemName: "A", totalPrice: 400, installmentCount: 4, dueDate: Date(), isPro: false)
        let planID = store.plans[0].id
        store.payNextBead(planID: planID)
        XCTAssertEqual(store.plans[0].payments.count, 1)
        XCTAssertEqual(store.plans[0].payments[0].amount, 100, accuracy: 0.001)
    }

    @MainActor
    func testDeletePaymentRemovesFromPlan() {
        let store = LayawayStore()
        for plan in store.plans { store.deletePlan(plan.id) }
        store.addPlan(itemName: "A", totalPrice: 400, installmentCount: 4, dueDate: Date(), isPro: false)
        let planID = store.plans[0].id
        store.addPayment(toPlan: planID, amount: 50)
        let paymentID = store.plans[0].payments[0].id
        store.deletePayment(paymentID, fromPlan: planID)
        XCTAssertTrue(store.plans[0].payments.isEmpty)
    }
}
