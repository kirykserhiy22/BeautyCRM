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

                    HomeHeaderView()


                    TodayStatsCard(
                        totalAppointments: todayAppointments.count,
                        completedAppointments: completedToday,
                        remainingAppointments: remainingToday
                    )


                    if let dashboardAppointment {

                        DashboardAppointmentCard(
                            title: dashboardTitle,
                            clientName: dashboardAppointment.clientName,
                            services: servicesText(dashboardAppointment),
                            dateText: dateText(dashboardAppointment),
                            timeText: timeText(dashboardAppointment),
                            statusText: dashboardStatus,
                            accentColor: dashboardColor,
                            titleIsLocalized: true,
                            statusIsLocalized: true
                        )

                    } else if !todayAppointments.isEmpty && remainingToday == 0 {

                        // Сьогодні записи були, і всі вже завершені
                        DashboardAppointmentCard(
                            title: "home.dayComplete",
                            clientName: "home.allDoneToday",
                            services: "",
                            dateText: "",
                            timeText: "",
                            statusText: "home.noUpcomingAppointments",
                            accentColor: colors.success,
                            titleIsLocalized: true,
                            clientNameIsLocalized: true,
                            statusIsLocalized: true
                        )

                    } else {

                        DashboardAppointmentCard(
                            title: "home.noAppointments",
                            clientName: "home.freeToday",
                            services: "",
                            dateText: "",
                            timeText: "",
                            statusText: "home.noUpcomingAppointments",
                            accentColor: colors.textSecondary,
                            titleIsLocalized: true,
                            clientNameIsLocalized: true,
                            statusIsLocalized: true
                        )
                    }


                    QuickActionsSection()

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




    var dashboardStatus: String {

        guard let appointment = dashboardAppointment
        else {
            return ""
        }


        let now = Date()


        if appointment.endDate < now {

            return "home.waitingForCompletion"
        }


        if appointment.startDate <= now {

            return "home.inProgress"
        }


        return "home.upcoming"
    }





    var dashboardColor: Color {

        guard let appointment = dashboardAppointment
        else {
            return colors.textSecondary
        }


        let now = Date()


        if appointment.endDate < now {

            return .orange
        }


        if appointment.startDate <= now {

            return .green
        }


        return colors.accent
    }






    func servicesText(
        _ appointment: Appointment
    ) -> String {


        appointment.services
            .filter {

                !$0.isDeleted

            }
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

        let formatter = DateFormatter()
        formatter.locale = localization.locale
        formatter.dateStyle = .long
        formatter.timeStyle = .none

        return formatter.string(from: date)
    }

    func timeText(
        _ appointment: Appointment
    ) -> String {


        let formatter = DateFormatter()

        formatter.dateFormat = "HH:mm"


        return "\(formatter.string(from: appointment.startDate)) - \(formatter.string(from: appointment.endDate))"
    }

}
