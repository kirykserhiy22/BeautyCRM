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
                reference: now,
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

                        statsGrid(summary)

                        topServicesSection(summary)

                        topClientsSection(summary)
                    }
                }
                .padding()
            }
            .background(colors.background)
            .navigationTitle(localized("analytics.title"))
            .onChange(of: selectedPeriod) { selectedChartDate = nil }
            .onChange(of: selectedMonth) { selectedChartDate = nil }
            .onChange(of: selectedYear) { selectedChartDate = nil }
        }
    }


    // MARK: - HEADER

    private var headerSection: some View {

        VStack(spacing: 12) {

            Picker(
                localized("analytics.period"),
                selection: $selectedPeriod
            ) {

                ForEach(
                    AnalyticsPeriod.allCases
                ) { period in

                    Text(localized("analytics.\(period.rawValue)"))
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .tint(colors.accent)


            periodSelection
        }
    }


    // MARK: - PERIOD SELECTION

    @ViewBuilder
    private var periodSelection: some View {

        switch selectedPeriod {

        case .week:

            HStack {

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
                    for: now
                )
        else {
            return "Current week"
        }


        let formatter = DateFormatter()

        formatter.locale = localization.locale

        formatter.dateFormat = "dd MMM"


        return "\(formatter.string(from: interval.start)) – \(formatter.string(from: interval.end.addingTimeInterval(-1)))"
    }


    // MARK: - REVENUE CARD

    private func revenueCard(_ summary: AnalyticsSummary) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(localized("analytics.revenue"))
                .font(.headline)


            Text(
                currency(summary.revenue)
            )
            .font(
                .system(
                    size: 36,
                    weight: .bold
                )
            )


            Text(
                periodDescription
            )
            .foregroundColor(
                colors.textSecondary
            )


            chartSelectionInfo(summary.chart)


            revenueChart(summary.chart)
        }
        .padding()
        .background(
            colors.card
        )
        .cornerRadius(24)
    }


    // MARK: - PERIOD DESCRIPTION

    private var periodDescription: String {

        switch selectedPeriod {

        case .week:

            return localized("analytics.currentWeekOverview")


        case .month:

            return "\(monthNames[selectedMonth - 1]) \(selectedYear)"


        case .year:

            return "\(selectedYear) — \(localized("analytics.selectedYearOverview"))"
        }
    }


    // MARK: - STATS GRID

    private func statsGrid(_ summary: AnalyticsSummary) -> some View {

        LazyVGrid(

            columns: [

                GridItem(.flexible()),

                GridItem(.flexible())
            ],

            spacing: 14
        ) {

            analyticsCard(
                title: "analytics.appointments",
                value: "\(summary.appointmentCount)",
                icon: "calendar"
            )


            analyticsCard(
                title: "analytics.clients",
                value: "\(summary.clientCount)",
                icon: "person.2"
            )


            analyticsCard(
                title: "analytics.avgCheck",
                value: currency(summary.averageCheck),
                icon: "eurosign.circle"
            )


            analyticsCard(
                title: "analytics.perHour",
                value: currency(summary.hourlyIncome),
                icon: "clock"
            )
        }
    }


    // MARK: - TOP SERVICES

    private func topServicesSection(_ summary: AnalyticsSummary) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(localized("analytics.mostPopularServices")
            )
            .font(
                .title3.bold()
            )


            ForEach(
                summary.topServices.prefix(3)
            ) { item in

                HStack {

                    Image(
                        systemName: "scissors"
                    )
                    .foregroundColor(
                        colors.accent
                    )
                    .font(.title3)


                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            item.name
                        )
                        .font(.headline)


                        Text(
                            CountFormatting.appointments(
                                item.count,
                                locale: localization.locale
                            )
                        )
                        .font(.caption)
                        .foregroundColor(
                            colors.textSecondary
                        )
                    }


                    Spacer()


                    Text(
                        currency(item.revenue)
                    )
                    .font(.headline)
                }
                .padding()
                .background(
                    colors.card
                )
                .cornerRadius(18)
            }
        }
    }


    // MARK: - TOP CLIENTS

    private func topClientsSection(_ summary: AnalyticsSummary) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(localized("analytics.mostLoyalClients"))
            .font(
                .title3.bold()
            )


            ForEach(
                summary.topClients.prefix(3)
            ) { item in

                HStack {

                    Image(
                        systemName: "person.crop.circle"
                    )
                    .foregroundColor(
                        colors.accent
                    )
                    .font(.title3)


                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            item.name
                        )
                        .font(.headline)


                        Text(
                            CountFormatting.visits(
                                item.visits,
                                locale: localization.locale
                            )
                        )
                        .font(.caption)
                        .foregroundColor(
                            colors.textSecondary
                        )
                    }


                    Spacer()


                    Text(
                        currency(item.spent)
                    )
                    .font(.headline)
                }
                .padding()
                .background(
                    colors.card
                )
                .cornerRadius(18)
            }
        }
    }


    // MARK: - ANALYTICS CARD

    private func analyticsCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Image(
                systemName: icon
            )
            .font(.title2)
            .foregroundColor(
                colors.accent
            )


            Text(
                value
            )
            .font(
                .title2.bold()
            )


            Text(
                localized(title)
            )
            .foregroundColor(
                colors.textSecondary
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            colors.card
        )
        .cornerRadius(20)
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
                    }
                }
            }
        }
        .chartYAxis {

            AxisMarks { value in

                AxisGridLine()

                AxisValueLabel {

                    if let amount = value.as(Double.self) {
                        Text(
                            amount.formatted(
                                .number.notation(.compactName)
                            )
                        )
                    }
                }
            }
        }
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
            height: 200
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

        let formatter = DateFormatter()
        formatter.locale = localization.locale

        switch selectedPeriod {

        case .week:
            formatter.setLocalizedDateFormatFromTemplate("EEE")

        case .month:
            formatter.dateFormat = "d"

        case .year:
            // 12 підписів мають влізти в ширину екрана: 3 літери без крапки
            formatter.setLocalizedDateFormatFromTemplate("LLL")

            return String(
                formatter.string(from: date)
                    .replacingOccurrences(of: ".", with: "")
                    .prefix(3)
            )
        }

        return formatter.string(from: date)
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


    // Рядок над графіком: дані вибраного стовпчика або підказка
    private func chartSelectionInfo(_ items: [AnalyticsChartItem]) -> some View {

        HStack {

            if let item = selectedChartItem(in: items) {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(selectionTitle(for: item.date))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)

                    HStack(
                        alignment: .firstTextBaseline,
                        spacing: 8
                    ) {

                        Text(currency(item.revenue))
                            .font(.title3.bold())
                            .foregroundColor(colors.textPrimary)

                        Text(
                            CountFormatting.appointments(
                                item.count,
                                locale: localization.locale
                            )
                        )
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                    }
                }

            } else {

                Label(
                    localized("analytics.chart.tapHint"),
                    systemImage: "hand.tap"
                )
                .font(.footnote)
                .foregroundColor(colors.textSecondary)
            }

            Spacer()
        }
        .frame(
            minHeight: 48,
            alignment: .leading
        )
    }


    private func selectionTitle(for date: Date) -> String {

        let formatter = DateFormatter()
        formatter.locale = localization.locale

        formatter.setLocalizedDateFormatFromTemplate(
            selectedPeriod == .year ? "LLLLyyyy" : "EEEEdMMMM"
        )

        return formatter.string(from: date)
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


