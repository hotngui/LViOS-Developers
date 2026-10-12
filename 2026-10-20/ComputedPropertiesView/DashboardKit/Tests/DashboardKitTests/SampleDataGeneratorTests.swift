import Foundation
import Testing
@testable import DashboardKit

@Suite struct SampleDataGeneratorTests {
    static let sample = make(count: 500)

    static func make(count: Int, seed: UInt64 = SampleDataGenerator.defaultSeed) -> [AccountTransaction] {
        SampleDataGenerator.makeTransactions(count: count, seed: seed, anchor: DemoClock.anchorDate, calendar: DemoClock.calendar)
    }

    @Test func countMatchesTheRequest() {
        #expect(Self.sample.count == 500)
        #expect(Self.make(count: 0).isEmpty)
    }

    @Test func asyncAPIReturnsTheIntensitysCount() async {
        let transactions = await SampleDataGenerator.transactions(count: 1_000)
        #expect(transactions.count == 1_000)
    }

    @Test func outputIsDeterministicPerSeed() {
        #expect(Self.make(count: 500) == Self.sample)
        #expect(Self.make(count: 500, seed: 7) != Self.sample)
    }

    @Test func everyDateFallsWithinTheYearBeforeTheAnchor() {
        let year = TimeRange.year.dateRange()
        #expect(Self.sample.allSatisfy { year.contains($0.date) })
    }

    @Test func allEightSpendingCategoriesAppear() {
        let categories = Set(Self.sample.map(\.category))
        #expect(Set(TransactionCategory.spending).isSubset(of: categories))
    }

    @Test func incomeIsPositiveAndSpendingIsNegative() {
        #expect(Self.sample.contains { $0.category == .income })
        #expect(Self.sample.allSatisfy { $0.category == .income ? $0.amount > 0 : $0.amount < 0 })
    }

    @Test func atLeastOneTransactionIsPending() {
        #expect(Self.sample.contains { $0.isPending })
    }

    @Test func resultsAreNewestFirstWithSequentialIDs() {
        #expect(zip(Self.sample, Self.sample.dropFirst()).allSatisfy { $0.date >= $1.date })
        #expect(Self.sample.map(\.id) == Array(0..<500))
    }

    static let large = make(count: 1_000)
    static let monthlyMerchants = Set(SampleDataGenerator.monthlyCharges.map(\.merchant))

    @Test func largeCountsIncludeTwelveOfEachMonthlyCharge() {
        let monthly = Self.large.filter { Self.monthlyMerchants.contains($0.merchant) }
        #expect(monthly.count == 72)
        for charge in SampleDataGenerator.monthlyCharges {
            let matches = monthly.filter { $0.merchant == charge.merchant }
            #expect(matches.count == 12)
            #expect(matches.allSatisfy { $0.amount == -Decimal(charge.cents) / 100 && !$0.isPending })
            #expect(matches.allSatisfy { DemoClock.calendar.component(.day, from: $0.date) == charge.day })
        }
    }

    @Test func smallCountsHaveNoMonthlyCharges() {
        #expect(!Self.sample.contains { Self.monthlyMerchants.contains($0.merchant) })
    }

    @Test func monthlyChargesDoNotChangeTheTotalCount() {
        #expect(Self.large.count == 1_000)
    }

    @Test func yearlyIncomeIsAboutTenPercentAboveSpending() {
        let income = NSDecimalNumber(decimal: TransactionMath.income(of: Self.large)).doubleValue
        let spending = NSDecimalNumber(decimal: TransactionMath.expenses(of: Self.large)).doubleValue
        #expect(abs(income / spending - 1.1) < 0.011)
    }
}
