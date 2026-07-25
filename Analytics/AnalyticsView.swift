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

    // MARK: - DATA

    @Query private var appointments: [Appointment]

    // MARK: - FILTER

    @State private var selectedPeriod: AnalyticsPeriod = .month

    // MARK: - THEME

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // MARK: - FILTERED APPOINTMENTS

    private var completedAppointments: [Appointment] {

        guard let userID = appState.session.userID else {
            return []
        }

        let calendar = Calendar.current
        let now = Date()

        return appointments.filter {

            $0.userID == userID &&
            $0.status == .completed &&
            $0.finalPrice != nil &&
            selectedPeriod.contains(date: $0.startDate, now: now, calendar: calendar)
        }
    }

    // MARK: - TOTAL REVENUE

    private var totalRevenue: Double {

        completedAppointments.reduce(0) {
            $0 + ($1.finalPrice ?? 0)
        }
    }

    // MARK: - TOTAL CLIENTS

    private var totalClients: Int {

        Set(
            completedAppointments.map { $0.clientID }
        ).count
    }

    // MARK: - AVERAGE CHECK

    private var averageCheck: Double {

        guard !completedAppointments.isEmpty else {
            return 0
        }

        return totalRevenue / Double(completedAppointments.count)
    }

    // MARK: - TOTAL HOURS

    private var totalHours: Double {

        let totalMinutes = completedAppointments.reduce(0) {
            $0 + $1.duration
        }

        return Double(totalMinutes) / 60
    }

    // MARK: - PROFIT PER HOUR

    private var hourlyIncome: Double {

        guard totalHours > 0 else {
            return 0
        }

        return totalRevenue / totalHours
    }

    // MARK: - TOP SERVICES

    private var topServices: [AnalyticsServiceItem] {

        var grouped: [String: (revenue: Double, count: Int)] = [:]

        for appointment in completedAppointments {

            for service in appointment.services {

                let revenue =
                    service.finalPrice
                    ?? service.plannedPrice

                grouped[service.serviceName, default: (0, 0)].revenue += revenue
                grouped[service.serviceName, default: (0, 0)].count += 1
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

        let grouped = Dictionary(grouping: completedAppointments) {
            $0.clientName
        }

        return grouped.map { key, value in

            let spent = value.reduce(0) {
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
            .navigationTitle("Analytics")
        }
    }

    // MARK: - HEADER

    private var headerSection: some View {

        Picker("Period", selection: $selectedPeriod) {

            ForEach(AnalyticsPeriod.allCases) { period in

                Text(period.title)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .tint(colors.accent)
    }

    // MARK: - REVENUE CARD

    private var revenueCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Revenue")
                .font(.headline)

            Text(currency(totalRevenue))
                .font(.system(size: 36, weight: .bold))

            Text(selectedPeriod.subtitle)
                .foregroundColor(colors.textSecondary)

            Chart {

                ForEach(chartData) { item in


                    AreaMark(

                        x:
                            .value(
                                "Date",
                                item.date
                            ),

                        y:
                            .value(
                                "Revenue",
                                item.value
                            )
                    )
                    .foregroundStyle(
                        colors.accent.opacity(0.15)
                    )



                    LineMark(

                        x:
                            .value(
                                "Date",
                                item.date
                            ),

                        y:
                            .value(
                                "Revenue",
                                item.value
                            )
                    )
                    .foregroundStyle(
                        colors.accent
                    )
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 3
                        )
                    )



                    PointMark(

                        x:
                            .value(
                                "Date",
                                item.date
                            ),

                        y:
                            .value(
                                "Revenue",
                                item.value
                            )
                    )
                    .foregroundStyle(
                        colors.accent
                    )
                }
            }
            .chartXAxis {

                AxisMarks {

                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(colors.card)
        .cornerRadius(24)
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
                title: "Appointments",
                value: "\(completedAppointments.count)",
                icon: "calendar"
            )

            analyticsCard(
                title: "Clients",
                value: "\(totalClients)",
                icon: "person.2"
            )

            analyticsCard(
                title: "Avg Check",
                value: currency(averageCheck),
                icon: "eurosign.circle"
            )

            analyticsCard(
                title: "Per Hour",
                value: currency(hourlyIncome),
                icon: "clock"
            )
        }
    }

    // MARK: - TOP SERVICES

    private var topServicesSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Most Popular Services")
                .font(.title3.bold())

            ForEach(topServices.prefix(3)) { item in

                HStack {

                    VStack(alignment: .leading, spacing: 4) {

                        Text(item.name)
                            .font(.headline)

                        Text("\(item.count) appointments")
                            .font(.caption)
                            .foregroundColor(colors.textSecondary)
                    }

                    Spacer()

                    Text(currency(item.revenue))
                        .font(.headline)
                }
                .padding()
                .background(colors.card)
                .cornerRadius(18)
            }
        }
    }

    // MARK: - TOP CLIENTS

    private var topClientsSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Most Loyal Clients")
                .font(.title3.bold())

            ForEach(topClients.prefix(3)) { item in

                HStack {

                    VStack(alignment: .leading, spacing: 4) {

                        Text(item.name)
                            .font(.headline)

                        Text("\(item.visits) visits")
                            .font(.caption)
                            .foregroundColor(colors.textSecondary)
                    }

                    Spacer()

                    Text(currency(item.spent))
                        .font(.headline)
                }
                .padding()
                .background(colors.card)
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

        VStack(alignment: .leading, spacing: 10) {

            Image(systemName: icon)
                .font(.title2)

            Text(value)
                .font(.title2.bold())

            Text(title)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.card)
        .cornerRadius(20)
    }

    // MARK: - CHART DATA

    private var chartData: [AnalyticsChartItem] {

        let calendar = Calendar.current

        var grouped: [Date: Double] = [:]


        for appointment in completedAppointments {

            let date: Date


            switch selectedPeriod {


            case .week:

                date = calendar.startOfDay(
                    for: appointment.startDate
                )


            case .month:

                date = calendar.startOfDay(
                    for: appointment.startDate
                )


            case .year:

                let components =
                calendar.dateComponents(
                    [.year,.month],
                    from: appointment.startDate
                )

                date =
                calendar.date(
                    from: components
                ) ?? appointment.startDate

            }


            grouped[date, default: 0] +=
            appointment.finalPrice ?? 0
        }


        return grouped.map {

            AnalyticsChartItem(
                date: $0.key,
                value: $0.value
            )

        }
        .sorted {
            $0.date < $1.date
        }
    }

    // MARK: - FORMATTERS

    private func currency(
        _ value: Double
    ) -> String {

        currency.format(value)
    }
}



