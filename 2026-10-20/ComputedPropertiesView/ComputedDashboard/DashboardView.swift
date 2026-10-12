//  ⚠️ INTENTIONAL ANTI-PATTERN — do not copy.
//
//  This dashboard builds its sections as `some View` computed properties. A computed property is inlined into `body`,
//  so it shares the dashboard's invalidation boundary: any change to the `@State` values below re-runs every section,
//  including expensive ones that never read the changed value. The live feed alone triggers that ten times a second.
//  The sibling app (StructDashboard) is identical except each section is its own `View` struct.
//
//  Section bodies sit between `BEGIN/END SECTION BODY` markers and must stay textually identical to the struct app's.
//  Run `Scripts/check-section-parity.sh` after editing either copy.

import Charts
import DashboardKit
import SwiftUI

// Seventeen computed-property sections are the anti-pattern under test, so this type is long on purpose.
// swiftlint:disable:next type_body_length
struct DashboardView: View {
    let transactions: [AccountTransaction]
    let rowLimit: Int

    @State private var budget = 2_000.0
    @State private var hideBalances = false
    @State private var showPendingOnly = false
    @State private var timeRange = TimeRange.month
    @State private var liveArrivals: [LiveArrival] = []
    @Environment(\.liveUpdatesEnabled) private var liveUpdatesEnabled

    var body: some View {
        ScrollView {
            VStack {
                liveActivity
                accountSummary
                timeRangePicker
                budgetCard
                spendingChart
                categoryBreakdown
                recentTransactions
                cashFlow
                topMerchants
                largestExpenses
                weekdayPattern
                spendingCalendar
                categoryTrends
                versusPrevious
                upcomingBills
                subscriptions
                savingsGoal
            }
            .padding()
        }
        .task(id: liveUpdatesEnabled) {
            // Identical in both apps: ten arrivals a second from the dashboard's own state.
            guard liveUpdatesEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                liveArrivals = LiveFeed.next(after: liveArrivals)
            }
        }
    }

    // MARK: - Sections (computed properties: the anti-pattern under test)

    @ViewBuilder
    private var accountSummary: some View {
        // BEGIN SECTION BODY: summary
        let evaluationCount = EvaluationCounter.shared.record(.summary)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        VStack(alignment: .leading) {
            HStack {
                Text("Account summary")
                    .font(.headline)
                Spacer()
                Button("Toggle balance visibility", systemImage: hideBalances ? "eye.slash" : "eye") {
                    InteractionTimer.shared.begin(.toggleBalances)
                    hideBalances.toggle()
                }
                .labelStyle(.iconOnly)
            }
            Text(TransactionMath.net(of: inRange), format: .currency(code: "USD"))
                .font(.largeTitle)
                .bold()
                .redacted(reason: hideBalances ? .placeholder : [])
            LabeledContent("Income") {
                Text(TransactionMath.income(of: inRange), format: .currency(code: "USD"))
                    .redacted(reason: hideBalances ? .placeholder : [])
            }
            LabeledContent("Spent") {
                Text(TransactionMath.expenses(of: inRange), format: .currency(code: "USD"))
                    .redacted(reason: hideBalances ? .placeholder : [])
            }
            EvaluationBadge(section: .summary, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: summary
    }

    @ViewBuilder
    private var timeRangePicker: some View {
        // BEGIN SECTION BODY: timeRange
        let evaluationCount = EvaluationCounter.shared.record(.timeRange)
        VStack(alignment: .leading) {
            Picker("Time range", selection: $timeRange.timed(.timeRange)) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.title)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            EvaluationBadge(section: .timeRange, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: timeRange
    }

    @ViewBuilder
    private var budgetCard: some View {
        // BEGIN SECTION BODY: budget
        let evaluationCount = EvaluationCounter.shared.record(.budget)
        let spent = TransactionMath.expenses(of: TransactionMath.transactions(transactions, in: timeRange.dateRange()))
        let ceiling = TransactionMath.budgetCeiling(forSpent: spent)
        VStack(alignment: .leading) {
            Text("Budget")
                .font(.headline)
            Gauge(value: TransactionMath.budgetUsage(spent: spent, budget: budget)) {
                Text("Spent of budget")
            } currentValueLabel: {
                Text(spent, format: .currency(code: "USD"))
            }
            if spent > Decimal(budget) {
                Label("Over budget", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .bold()
            }
            Slider(value: $budget, in: 0...ceiling) {
                Text("Budget")
            }
            .accessibilityValue(Text(budget, format: .currency(code: "USD")))
            Text("Budget: \(budget, format: .currency(code: "USD").precision(.fractionLength(0)))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            EvaluationBadge(section: .budget, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: budget
    }

    @ViewBuilder
    private var spendingChart: some View {
        // BEGIN SECTION BODY: chart
        let evaluationCount = EvaluationCounter.shared.record(.chart)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let dailyTotals = TransactionMath.dailyTotals(of: inRange, calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Spending by day")
                .font(.headline)
            Chart(dailyTotals) { dailyTotal in
                BarMark(x: .value("Day", dailyTotal.day, unit: .day), y: .value("Spent", dailyTotal.amount))
                    .foregroundStyle(by: .value("Category", dailyTotal.category.name))
            }
            .chartForegroundStyleScale(
                domain: TransactionCategory.spending.map(\.name), range: TransactionCategory.spending.map(\.color)
            )
            .frame(minHeight: 220)
            EvaluationBadge(section: .chart, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: chart
    }

    @ViewBuilder
    private var categoryBreakdown: some View {
        // BEGIN SECTION BODY: categories
        let evaluationCount = EvaluationCounter.shared.record(.categories)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let categoryTotals = TransactionMath.categoryTotals(of: inRange)
        VStack(alignment: .leading) {
            Text("Where it went")
                .font(.headline)
            if categoryTotals.isEmpty {
                Text("No spending in this range")
                    .foregroundStyle(.secondary)
            }
            ForEach(categoryTotals) { categoryTotal in
                VStack(alignment: .leading) {
                    LabeledContent {
                        Text(categoryTotal.total, format: .currency(code: "USD"))
                    } label: {
                        Label {
                            Text(categoryTotal.category.title)
                        } icon: {
                            Image(systemName: categoryTotal.category.systemImage)
                        }
                    }
                    ProgressView(value: categoryTotal.share)
                        .tint(categoryTotal.category.color)
                        .accessibilityValue(Text(categoryTotal.share, format: .percent.precision(.fractionLength(1))))
                }
            }
            EvaluationBadge(section: .categories, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: categories
    }

    @ViewBuilder
    private var recentTransactions: some View {
        // BEGIN SECTION BODY: transactions
        let evaluationCount = EvaluationCounter.shared.record(.transactions)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let filtered = showPendingOnly ? TransactionMath.pendingOnly(inRange) : inRange
        let rows = TransactionMath.newestFirst(filtered, limit: rowLimit)
        VStack(alignment: .leading) {
            Text("Recent transactions")
                .font(.headline)
            Toggle("Pending only", isOn: $showPendingOnly.timed(.pendingOnly))
            if rows.isEmpty {
                Text("No transactions in this range")
                    .foregroundStyle(.secondary)
            }
            ForEach(rows) { transaction in
                HStack {
                    Image(systemName: transaction.category.systemImage)
                        .foregroundStyle(transaction.category.color)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(transaction.merchant)
                        Text(transaction.date, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(transaction.amount, format: .currency(code: "USD").sign(strategy: .always()))
                        if transaction.isPending {
                            Label("Pending", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
            EvaluationBadge(section: .transactions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: transactions
    }

    @ViewBuilder
    private var liveActivity: some View {
        // BEGIN SECTION BODY: live
        let evaluationCount = EvaluationCounter.shared.record(.live)
        let shownTotal = liveArrivals.reduce(Decimal.zero) { $0 + $1.amount }
        VStack(alignment: .leading) {
            HStack {
                Label("Live activity", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                Spacer()
                Text("\(liveArrivals.count) recent")
                    .foregroundStyle(.secondary)
            }
            if let latest = liveArrivals.last {
                LabeledContent(latest.merchant) {
                    Text(latest.amount, format: .currency(code: "USD"))
                }
            } else {
                Text("Waiting for activity…")
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Pending (shown)") {
                Text(shownTotal, format: .currency(code: "USD"))
            }
            Chart(liveArrivals) { arrival in
                LineMark(x: .value("Arrival", arrival.id), y: .value("Amount", arrival.value))
            }
            .chartXAxis(.hidden)
            .frame(minHeight: 60)
            EvaluationBadge(section: .live, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: live
    }

    @ViewBuilder
    private var cashFlow: some View {
        // BEGIN SECTION BODY: cashFlow
        let evaluationCount = EvaluationCounter.shared.record(.cashFlow)
        let balances = TransactionMath.dailyBalances(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Cash flow")
                .font(.headline)
            Chart(balances) { point in
                LineMark(x: .value("Day", point.day, unit: .day), y: .value("Net", point.amount))
            }
            .frame(minHeight: 160)
            EvaluationBadge(section: .cashFlow, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: cashFlow
    }

    @ViewBuilder
    private var topMerchants: some View {
        // BEGIN SECTION BODY: topMerchants
        let evaluationCount = EvaluationCounter.shared.record(.topMerchants)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let merchants = TransactionMath.topMerchants(of: inRange, limit: 10)
        VStack(alignment: .leading) {
            Text("Top merchants")
                .font(.headline)
            Chart(merchants) { merchant in
                BarMark(x: .value("Spent", merchant.amount), y: .value("Merchant", merchant.merchant))
            }
            .frame(minHeight: 240)
            EvaluationBadge(section: .topMerchants, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: topMerchants
    }

    @ViewBuilder
    private var largestExpenses: some View {
        // BEGIN SECTION BODY: largestTransactions
        let evaluationCount = EvaluationCounter.shared.record(.largestTransactions)
        let inRange = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let largest = TransactionMath.largestExpenses(of: inRange, limit: 10)
        VStack(alignment: .leading) {
            Text("Largest expenses")
                .font(.headline)
            ForEach(largest) { transaction in
                LabeledContent {
                    Text(transaction.amount, format: .currency(code: "USD"))
                } label: {
                    Text(transaction.merchant)
                    Text(transaction.date, format: .dateTime.month().day())
                }
            }
            EvaluationBadge(section: .largestTransactions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: largestTransactions
    }

    @ViewBuilder
    private var weekdayPattern: some View {
        // BEGIN SECTION BODY: weekdayPattern
        let evaluationCount = EvaluationCounter.shared.record(.weekdayPattern)
        let averages = TransactionMath.weekdayAverages(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        let symbols = DemoClock.calendar.shortWeekdaySymbols
        VStack(alignment: .leading) {
            Text("By weekday")
                .font(.headline)
            Chart(averages) { average in
                BarMark(x: .value("Weekday", symbols[average.weekday - 1]), y: .value("Average", average.amount))
            }
            .frame(minHeight: 160)
            EvaluationBadge(section: .weekdayPattern, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: weekdayPattern
    }

    @ViewBuilder
    private var spendingCalendar: some View {
        // BEGIN SECTION BODY: spendingCalendar
        let evaluationCount = EvaluationCounter.shared.record(.spendingCalendar)
        let days = TransactionMath.dailySpend(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        let busiest = days.map(\.amount).max() ?? 0
        VStack(alignment: .leading) {
            Text("Spending calendar")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red.opacity(busiest > 0 ? day.amount / busiest : 0))
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityLabel(Text(day.day, format: .dateTime.month().day()))
                        .accessibilityValue(Text(day.value, format: .currency(code: "USD")))
                }
            }
            EvaluationBadge(section: .spendingCalendar, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: spendingCalendar
    }

    @ViewBuilder
    private var categoryTrends: some View {
        // BEGIN SECTION BODY: categoryTrends
        let evaluationCount = EvaluationCounter.shared.record(.categoryTrends)
        let series = TransactionMath.categorySeries(of: transactions, in: timeRange.dateRange(), calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Category trends")
                .font(.headline)
            ForEach(series) { categorySeries in
                HStack {
                    Label {
                        Text(categorySeries.category.title)
                    } icon: {
                        Image(systemName: categorySeries.category.systemImage)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Chart(categorySeries.points) { point in
                        LineMark(x: .value("Day", point.day, unit: .day), y: .value("Spent", point.amount))
                            .foregroundStyle(categorySeries.category.color)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(minHeight: 36)
                }
            }
            EvaluationBadge(section: .categoryTrends, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: categoryTrends
    }

    @ViewBuilder
    private var versusPrevious: some View {
        // BEGIN SECTION BODY: versusPrevious
        let evaluationCount = EvaluationCounter.shared.record(.versusPrevious)
        let current = TransactionMath.transactions(transactions, in: timeRange.dateRange())
        let previous = TransactionMath.transactions(transactions, in: timeRange.previousDateRange())
        let changes = TransactionMath.categoryComparison(current: current, previous: previous)
        VStack(alignment: .leading) {
            Text("Versus previous period")
                .font(.headline)
            ForEach(changes) { change in
                let before = Text(change.previous, format: .currency(code: "USD"))
                let after = Text(change.current, format: .currency(code: "USD"))
                LabeledContent {
                    Text(change.difference, format: .currency(code: "USD").sign(strategy: .always()))
                } label: {
                    Text(change.category.title)
                    Text("\(before) → \(after)")
                }
            }
            EvaluationBadge(section: .versusPrevious, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: versusPrevious
    }

    @ViewBuilder
    private var upcomingBills: some View {
        // BEGIN SECTION BODY: upcomingBills
        let evaluationCount = EvaluationCounter.shared.record(.upcomingBills)
        let charges = TransactionMath.recurringCharges(of: transactions, calendar: DemoClock.calendar)
        let bills = TransactionMath.upcomingBills(charges, after: DemoClock.anchorDate, within: 30, calendar: DemoClock.calendar)
        VStack(alignment: .leading) {
            Text("Upcoming bills")
                .font(.headline)
            if bills.isEmpty {
                Text("No bills due in the next 30 days")
                    .foregroundStyle(.secondary)
            }
            ForEach(bills) { bill in
                LabeledContent {
                    Text(bill.amount, format: .currency(code: "USD"))
                } label: {
                    Text(bill.merchant)
                    Text(bill.nextDate, format: .dateTime.month().day())
                }
            }
            EvaluationBadge(section: .upcomingBills, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: upcomingBills
    }

    @ViewBuilder
    private var subscriptions: some View {
        // BEGIN SECTION BODY: subscriptions
        let evaluationCount = EvaluationCounter.shared.record(.subscriptions)
        let charges = TransactionMath.recurringCharges(of: transactions, calendar: DemoClock.calendar)
        let monthlyTotal = charges.reduce(Decimal.zero) { $0 + $1.amount }
        VStack(alignment: .leading) {
            Text("Subscriptions")
                .font(.headline)
            ForEach(charges) { charge in
                LabeledContent(charge.merchant) {
                    Text(charge.amount, format: .currency(code: "USD"))
                }
            }
            LabeledContent("Monthly total") {
                Text(monthlyTotal, format: .currency(code: "USD"))
                    .bold()
            }
            EvaluationBadge(section: .subscriptions, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: subscriptions
    }

    @ViewBuilder
    private var savingsGoal: some View {
        // BEGIN SECTION BODY: savingsGoal
        let evaluationCount = EvaluationCounter.shared.record(.savingsGoal)
        let year = TransactionMath.transactions(transactions, in: TimeRange.year.dateRange())
        let net = TransactionMath.net(of: year)
        let goal = TransactionMath.income(of: year) / 5
        VStack(alignment: .leading) {
            Text("Savings goal")
                .font(.headline)
            Gauge(value: TransactionMath.savingsProgress(net: net, goal: goal)) {
                Text("Saved this year")
            } currentValueLabel: {
                Text(net, format: .currency(code: "USD"))
            }
            Text("Goal: \(goal, format: .currency(code: "USD"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            EvaluationBadge(section: .savingsGoal, count: evaluationCount)
        }
        .dashboardCard()
        // END SECTION BODY: savingsGoal
    }
}
