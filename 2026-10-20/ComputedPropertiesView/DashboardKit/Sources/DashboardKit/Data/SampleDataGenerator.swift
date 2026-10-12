import Foundation

/// Builds a deterministic year of account activity, so both demo apps show exactly the same transactions.
public enum SampleDataGenerator {
    public static let defaultSeed: UInt64 = 2_026

    /// At most this many paychecks, one every 14 days.
    static let paydayCount = 26
    static let secondsPerDay: TimeInterval = 86_400
    /// Monthly charges are included only when there's room for them (6 × 12 = 72 transactions).
    static let monthlyChargeThreshold = 720
    /// Paychecks are sized so a year's income is this multiple of its spending.
    static let incomeToSpendingRatio: Decimal = 1.1

    static let monthlyCharges: [MonthlyCharge] = [
        MonthlyCharge(merchant: "Apartment Rent", category: .home, cents: 145_000, day: 1),
        MonthlyCharge(merchant: "Gym Membership", category: .health, cents: 4_500, day: 1),
        MonthlyCharge(merchant: "StreamBox", category: .entertainment, cents: 1_599, day: 3),
        MonthlyCharge(merchant: "Fiber Internet Plan", category: .utilities, cents: 7_000, day: 8),
        MonthlyCharge(merchant: "Mobile Plan", category: .utilities, cents: 5_500, day: 12),
        MonthlyCharge(merchant: "Cloud Storage", category: .shopping, cents: 299, day: 20)
    ]

    /// Generates `count` transactions for the year ending on the demo anchor date, off the main actor.
    @concurrent
    public static func transactions(count: Int, seed: UInt64 = defaultSeed) async -> [AccountTransaction] {
        makeTransactions(count: count, seed: seed, anchor: DemoClock.anchorDate, calendar: DemoClock.calendar)
    }

    /// The synchronous core. Returns newest first, with ids `0..<count`.
    static func makeTransactions(count: Int, seed: UInt64, anchor: Date, calendar: Calendar) -> [AccountTransaction] {
        guard count > 0 else { return [] }
        var generator = SeededRandomGenerator(seed: seed)
        let year = TimeRange.year.dateRange(endingOn: anchor, calendar: calendar)
        let incomeCount = min(paydayCount, count / 10)
        let monthly = count >= monthlyChargeThreshold ? monthlyTransactions(in: year, calendar: calendar) : []
        let randomCount = max(count - incomeCount - monthly.count, 0)
        let expenses = monthly + randomExpenses(count: randomCount, in: year, using: &generator)
        let spent = expenses.reduce(Decimal.zero) { $0 - $1.amount }
        let paycheck = incomeCount > 0 ? roundedToCents(spent * incomeToSpendingRatio / Decimal(incomeCount)) : 0
        var entries = paychecks(count: incomeCount, amount: paycheck, in: year) + expenses
        entries.sort { $0.date > $1.date }
        return entries.enumerated().map { $0.element.withID($0.offset) }
    }

    static func paychecks(count: Int, amount: Decimal, in year: Range<Date>) -> [AccountTransaction] {
        (0..<count).map { index in
            let payday = year.lowerBound.addingTimeInterval(TimeInterval(index * 14) * secondsPerDay + 9 * 3_600)
            return AccountTransaction(
                id: 0, date: payday, merchant: "Employer Payroll", category: .income, amount: amount, isPending: false
            )
        }
    }

    static func monthlyTransactions(in year: Range<Date>, calendar: Calendar) -> [AccountTransaction] {
        (0..<12).flatMap { month in
            let monthStart = calendar.date(byAdding: .month, value: month, to: year.lowerBound) ?? year.lowerBound
            return monthlyCharges.map { charge in
                let day = calendar.date(byAdding: .day, value: charge.day - 1, to: monthStart) ?? monthStart
                return AccountTransaction(
                    id: 0, date: day.addingTimeInterval(10 * 3_600), merchant: charge.merchant, category: charge.category,
                    amount: -Decimal(charge.cents) / 100, isPending: false
                )
            }
        }
    }

    static func randomExpenses(
        count: Int, in year: Range<Date>, using generator: inout SeededRandomGenerator
    ) -> [AccountTransaction] {
        let span = year.upperBound.timeIntervalSince(year.lowerBound)
        let spending = TransactionCategory.spending
        return (0..<count).map { _ in
            let category = spending[Int.random(in: 0..<spending.count, using: &generator)]
            let names = merchants(for: category)
            let merchant = names[Int.random(in: 0..<names.count, using: &generator)]
            let cents = Int.random(in: centsRange(for: category), using: &generator)
            let date = year.lowerBound.addingTimeInterval(Double.random(in: 0..<span, using: &generator))
            let isPending = Int.random(in: 0..<20, using: &generator) == 0
            return AccountTransaction(
                id: 0, date: date, merchant: merchant, category: category, amount: -Decimal(cents) / 100, isPending: isPending
            )
        }
    }

    static func roundedToCents(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }

    static func merchants(for category: TransactionCategory) -> [String] {
        switch category {
        case .income: ["Employer Payroll"]
        case .groceries: ["Green Basket Market", "Corner Grocer", "FreshCo", "Harvest Foods"]
        case .dining: ["Blue Door Café", "Noodle Bar", "Taco Stand", "Slice Pizza"]
        case .transport: ["Metro Transit", "City Rideshare", "Fuel Stop", "Parking Garage"]
        case .home: ["Hardware Depot", "Home Goods", "Garden Center", "Furniture Barn"]
        case .utilities: ["Power & Light", "Water Utility", "Fiber Internet", "Mobile Carrier"]
        case .entertainment: ["Cinema 8", "Streaming Plus", "Game Shop", "Concert Hall"]
        case .shopping: ["Department Store", "Bookshop", "Shoe Outlet", "Online Market"]
        case .health: ["Pharmacy", "Clinic Copay", "Fitness Club", "Dental Care"]
        }
    }

    /// Amount range in cents for one transaction of the category.
    static func centsRange(for category: TransactionCategory) -> ClosedRange<Int> {
        switch category {
        case .income: 325_000...325_000
        case .groceries: 500...12_000
        case .dining: 400...6_000
        case .transport: 200...4_500
        case .home: 500...15_000
        case .utilities: 2_000...15_000
        case .entertainment: 300...6_000
        case .shopping: 500...20_000
        case .health: 500...12_000
        }
    }
}

private extension AccountTransaction {
    func withID(_ id: Int) -> AccountTransaction {
        AccountTransaction(id: id, date: date, merchant: merchant, category: category, amount: amount, isPending: isPending)
    }
}
