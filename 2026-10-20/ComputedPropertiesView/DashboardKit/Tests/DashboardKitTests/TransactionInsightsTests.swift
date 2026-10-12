import Foundation
import Testing
@testable import DashboardKit

@Suite struct TransactionInsightsTests {
    let week = TimeRange.week.dateRange()
    let calendar = DemoClock.calendar

    func day(_ offset: Int) -> Date { Fixture.date(dayOffset: offset, hour: 0) }

    @Test func dailyBalancesRunFromZeroOneEntryPerDay() {
        let sample = [
            Fixture.transaction(100, .income, on: Fixture.date(dayOffset: -2)),
            Fixture.transaction(-30, .dining, on: Fixture.date(dayOffset: -1)),
            Fixture.transaction(-20, .dining, on: Fixture.date(dayOffset: 0))
        ]
        let balances = TransactionMath.dailyBalances(of: sample, in: week, calendar: calendar)
        #expect(balances.map(\.day) == (-6...0).map(day))
        #expect(balances.map(\.value) == [0, 0, 0, 0, 100, 70, 50])
    }

    @Test func dailySpendIncludesZeroDaysAndIgnoresIncome() {
        let sample = [
            Fixture.transaction(-12, .home, on: Fixture.date(dayOffset: -3)),
            Fixture.transaction(500, .income, on: Fixture.date(dayOffset: -3))
        ]
        let spend = TransactionMath.dailySpend(of: sample, in: week, calendar: calendar)
        #expect(spend.count == 7)
        #expect(spend.map(\.value) == [0, 0, 0, 12, 0, 0, 0])
    }

    @Test func topMerchantsSortByTotalThenNameAndHonorTheLimit() {
        let sample = [
            Fixture.transaction(-10, .dining, on: day(-1), merchant: "A"),
            Fixture.transaction(-5, .dining, on: day(-1), merchant: "A"),
            Fixture.transaction(-15, .dining, on: day(-1), merchant: "B"),
            Fixture.transaction(-20, .dining, on: day(-1), merchant: "C"),
            Fixture.transaction(99, .income, on: day(-1), merchant: "Payroll")
        ]
        let top = TransactionMath.topMerchants(of: sample, limit: 2)
        #expect(top.map(\.merchant) == ["C", "A"])
        #expect(top.map(\.total) == [20, 15])
        #expect(top.last?.count == 2)
    }

    @Test func largestExpensesSortByMagnitudeThenNewestFirst() {
        let older = Fixture.transaction(-20, .home, on: day(-3), merchant: "Older")
        let newer = Fixture.transaction(-20, .home, on: day(-1), merchant: "Newer")
        let sample = [Fixture.transaction(-5, .home, on: day(-2)), older, Fixture.transaction(-50, .home, on: day(-2)), newer,
                      Fixture.transaction(100, .income, on: day(-2))]
        let largest = TransactionMath.largestExpenses(of: sample, limit: 3)
        #expect(largest.map(\.amount) == [-50, -20, -20])
        #expect(largest.map(\.merchant).suffix(2) == ["Newer", "Older"])
    }

    @Test func weekdayAveragesCoverSevenWeekdaysIncludingZeroDays() {
        let sample = [Fixture.transaction(-14, .dining, on: Fixture.date(dayOffset: 0))]
        let averages = TransactionMath.weekdayAverages(of: sample, in: week, calendar: calendar)
        let anchorWeekday = calendar.component(.weekday, from: DemoClock.anchorDate)
        #expect(averages.map(\.weekday) == Array(1...7))
        #expect(averages.first { $0.weekday == anchorWeekday }?.average == 14)
        #expect(averages.filter { $0.weekday != anchorWeekday }.allSatisfy { $0.average == 0 })
    }

    @Test func categorySeriesHasEightSeriesWithOnePointPerDay() {
        let sample = [Fixture.transaction(-9, .transport, on: Fixture.date(dayOffset: -2))]
        let series = TransactionMath.categorySeries(of: sample, in: week, calendar: calendar)
        #expect(series.map(\.category) == TransactionCategory.spending)
        #expect(series.allSatisfy { $0.points.count == 7 })
        #expect(series.first { $0.category == .transport }?.points.map(\.value) == [0, 0, 0, 0, 9, 0, 0])
    }

    @Test(arguments: TimeRange.allCases)
    func previousDateRangeHasTheSameLengthAndEndsWhereTheRangeStarts(range: TimeRange) {
        let current = range.dateRange()
        let previous = range.previousDateRange()
        #expect(previous.upperBound == current.lowerBound)
        let previousLength = previous.upperBound.timeIntervalSince(previous.lowerBound)
        #expect(previousLength == current.upperBound.timeIntervalSince(current.lowerBound))
    }

    @Test func categoryComparisonFillsAllCategoriesWithZeros() {
        let current = [Fixture.transaction(-10, .dining, on: day(-1))]
        let previous = [Fixture.transaction(-4, .dining, on: day(-9)), Fixture.transaction(-6, .groceries, on: day(-9))]
        let changes = TransactionMath.categoryComparison(current: current, previous: previous)
        #expect(changes.map(\.category) == TransactionCategory.spending)
        #expect(changes.first { $0.category == .dining }.map { [$0.current, $0.previous] } == [10, 4])
        #expect(changes.first { $0.category == .groceries }.map { [$0.current, $0.previous] } == [0, 6])
        #expect(changes.first { $0.category == .health }?.difference == 0)
    }

    @Test func recurringChargesFindEqualMonthlyChargesOnly() {
        let start = Fixture.date(dayOffset: -120)
        func monthly(_ months: Int) -> Date { calendar.date(byAdding: .month, value: months, to: start) ?? start }
        let sample = (0..<4).map { Fixture.transaction(-45, .health, on: monthly($0), merchant: "Gym") }
            + (0..<4).map { Fixture.transaction(Decimal(-10 - $0), .dining, on: monthly($0), merchant: "Varying") }
            + (0..<4).map {
                Fixture.transaction(-9, .shopping, on: start.addingTimeInterval(Double($0) * 10 * 86_400), merchant: "Irregular")
            }
            + (0..<2).map { Fixture.transaction(-5, .shopping, on: monthly($0), merchant: "Twice") }
        let charges = TransactionMath.recurringCharges(of: sample, calendar: calendar)
        #expect(charges.map(\.merchant) == ["Gym"])
        #expect(charges.first?.amount == 45)
        #expect(charges.first?.nextDate == monthly(4))
    }

    @Test func recurringChargesOnGeneratedDataFindTheSixMonthlyMerchants() {
        let data = SampleDataGenerator.makeTransactions(
            count: 1_000, seed: SampleDataGenerator.defaultSeed, anchor: DemoClock.anchorDate, calendar: calendar
        )
        let merchants = TransactionMath.recurringCharges(of: data, calendar: calendar).map(\.merchant)
        #expect(merchants == SampleDataGenerator.monthlyCharges.map(\.merchant).sorted())
    }

    @Test func upcomingBillsKeepTheWindowAndSortByDate() {
        let anchor = DemoClock.anchorDate
        func charge(_ name: String, dueIn days: Double) -> RecurringCharge {
            RecurringCharge(merchant: name, category: .utilities, amount: 10, lastDate: anchor,
                            nextDate: anchor.addingTimeInterval(days * 86_400))
        }
        let charges = [
            charge("Late", dueIn: 31), charge("Second", dueIn: 20), charge("Now", dueIn: 0), charge("First", dueIn: 1)
        ]
        let bills = TransactionMath.upcomingBills(charges, after: anchor, within: 30, calendar: calendar)
        #expect(bills.map(\.merchant) == ["First", "Second"])
    }

    @Test func savingsProgressClampsAndHandlesAZeroGoal() {
        #expect(TransactionMath.savingsProgress(net: 50, goal: 100) == 0.5)
        #expect(TransactionMath.savingsProgress(net: 150, goal: 100) == 1)
        #expect(TransactionMath.savingsProgress(net: -10, goal: 100) == 0)
        #expect(TransactionMath.savingsProgress(net: 5, goal: 0) == 1)
        #expect(TransactionMath.savingsProgress(net: 0, goal: 0) == 0)
    }
}
