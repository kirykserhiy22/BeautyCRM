import SwiftUI


// Шкала смужки зайнятості.
// Основна частина смужки — завжди робочі години майстра, тож запис на початок
// робочого дня завжди стоїть на початку смужки. Час до і після робочих годин
// показується у вузьких зонах по краях (лише в місяцях, де є такі записи).
struct DayTimeScale: Equatable {

    // Робочі години, хвилини від 00:00
    var startMinute: Int
    var endMinute: Int

    var showsEarlyZone = false
    var showsLateZone = false

    // Частка ширини смужки на кожну крайню зону
    static let edgeZoneShare: CGFloat = 0.12


    static let defaultWorkingHours = DayTimeScale(
        startMinute: 9 * 60,
        endMinute: 19 * 60
    )


    // Робочі години майстра з профілю (або за замовчуванням)
    static func workingHours(
        _ profile: UserProfile?
    ) -> DayTimeScale {

        guard
            let start = profile?.workStartMinute,
            let end = profile?.workEndMinute,
            end > start
        else {
            return defaultWorkingHours
        }

        return DayTimeScale(startMinute: start, endMinute: end)
    }


    // Шкала для місяця: робочі години + крайні зони, якщо в цьому місяці
    // є записи раніше або пізніше. Однакова для всіх днів місяця.
    static func forMonth(
        _ month: Date,
        appointments: [Appointment],
        workingHours: DayTimeScale
    ) -> DayTimeScale {

        let calendar = Calendar.current

        var scale = workingHours

        for appointment in appointments where
            appointment.status != .cancelled &&
            appointment.status != .archived &&
            calendar.isDate(
                appointment.startDate,
                equalTo: month,
                toGranularity: .month
            )
        {
            let appointmentStart = minuteOfDay(appointment.startDate)
            let appointmentEnd = min(
                appointmentStart + appointment.duration,
                24 * 60
            )

            if appointmentStart < scale.startMinute {
                scale.showsEarlyZone = true
            }

            if appointmentEnd > scale.endMinute {
                scale.showsLateZone = true
            }
        }

        return scale
    }


    // Де на смужці (0…1) стоїть хвилина доби
    func progress(atMinute minute: Int) -> CGFloat {

        let early = showsEarlyZone ? Self.edgeZoneShare : 0
        let late = showsLateZone ? Self.edgeZoneShare : 0
        let main = 1 - early - late

        if minute < startMinute {

            guard showsEarlyZone, startMinute > 0 else {
                return early
            }

            return early * CGFloat(minute) / CGFloat(startMinute)
        }

        if minute > endMinute {

            guard showsLateZone, endMinute < 24 * 60 else {
                return early + main
            }

            return early + main + late *
                CGFloat(minute - endMinute) / CGFloat(24 * 60 - endMinute)
        }

        return early + main *
            CGFloat(minute - startMinute) / CGFloat(max(endMinute - startMinute, 1))
    }


    static func minuteOfDay(_ date: Date) -> Int {

        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: date
        )

        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}



struct DayOccupancyBar: View {

    let appointments: [Appointment]

    let day: Date

    let scale: DayTimeScale

    @EnvironmentObject var theme: ThemeManager

    // Проміжок між сусідніми записами, щоб вони не «злипались»
    private let gap: CGFloat = 1.5

    private let minimumSegmentWidth: CGFloat = 3

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        GeometryReader { geo in

            ZStack(alignment: .leading) {

                track(totalWidth: geo.size.width)

                ForEach(activeAppointments) { appt in

                    let frame = segmentFrame(
                        for: appt,
                        totalWidth: geo.size.width
                    )

                    Capsule()
                        .fill(color(for: appt))
                        .frame(width: frame.width, height: 8)
                        .offset(x: frame.x)
                }
            }
            .frame(height: geo.size.height)
        }
        .frame(height: 12)
    }
}


private extension DayOccupancyBar {

    var activeAppointments: [Appointment] {

        appointments.filter {

            $0.status != .cancelled &&
            $0.status != .archived &&

            Calendar.current.isDate(
                $0.startDate,
                inSameDayAs: day
            )
        }
    }


    func color(for appt: Appointment) -> Color {

        appt.status == .completed
            ? colors.success
            : colors.accent
    }


    // Фон смужки: робочі години темніші, крайні зони світліші
    func track(totalWidth: CGFloat) -> some View {

        let early = scale.progress(atMinute: scale.startMinute) * totalWidth
        let main = scale.progress(atMinute: scale.endMinute) * totalWidth - early

        return ZStack(alignment: .leading) {

            Rectangle()
                .fill(colors.cardSecondary.opacity(0.45))

            Rectangle()
                .fill(colors.cardSecondary)
                .frame(width: main)
                .offset(x: early)
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }


    // Позиція і ширина запису на смужці відповідно до шкали місяця
    func segmentFrame(
        for appt: Appointment,
        totalWidth: CGFloat
    ) -> (x: CGFloat, width: CGFloat) {

        let start = DayTimeScale.minuteOfDay(appt.startDate)
        let end = min(start + appt.duration, 24 * 60)

        let x = scale.progress(atMinute: start) * totalWidth
        let endX = scale.progress(atMinute: end) * totalWidth

        let width = max(
            minimumSegmentWidth,
            endX - x - gap
        )

        return (min(x, totalWidth - width), width)
    }
}
