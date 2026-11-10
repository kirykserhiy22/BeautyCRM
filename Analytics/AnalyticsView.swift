//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 20.05.26.
//


import SwiftUI
import SwiftData
import Charts


struct AnalyticsView: View {

    // MARK: - ENV

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var localization: LocalizationManager

    // MARK: - DATA

    @Query private var appointments: [Appointment]

    // Актуальні імена клієнтів і назви послуг для топів (і видалені теж)
    @Query private var clients: [Client]
    @Query private var services: [Service]


    // MARK: - FILTER

    @State private var selectedPeriod: AnalyticsPeriod = .month

    // Скільки тижнів назад дивимось: 0 — поточний (#58)
    @State private var weekOffset = 0

    @State private var selectedMonth: Int = Calendar.current.component(
        .month,
        from: Date()
    )

    @State private var selectedYear: Int = Calendar.current.component(
        .year,
        from: Date()
    )

    // Стовпчик графіка, на який натиснули (початок дня або місяця)
    @State private var selectedChartDate: Date?


    // MARK: - THEME

    private var colors: ThemeColors {

        theme.colors(
            for: theme.currentTheme
        )
    }
    // MARK: - LOCALIZATION

    private func localized(_ key: String) -> String {
        localization.localizedString(for: key)
    }

    // MARK: - CALENDAR

    private var calendar: Calendar {
        AnalyticsEngine.calendar()
    }


    // MARK: - CURRENT DATE

    private var now: Date {

        Date()
    }


    // Будь-який день вибраного тижня
    private var weekReference: Date {
        calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
    }


    // MARK: - AVAILABLE YEARS

    private var availableYears: [Int] {

        let currentYear =
            calendar.component(
                .year,
                from: now
            )

        let appointmentYears =
            appointments.compactMap {

                calendar.dateComponents(
                    [.year],
                    from: $0.startDate
                ).year
            }

        let minimumYear =
            appointmentYears.min()
            ?? currentYear

        return Array(
            stride(
                from: currentYear,
                through: minimumYear,
                by: -1
            )
        )
    }


    // MARK: - MONTH NAMES

    private var monthNames: [String] {
        AppFormatting.monthNames(
            locale: localization.locale
        )
    }


    // MARK: - SUMMARY

    // Усі цифри екрана рахує AnalyticsEngine — один раз на оновлення екрана
    private func makeSummary() -> AnalyticsSummary? {

        guard
            let userID = appState.session.userID,
            let interval = AnalyticsEngine.interval(
                for: selectedPeriod,
                reference: weekReference,
                month: selectedMonth,
                year: selectedYear,
                calendar: calendar
            )
        else {
            return nil
        }

        let ownClients = clients.filter { $0.userID == userID }
        let ownServices = services.filter { $0.userID == userID }

        return AnalyticsEngine.summary(
            appointments: appointments,
            userID: userID,
            clientNames: Dictionary(ownClients.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first }),
            serviceNames: Dictionary(ownServices.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first }),
            period: selectedPeriod,
            interval: interval,
            calendar: calendar
        )
    }


    // MARK: - BODY

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    headerSection

                    if let summary = makeSummary() {

                        revenueCard(summary)

                        if summary.appointmentCount == 0 {
                            EmptyStateView(
                                systemImage: "chart.bar",
                                titleKey: "empty.analytics.title",
                                messageKey: "empty.analytics.message"
                            )
                        } else {
                            statsGrid(summary)

                            insightsCard(summary)
                        }
                    }
                }
                .padding()
            }
            .background(colors.background)
            .navigationTitle(localized("analytics.title"))
            .onChange(of: selectedPeriod) { selectedChartDate = nil }
            .onChange(of: weekOffset) { selectedChartDate = nil }
            .onChange(of: selectedMonth) { selectedChartDate = nil }
            .onChange(of: selectedYear) { selectedChartDate = nil }
        }
    }


    // MARK: - HEADER

    private var headerSection: some View {

        VStack(spacing: 12) {

            periodPicker

            periodSelection
        }
        .tint(colors.accent)
    }


    // Свій перемикач: системний не бере фірмовий колір
    private var periodPicker: some View {

        HStack(spacing: 2) {

            ForEach(AnalyticsPeriod.allCases) { period in

                let isSelected = selectedPeriod == period

                Button {
                    selectedPeriod = period
                } label: {
                    Text(localized("analytics.\(period.rawValue)"))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? .white : colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? colors.buttonPrimary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }


    // MARK: - PERIOD SELECTION

    @ViewBuilder
    private var periodSelection: some View {

        switch selectedPeriod {

        case .week:

            HStack {

                Button {
                    weekOffset += 1
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(localized("analytics.previousWeek"))

                Spacer()

                Image(
                    systemName: "calendar"
                )
                .foregroundColor(
                    colors.accent
                )

                Text(
                    currentWeekText
                )
                .font(.subheadline)
                .foregroundColor(
                    colors.textSecondary
                )

                Spacer()

                Button {
                    weekOffset -= 1
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .disabled(weekOffset == 0)
                .accessibilityLabel(localized("analytics.nextWeek"))
            }


        case .month:

            HStack(spacing: 10) {

                monthPicker

                yearPicker
            }


        case .year:

            HStack {

                yearPicker

                Spacer()
            }
        }
    }


    // MARK: - MONTH PICKER

    private var monthPicker: some View {

        Menu {

            ForEach(
                1...12,
                id: \.self
            ) { month in

                Button {

                    selectedMonth = month

                } label: {

                    HStack {

                        Text(
                            monthNames[month - 1]
                        )

                        if selectedMonth == month {

                            Spacer()

                            Image(
                                systemName: "checkmark"
                            )
                        }
                    }
                }
            }

        } label: {

            HStack(spacing: 6) {

                Text(
                    monthNames[
                        selectedMonth - 1
                    ]
                )

                Image(
                    systemName: "chevron.down"
                )
                .font(.caption)
            }
            .foregroundColor(
                colors.textPrimary
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                colors.card
            )
            .cornerRadius(12)
        }
    }


    // MARK: - YEAR PICKER

    private var yearPicker: some View {

        Menu {

            ForEach(
                availableYears,
                id: \.self
            ) { year in

                Button {

                    selectedYear = year

                } label: {

                    HStack {

                        Text(
                            String(year)
                        )

                        if selectedYear == year {

                            Spacer()

                            Image(
                                systemName: "checkmark"
                            )
                        }
                    }
                }
            }

        } label: {

            HStack(spacing: 6) {

                Text(
                    String(selectedYear)
                )

                Image(
                    systemName: "chevron.down"
                )
                .font(.caption)
            }
            .foregroundColor(
                colors.textPrimary
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                colors.card
            )
            .cornerRadius(12)
        }
    }

    // MARK: - CURRENT WEEK TEXT

    private var currentWeekText: String {

        guard
            let interval =
                calendar.dateInterval(
                    of: .weekOfYear,
                    for: weekReference
                )
        else {
            return localized("analytics.currentWeek")
        }


        let locale = localization.locale

        return "\(AppFormatting.pattern("dd MMM", interval.start, locale: locale)) – \(AppFormatting.pattern("dd MMM", interval.end.addingTimeInterval(-1), locale: locale))"
    }


    // MARK: - REVENUE CARD

    // Натиснутий стовпчик тимчасово показує свої дані на місці головної суми
    private func revenueCard(_ summary: AnalyticsSummary) -> some View {

        let selected = selectedChartItem(in: summary.chart)

        return VStack(alignment: .leading, spacing: 4) {

            Text(selected.map { selectionTitle(for: $0.date) } ?? "\(periodDescription) · \(localized("analytics.earned"))")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)

            Text(currency(selected?.revenue ?? summary.revenue))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // ZStack тримає висоту, щоб графік не стрибав при виборі стовпчика
            ZStack(alignment: .topLeading) {

                revenueNotes(summary)
                    .opacity(selected == nil ? 1 : 0)

                if let selected {
                    Text(CountFormatting.appointments(selected.count, locale: localization.locale))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
            }

            // Порожній графік лише займав би місце над підказкою «немає записів»
            if summary.appointmentCount > 0 {
                revenueChart(summary.chart)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.card)
        .cornerRadius(24)
    }


    private func revenueNotes(_ summary: AnalyticsSummary) -> some View {

        VStack(alignment: .leading, spacing: 2) {

            if let comparison = summary.comparison {
                Text(comparisonText(comparison))
                    .font(.subheadline)
                    .foregroundColor(comparison.percent > 0 ? colors.accent : colors.textSecondary)
            }

            if summary.expectedRevenue > 0 {
                Text(
                    String(
                        format: localized("analytics.expectedRevenue"),
                        currency(summary.expectedRevenue)
                    )
                )
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
            }
        }
    }


    private func comparisonText(_ comparison: AnalyticsComparison) -> String {

        let scope = comparison.isPartial ? "soFar." : ""
        let previous = localized("analytics.compare.\(scope)\(selectedPeriod.rawValue)")

        if comparison.percent == 0 {
            return String(format: localized("analytics.compare.same"), previous)
        }

        return String(
            format: localized(comparison.percent > 0 ? "analytics.compare.more" : "analytics.compare.less"),
            percentText(abs(comparison.percent)),
            previous
        )
    }


    private func percentText(_ percent: Int) -> String {
        percent.formatted(.percent.locale(localization.locale))
    }


    // MARK: - PERIOD DESCRIPTION

    private var periodDescription: String {

        switch selectedPeriod {

        case .week:

            return currentWeekText


        case .month:

            let month = monthNames[selectedMonth - 1].capitalized(with: localization.locale)
            let isThisYear = selectedYear == calendar.component(.year, from: now)

            return isThisYear ? month : "\(month) \(selectedYear)"


        case .year:

            return String(selectedYear)
        }
    }


    // MARK: - STATS GRID

    private func statsGrid(_ summary: AnalyticsSummary) -> some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            statTile(value: "\(summary.appointmentCount)", title: "analytics.appointments")
            statTile(value: currency(summary.averageCheck), title: "analytics.avgCheck")
            statTile(value: "\(summary.clientCount)", title: "analytics.clients")
            statTile(value: currency(summary.hourlyIncome), title: "analytics.perHour")
        }
    }


    private func statTile(value: String, title: String) -> some View {

        VStack(alignment: .leading, spacing: 2) {

            Text(value)
                .font(.title3.bold())
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(localized(title))
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(colors.card)
        .cornerRadius(18)
    }


    // MARK: - INSIGHTS

    private func insightsCard(_ summary: AnalyticsSummary) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            clientsInsight(summary)

            if let leader = summary.leadingService {
                insightRow(
                    icon: "chart.pie",
                    text: String(
                        format: localized("analytics.serviceShare"),
                        leader.name,
                        percentText(leader.percent)
                    )
                )
            }

            Divider()
                .overlay(colors.divider)

            VStack(alignment: .leading, spacing: 6) {

                Text(localized("analytics.topServices"))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)

                ForEach(summary.topServices.prefix(3)) { service in
                    rankRow(
                        name: service.name,
                        detail: CountFormatting.appointments(service.count, locale: localization.locale)
                    )
                }
            }

            clientsRanking(summary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.card)
        .cornerRadius(18)
    }


    // За рік важливо, чи клієнти повертаються; за тиждень чи місяць — скільки нових
    @ViewBuilder
    private func clientsInsight(_ summary: AnalyticsSummary) -> some View {

        if selectedPeriod == .year {
            insightRow(
                icon: "person.2",
                text: String(
                    format: localized("analytics.yearClients"),
                    summary.clientCount,
                    percentText(summary.returningClientPercent)
                )
            )
        } else {
            insightRow(
                icon: "person.badge.plus",
                text: String(format: localized("analytics.newClients"), summary.newClientCount)
            )
        }
    }


    // Постійним клієнт стає за довший час, тому за тиждень чи місяць — лише хто приніс більше
    @ViewBuilder
    private func clientsRanking(_ summary: AnalyticsSummary) -> some View {

        if selectedPeriod == .year {

            VStack(alignment: .leading, spacing: 6) {

                Text(localized("analytics.loyalClients"))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)

                ForEach(summary.topClients.prefix(3)) { client in
                    rankRow(
                        name: client.name,
                        detail: CountFormatting.visits(client.visits, locale: localization.locale)
                    )
                }
            }

        } else if let client = summary.topClientBySpending {

            topRow(
                title: "analytics.topClient",
                name: client.name,
                detail: currency(client.spent)
            )
        }
    }


    private func rankRow(name: String, detail: String) -> some View {

        HStack(alignment: .firstTextBaseline) {

            Text(name)
                .font(.headline)
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(detail)
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }


    private func insightRow(icon: String, text: String) -> some View {

        Label {
            Text(text)
                .font(.subheadline)
                .foregroundColor(colors.textPrimary)
        } icon: {
            Image(systemName: icon)
                .foregroundColor(colors.accent)
        }
    }


    private func topRow(title: String, name: String, detail: String) -> some View {

        HStack(alignment: .firstTextBaseline) {

            VStack(alignment: .leading, spacing: 2) {

                Text(localized(title))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)

                Text(name)
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Text(detail)
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }


    // MARK: - CHART SELECTION

    private func selectedChartItem(in items: [AnalyticsChartItem]) -> AnalyticsChartItem? {

        guard let selectedChartDate else {
            return nil
        }

        return items.first {
            $0.date == selectedChartDate
        }
    }


    // MARK: - REVENUE CHART

    // Кожен стовпчик — окрема «клітинка» на осі X (ключ = номер у періоді),
    // тому підписи завжди стоять рівно під своїм стовпчиком
    private func revenueChart(_ items: [AnalyticsChartItem]) -> some View {

        return Chart(Array(items.enumerated()), id: \.element.date) { index, item in

            BarMark(
                x: .value(
                    localized("analytics.chart.date"),
                    String(index)
                ),
                y: .value(
                    localized("analytics.chart.revenue"),
                    item.value
                ),
                width: .ratio(0.7)
            )
            .foregroundStyle(
                selectedChartDate == nil || selectedChartDate == item.date
                    ? colors.accent
                    : colors.accent.opacity(0.3)
            )
            .cornerRadius(4)
        }
        .chartXAxis {

            AxisMarks(values: xAxisLabelKeys(count: items.count)) { value in

                AxisValueLabel {

                    if
                        let key = value.as(String.self),
                        let index = Int(key),
                        items.indices.contains(index)
                    {
                        Text(axisLabel(for: items[index].date))
                            .font(.caption2)
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartOverlay { proxy in

            GeometryReader { geometry in

                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { tap in
                                selectBar(
                                    at: tap.location,
                                    proxy: proxy,
                                    geometry: geometry,
                                    items: items
                                )
                            }
                    )
            }
        }
        .frame(
            height: 120
        )
    }


    // Які стовпчики підписувати: у місяці — 1, 5, 10, 15…, інакше всі
    private func xAxisLabelKeys(count: Int) -> [String] {

        guard selectedPeriod == .month else {
            return (0..<count).map { String($0) }
        }

        let days = [1, 5, 10, 15, 20, 25, 30].filter { $0 <= count }

        return days.map { String($0 - 1) }
    }


    // Підпис під стовпчиком: день тижня, число місяця або місяць
    private func axisLabel(for date: Date) -> String {

        let locale = localization.locale

        switch selectedPeriod {

        case .week:
            return AppFormatting.template("EEE", date, locale: locale)

        case .month:
            return AppFormatting.pattern("d", date, locale: locale)

        case .year:
            // 12 підписів мають влізти в ширину екрана: 3 літери без крапки
            return String(
                AppFormatting.template("LLL", date, locale: locale)
                    .replacingOccurrences(of: ".", with: "")
                    .prefix(3)
            )
        }
    }


    // Натискання на стовпчик показує його суму; повторне — ховає
    private func selectBar(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy,
        items: [AnalyticsChartItem]
    ) {

        guard let plotFrame = proxy.plotFrame else {
            return
        }

        let x = location.x - geometry[plotFrame].origin.x

        guard
            let key: String = proxy.value(atX: x),
            let index = Int(key),
            items.indices.contains(index)
        else {
            selectedChartDate = nil
            return
        }

        let date = items[index].date

        selectedChartDate =
            selectedChartDate == date ? nil : date
    }



    private func selectionTitle(for date: Date) -> String {

        AppFormatting.template(
            selectedPeriod == .year ? "LLLLyyyy" : "EEEEdMMMM",
            date,
            locale: localization.locale
        )
    }


    // MARK: - FORMATTERS

    private func currency(
        _ value: Decimal
    ) -> String {

        currency.format(
            value
        )
    }
}


