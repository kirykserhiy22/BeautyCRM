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

        // Тиждень починається з понеділка (ринок — Європа)
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
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


    // MARK: - FILTERED APPOINTMENTS

    private var completedAppointments: [Appointment] {

        guard let userID = appState.session.userID else {
            return []
        }

        return appointments.filter { appointment in

            guard
                appointment.userID == userID,
                appointment.status == .completed,
                appointment.finalPrice != nil
            else {
                return false
            }

            return isDateIncluded(
                appointment.startDate
            )
        }
    }


    // MARK: - PERIOD FILTER

    private func isDateIncluded(
        _ date: Date
    ) -> Bool {

        switch selectedPeriod {

        case .week:

            return calendar.isDate(
                date,
                equalTo: now,
                toGranularity: .weekOfYear
            )


        case .month:

            let components =
                calendar.dateComponents(
                    [.year, .month],
                    from: date
                )

            return components.year == selectedYear &&
                   components.month == selectedMonth


        case .year:

            let year =
                calendar.component(
                    .year,
                    from: date
                )

            return year == selectedYear
        }
    }


    // MARK: - TOTAL REVENUE

    private var totalRevenue: Decimal {

        completedAppointments.reduce(Decimal(0)) {

            $0 + ($1.finalPrice ?? 0)
        }
    }


    // MARK: - TOTAL CLIENTS

    private var totalClients: Int {

        Set(
            completedAppointments.map {
                $0.clientID
            }
        ).count
    }


    // MARK: - AVERAGE CHECK

    private var averageCheck: Decimal {

        guard !completedAppointments.isEmpty else {
            return 0
        }

        return totalRevenue /
            Decimal(completedAppointments.count)
    }


    // MARK: - TOTAL HOURS

    private var totalHours: Double {

        let totalMinutes =
            completedAppointments.reduce(0) {

                $0 + $1.duration
            }

        return Double(totalMinutes) / 60
    }


    // MARK: - PROFIT PER HOUR

    private var hourlyIncome: Decimal {

        guard totalHours > 0 else {
            return 0
        }

        // Рахуємо через хвилини, щоб не втрачати точність на дробових годинах
        let totalMinutes =
            completedAppointments.reduce(0) {

                $0 + $1.duration
            }

        return totalRevenue * 60 / Decimal(totalMinutes)
    }


    // MARK: - TOP SERVICES

    private var topServices: [AnalyticsServiceItem] {

        var grouped:
            [String: (
                revenue: Decimal,
                count: Int
            )] = [:]


        for appointment in completedAppointments {

            for service in appointment.services {

                let revenue =
                    service.finalPrice
                    ?? service.plannedPrice


                grouped[
                    service.serviceName,
                    default: (0, 0)
                ].revenue += revenue


                grouped[
                    service.serviceName,
                    default: (0, 0)
                ].count += 1
            }
        }


        return grouped.map { key, value in

            AnalyticsServiceItem(
                name: key,
                revenue: value.revenue,
                count: value.count
            )

        }
        .sorted {

            if $0.count == $1.count {

                return $0.revenue > $1.revenue
            }

            return $0.count > $1.count
        }
    }


    // MARK: - TOP CLIENTS

    private var topClients: [AnalyticsClientItem] {

        let grouped =
            Dictionary(
                grouping: completedAppointments
            ) {
                $0.clientName
            }


        return grouped.map { key, value in

            let spent =
                value.reduce(Decimal(0)) {

                    $0 + ($1.finalPrice ?? 0)
                }


            return AnalyticsClientItem(
                name: key,
                spent: spent,
                visits: value.count
            )

        }
        .sorted {

            if $0.visits == $1.visits {

                return $0.spent > $1.spent
            }

            return $0.visits > $1.visits
        }
    }


    // MARK: - BODY

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    headerSection

                    revenueCard

                    statsGrid

                    topServicesSection

                    topClientsSection
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

    private var revenueCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(localized("analytics.revenue"))
                .font(.headline)


            Text(
                currency(totalRevenue)
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


            chartSelectionInfo


            revenueChart
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

    private var statsGrid: some View {

        LazyVGrid(

            columns: [

                GridItem(.flexible()),

                GridItem(.flexible())
            ],

            spacing: 14
        ) {

            analyticsCard(
                title: "analytics.appointments",
                value: "\(completedAppointments.count)",
                icon: "calendar"
            )


            analyticsCard(
                title: "analytics.clients",
                value: "\(totalClients)",
                icon: "person.2"
            )


            analyticsCard(
                title: "analytics.avgCheck",
                value: currency(averageCheck),
                icon: "eurosign.circle"
            )


            analyticsCard(
                title: "analytics.perHour",
                value: currency(hourlyIncome),
                icon: "clock"
            )
        }
    }


    // MARK: - TOP SERVICES

    private var topServicesSection: some View {

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
                topServices.prefix(3)
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

    private var topClientsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(localized("analytics.mostLoyalClients"))
            .font(
                .title3.bold()
            )


            ForEach(
                topClients.prefix(3)
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


    // MARK: - CHART DATA

    // Межі вибраного періоду: поточний тиждень, вибраний місяць або рік
    private var periodInterval: DateInterval? {

        switch selectedPeriod {

        case .week:

            return calendar.dateInterval(
                of: .weekOfYear,
                for: now
            )


        case .month:

            guard let date = calendar.date(
                from: DateComponents(
                    year: selectedYear,
                    month: selectedMonth
                )
            ) else {
                return nil
            }

            return calendar.dateInterval(of: .month, for: date)


        case .year:

            guard let date = calendar.date(
                from: DateComponents(year: selectedYear)
            ) else {
                return nil
            }

            return calendar.dateInterval(of: .year, for: date)
        }
    }


    // Один стовпчик = день (тиждень, місяць) або місяць (рік)
    private var chartUnit: Calendar.Component {

        selectedPeriod == .year ? .month : .day
    }


    // Стовпчик на кожен день / місяць періоду, навіть якщо доходу не було,
    // щоб графік завжди мав однакову, зрозумілу шкалу
    private var chartData: [AnalyticsChartItem] {

        guard let interval = periodInterval else {
            return []
        }


        var buckets: [Date: (revenue: Decimal, count: Int)] = [:]

        for appointment in completedAppointments {

            guard let bucket = calendar.dateInterval(
                of: chartUnit,
                for: appointment.startDate
            )?.start else {
                continue
            }

            buckets[bucket, default: (0, 0)].revenue +=
                appointment.finalPrice ?? 0

            buckets[bucket, default: (0, 0)].count += 1
        }


        var items: [AnalyticsChartItem] = []
        var date = interval.start

        while date < interval.end {

            let bucket = buckets[date] ?? (0, 0)

            items.append(
                AnalyticsChartItem(
                    date: date,
                    revenue: bucket.revenue,
                    count: bucket.count
                )
            )

            guard let next = calendar.date(
                byAdding: chartUnit,
                value: 1,
                to: date
            ) else {
                break
            }

            date = next
        }

        return items
    }


    private var selectedChartItem: AnalyticsChartItem? {

        guard let selectedChartDate else {
            return nil
        }

        return chartData.first {
            $0.date == selectedChartDate
        }
    }


    // MARK: - REVENUE CHART

    // Кожен стовпчик — окрема «клітинка» на осі X (ключ = номер у періоді),
    // тому підписи завжди стоять рівно під своїм стовпчиком
    private var revenueChart: some View {

        let items = chartData

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
    private var chartSelectionInfo: some View {

        HStack {

            if let item = selectedChartItem {

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


