import Foundation
import Testing
@testable import DashboardKit

@Suite struct TransactionMathTests {
    let week = TimeRange.week.dateRange()

    @Test func rangeFilterIncludesBothBoundaryDaysAndExcludesOutside() {
        let firstDay = Fixture.transaction(-1, .dining, on: Fixture.date(dayOffset: -6, hour: 0))
        let lastMinute = Fixture.transaction(-2, .dining, on: Fixture.date(dayOffset: 0, hour: 23, minute: 59))
        let tooEarly = Fixture.transaction(-3, .dining, on: Fixture.date(dayOffset: -7, hour: 23, minute: 59))
        let tooLate = Fixture.transaction(-4, .dining, on: Fixture.date(dayOffset: 1, hour: 0))
        let result = TransactionMath.transactions([firstDay, lastMinute, tooEarly, tooLate], in: week)
        #expect(result == [firstDay, lastMinute])
    }

    @Test func sumsIncomeExpensesAndNet() {
        let sample = [
            Fixture.transaction(3_250, .income, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-120.5, .groceries, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-79.5, .dining, on: Fixture.date(dayOffset: -2))
        ]
        #expect(TransactionMath.income(of: sample) == 3_250)
        #expect(TransactionMath.expenses(of: sample) == 200)
        #expect(TransactionMath.net(of: sample) == 3_050)
    }

    @Test func spendingTotalForTheBudgetGaugeCountsOnlyExpensesInRange() {
        let sample = [
            Fixture.transaction(-40, .transport, on: Fixture.date(dayOffset: -3)),
            Fixture.transaction(-60, .shopping, on: Fixture.date(dayOffset: -30)),
            Fixture.transaction(500, .income, on: Fixture.date(dayOffset: -3))
        ]
        #expect(TransactionMath.expenses(of: TransactionMath.transactions(sample, in: week)) == 40)
    }

    @Test func categoryTotalsAreSortedLargestFirstAndSharesAddUpToOne() {
        let sample = [
            Fixture.transaction(-10, .dining, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-60, .groceries, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-30, .dining, on: Fixture.date(dayOffset: -2)),
            Fixture.transaction(1_000, .income, on: Fixture.date(dayOffset: -2))
        ]
        let totals = TransactionMath.categoryTotals(of: sample)
        #expect(totals.map(\.category) == [.groceries, .dining])
        #expect(totals.map(\.total) == [60, 40])
        #expect(abs(totals[0].share - 0.6) < 1e-9)
        #expect(abs(totals.map(\.share).reduce(0, +) - 1) < 1e-9)
    }

    @Test func categoryTotalTiesFollowCategoryOrder() {
        let sample = [
            Fixture.transaction(-20, .shopping, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-20, .dining, on: Fixture.date(dayOffset: -1))
        ]
        #expect(TransactionMath.categoryTotals(of: sample).map(\.category) == [.dining, .shopping])
    }

    @Test func categoryTotalsForARangeWithNoSpendingAreEmpty() {
        #expect(TransactionMath.categoryTotals(of: []).isEmpty)
        let incomeOnly = [Fixture.transaction(3_250, .income, on: Fixture.date(dayOffset: -1))]
        #expect(TransactionMath.categoryTotals(of: incomeOnly).isEmpty)
        #expect(TransactionMath.expenses(of: incomeOnly) == 0)
    }

    @Test func dailyTotalsBinByDayAndCategorySkippingIncome() {
        let sample = [
            Fixture.transaction(-10, .groceries, on: Fixture.date(dayOffset: -1, hour: 9)),
            Fixture.transaction(-5, .groceries, on: Fixture.date(dayOffset: -1, hour: 18)),
            Fixture.transaction(-7, .dining, on: Fixture.date(dayOffset: -1, hour: 20)),
            Fixture.transaction(-3, .groceries, on: Fixture.date(dayOffset: 0, hour: 8)),
            Fixture.transaction(3_250, .income, on: Fixture.date(dayOffset: -1, hour: 9))
        ]
        let dayBefore = Fixture.date(dayOffset: -1, hour: 0)
        let anchorDay = Fixture.date(dayOffset: 0, hour: 0)
        let bins = TransactionMath.dailyTotals(of: sample, calendar: DemoClock.calendar)
        #expect(bins.map(\.day) == [dayBefore, dayBefore, anchorDay])
        #expect(bins.map(\.category) == [.groceries, .dining, .groceries])
        #expect(bins.map(\.total) == [15, 7, 3])
        #expect(bins.map(\.amount) == [15, 7, 3])
    }

    @Test func pendingOnlyKeepsOnlyPendingTransactions() {
        let pending = Fixture.transaction(-5, .health, on: Fixture.date(dayOffset: -1), isPending: true)
        let settled = Fixture.transaction(-6, .health, on: Fixture.date(dayOffset: -1))
        #expect(TransactionMath.pendingOnly([pending, settled]) == [pending])
    }

    @Test func newestFirstSortsDescendingAndHonorsTheLimit() {
        let old = Fixture.transaction(-1, .home, on: Fixture.date(dayOffset: -3))
        let middle = Fixture.transaction(-2, .home, on: Fixture.date(dayOffset: -2))
        let newest = Fixture.transaction(-3, .home, on: Fixture.date(dayOffset: -1))
        #expect(TransactionMath.newestFirst([old, newest, middle], limit: 2) == [newest, middle])
    }

    @Test(arguments: [
        (Decimal(50), 200.0, 0.25),
        (Decimal(500), 200.0, 1.0),
        (Decimal(0), 0.0, 0.0),
        (Decimal(10), 0.0, 1.0)
    ])
    func budgetUsageStaysBetweenZeroAndOne(spent: Decimal, budget: Double, expected: Double) {
        #expect(TransactionMath.budgetUsage(spent: spent, budget: budget) == expected)
    }

    @Test func budgetCeilingIsTwiceTheSpendingWithAFloor() {
        #expect(TransactionMath.budgetCeiling(forSpent: 1_234.5) == 2_469)
        #expect(TransactionMath.budgetCeiling(forSpent: 0) == 100)
    }
}
