//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI
import SwiftData


struct HomeView: View {


    @Query private var appointments: [Appointment]

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<Client> { $0.deletedAt == nil })
    private var clients: [Client]

    private var firstName: String {
        profiles.first { $0.authUserID == appState.session.userID }?.firstName ?? ""
    }

    private var userAppointments: [Appointment] {

        guard let userID = appState.session.userID else {
            return []
        }

        return appointments.filter {
            $0.userID == userID
        }
    }



    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    HomeHeaderView(firstName: firstName)

                    // Раз на 30 секунд оновлює «через 40 хв» і стан запису
                    TimelineView(.periodic(from: .now, by: 30)) { _ in

                        VStack(alignment: .leading, spacing: 20) {

                            if let dashboardAppointment {

                                DashboardAppointmentCard(
                                    appointment: dashboardAppointment,
                                    title: dashboardTitle,
                                    services: servicesText(dashboardAppointment),
                                    timeText: timeText(dashboardAppointment),
                                    statusText: statusText(dashboardAppointment),
                                    statusColor: dashboardColor,
                                    phoneURL: phoneURL(dashboardAppointment)
                                )

                            } else if !todayAppointments.isEmpty && remainingToday == 0 {

                                // Сьогодні записи були, і всі вже завершені
                                DashboardMessageCard(
                                    title: "home.dayComplete",
                                    message: "home.allDoneToday"
                                )

                            } else {

                                DashboardMessageCard(message: "home.noPlanned")
                            }

                            if !todayAppointments.isEmpty {
                                TodayStatsCard(
                                    totalAppointments: todayAppointments.count,
                                    completedAppointments: completedToday
                                )
                            }

                            QuickActionsSection()

                            if !laterTodayText.isEmpty {
                                laterTodayCard
                            }
                        }
                    }

                }
                .padding()
            }
            .background(colors.background.ignoresSafeArea())
            
        }
    }
}






// MARK: - APPOINTMENT LOGIC

private extension HomeView {


    var todayAppointments: [Appointment] {

        userAppointments.filter {

            Calendar.current.isDateInToday(
                $0.startDate
            )
            &&
            $0.status != .cancelled
            &&
            $0.status != .archived
        }
        .sorted {
            $0.startDate < $1.startDate
        }
    }



    var completedToday: Int {

        todayAppointments.filter {

            $0.status == .completed

        }
        .count
    }



    var remainingToday: Int {

        todayAppointments.filter {

            $0.status == .active

        }
        .count
    }




    var dashboardAppointment: Appointment? {

        let now = Date()


        let active = userAppointments.filter {

            $0.status == .active

        }



        // 1. запис зараз триває

        if let current = active.first(where: {

            $0.startDate <= now &&
            $0.endDate >= now

        }) {

            return current
        }



        // 2. запис закінчився, але не завершений

        if let unfinished = active
            .filter({

                $0.endDate < now

            })
            .sorted(by: {

                $0.endDate > $1.endDate

            })
            .first {

            return unfinished
        }



        // 3. наступний запис

        return active
            .filter({

                $0.startDate > now

            })
            .sorted {

                $0.startDate < $1.startDate

            }
            .first
    }



    var dashboardTitle: String {

        guard let appointment = dashboardAppointment
        else {
            return ""
        }


        let now = Date()


        if appointment.startDate <= now &&
            appointment.endDate >= now {

            return "home.currentAppointment"
        }


        if appointment.endDate < now {

            return "home.needsCompletion"
        }


        return "home.nextAppointment"
    }




    func statusText(_ appointment: Appointment) -> String {

        let now = Date()

        if appointment.endDate < now {
            return localization.localizedString(for: "home.waitingForCompletion")
        }

        if appointment.startDate <= now {
            let left = String(
                format: localization.localizedString(for: "home.endsInMinutes"),
                locale: localization.locale,
                HomeTiming.minutes(from: now, to: appointment.endDate)
            )
            return "\(localization.localizedString(for: "home.inProgress")) · \(left)"
        }

        switch HomeTiming.countdown(from: now, to: appointment.startDate) {

        case .minutes(let minutes):
            return String(
                format: localization.localizedString(for: "home.startsInMinutes"),
                locale: localization.locale,
                minutes
            )

        case .hours(let hours, let minutes):
            return String(
                format: localization.localizedString(for: "home.startsInHours"),
                locale: localization.locale,
                hours,
                minutes
            )

        case .otherDay:
            return dateText(appointment)
        }
    }


    func phoneURL(_ appointment: Appointment) -> URL? {
        clients
            .first { $0.id == appointment.clientID }?
            .phone
            .flatMap { ContactLinks.phone($0) }
    }


    // Решта сьогоднішніх записів: «13:30 Anna · 15:00 Lena · ще 1»
    var laterTodayText: String {

        let now = Date()

        let later = todayAppointments.filter {
            $0.status == .active
                && $0.startDate > now
                && $0.id != dashboardAppointment?.id
        }

        var parts = later.prefix(2).map {
            "\(AppFormatting.clock($0.startDate)) \($0.clientName)"
        }

        if later.count > 2 {
            parts.append(
                String(
                    format: localization.localizedString(for: "home.moreCount"),
                    locale: localization.locale,
                    later.count - 2
                )
            )
        }

        return parts.joined(separator: " · ")
    }


    var laterTodayCard: some View {

        VStack(alignment: .leading, spacing: 4) {

            Text("home.laterToday")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)

            Text(laterTodayText)
                .font(.subheadline.weight(.medium))
                .foregroundColor(colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colors.card)
        )
    }


    var dashboardColor: Color {

        guard let appointment = dashboardAppointment
        else {
            return colors.textSecondary
        }


        let now = Date()


        if appointment.endDate < now {

            return colors.warning
        }


        if appointment.startDate <= now {

            return colors.success
        }


        return colors.accent
    }






    func servicesText(
        _ appointment: Appointment
    ) -> String {


        appointment.services
            .map {

                $0.serviceName

            }
            .joined(separator: " • ")
    }




    func dateText(_ appointment: Appointment) -> String {
        let calendar = Calendar.current
        let date = appointment.startDate

        if calendar.isDateInToday(date) {
            return localization.localizedString(for: "home.dateToday")
        }

        if calendar.isDateInTomorrow(date) {
            return localization.localizedString(for: "home.dateTomorrow")
        }

        return AppFormatting.date(date, locale: localization.locale)
    }

    func timeText(
        _ appointment: Appointment
    ) -> String {


        "\(AppFormatting.clock(appointment.startDate)) – \(AppFormatting.clock(appointment.endDate))"
    }

}
