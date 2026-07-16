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

        let grouped = Dictionary(grouping: completedAppointments) {
            $0.serviceName
        }

        return grouped.map { key, value in

            let revenue = value.reduce(0) {
                $0 + ($1.finalPrice ?? 0)
            }

            return AnalyticsServiceItem(
                name: key,
                revenue: revenue,
                count: value.count
            )
        }
        .sorted {
            $0.revenue > $1.revenue
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
            $0.spent > $1.spent
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

                    BarMark(
                        x: .value("Label", item.label),
                        y: .value("Revenue", item.value)
                    )
                }
            }
            .frame(height: 180)
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

            Text("Top Services")
                .font(.title3.bold())

            ForEach(topServices.prefix(5)) { item in

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

            Text("Top Clients")
                .font(.title3.bold())

            ForEach(topClients.prefix(5)) { item in

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

        let grouped = Dictionary(grouping: completedAppointments) {
            calendar.startOfDay(for: $0.startDate)
        }

        return grouped.map { key, value in

            let total = value.reduce(0) {
                $0 + ($1.finalPrice ?? 0)
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"

            return AnalyticsChartItem(
                label: formatter.string(from: key),
                value: total
            )
        }
        .sorted {
            $0.label < $1.label
        }
    }

    // MARK: - FORMATTERS

    private func currency(_ value: Double) -> String {

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"

        return formatter.string(from: NSNumber(value: value)) ?? "€0"
    }
}


import Foundation

struct AnalyticsServiceItem: Identifiable {

    let id = UUID()

    let name: String
    let revenue: Double
    let count: Int
}

struct AnalyticsClientItem: Identifiable {

    let id = UUID()

    let name: String
    let spent: Double
    let visits: Int
}

struct AnalyticsChartItem: Identifiable {

    let id = UUID()

    let label: String
    let value: Double
}
