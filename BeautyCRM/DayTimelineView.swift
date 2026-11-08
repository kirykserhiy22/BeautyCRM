//
//  DayTimelineView.swift
//  BeautyCRM
//
//  Шкала дня по годинах: на Головній і в Календарі.
//

import SwiftUI


struct DayTimelineView: View {

    let day: Date
    // Активні й завершені записи цього дня
    let appointments: [Appointment]
    let workingHours: DayTimeScale
    let onSelect: (Appointment) -> Void

    @EnvironmentObject var theme: ThemeManager

    private let hourHeight: CGFloat = 60
    private let labelWidth: CGFloat = 48
    private let topInset: CGFloat = 8

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var items: [TimelineItem] {
        appointments.map {
            DayTimelineLayout.item(id: $0.id, start: $0.startDate, durationMinutes: $0.duration)
        }
    }

    var body: some View {

        let items = items
        let hours = DayTimelineLayout.hourRange(
            items: items,
            workStartMinute: workingHours.startMinute,
            workEndMinute: workingHours.endMinute
        )
        let placements = DayTimelineLayout.placements(for: items)

        GeometryReader { geo in

            let laneWidth = max(geo.size.width - labelWidth, 0)

            ZStack(alignment: .topLeading) {

                ForEach(Array(hours), id: \.self) { hour in
                    hourLine(hour, lowerHour: hours.lowerBound, width: geo.size.width)
                }

                ForEach(appointments) { appointment in
                    if let item = items.first(where: { $0.id == appointment.id }),
                       let placement = placements[appointment.id] {
                        block(
                            appointment,
                            item: item,
                            placement: placement,
                            lowerHour: hours.lowerBound,
                            laneWidth: laneWidth
                        )
                    }
                }

                if Calendar.current.isDateInToday(day) {
                    // Раз на хвилину пересуває лінію «зараз»
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        nowLine(at: context.date, hours: hours, width: geo.size.width)
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .frame(height: CGFloat(hours.count - 1) * hourHeight + topInset * 2)
    }


    // MARK: - HOURS

    private func y(minute: Int, lowerHour: Int) -> CGFloat {
        CGFloat(minute - lowerHour * 60) / 60 * hourHeight + topInset
    }

    private func hourLine(_ hour: Int, lowerHour: Int, width: CGFloat) -> some View {

        let top = y(minute: hour * 60, lowerHour: lowerHour)

        return ZStack(alignment: .topLeading) {

            Rectangle()
                .fill(colors.divider)
                .frame(width: max(width - labelWidth, 0), height: 1)
                .offset(x: labelWidth, y: top)

            Text(String(format: "%02d:00", hour))
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(colors.textSecondary)
                .offset(y: top - 7)
        }
    }


    // MARK: - APPOINTMENT

    private func block(
        _ appointment: Appointment,
        item: TimelineItem,
        placement: TimelinePlacement,
        lowerHour: Int,
        laneWidth: CGFloat
    ) -> some View {

        let columnWidth = laneWidth / CGFloat(placement.columnCount)
        let minutes = max(item.endMinute - item.startMinute, DayTimelineLayout.minimumVisualMinutes)
        let height = CGFloat(minutes) / 60 * hourHeight - 2
        let isCompleted = appointment.status == .completed
        let services = appointment.services.map(\.serviceName).joined(separator: " · ")

        return Button {
            onSelect(appointment)
        } label: {
            HStack(spacing: 0) {

                Rectangle()
                    .fill(isCompleted ? colors.textMuted : colors.buttonPrimary)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 1) {

                    if height >= 44 {
                        Text(appointment.clientName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(isCompleted ? colors.textSecondary : colors.textPrimary)
                            .lineLimit(1)

                        Text(services)
                            .font(.caption)
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(1)
                    } else {
                        Text("\(appointment.clientName) · \(services)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(isCompleted ? colors.textSecondary : colors.textPrimary)
                            .lineLimit(1)
                    }

                    if height >= 66 {
                        Text("\(AppFormatting.clock(appointment.startDate)) – \(AppFormatting.clock(appointment.endDate))")
                            .font(.caption2)
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)

                Spacer(minLength: 0)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(colors.success)
                        .padding(.trailing, 8)
                }
            }
            .frame(width: max(columnWidth - 2, 0), height: height, alignment: .leading)
            .background(isCompleted ? colors.card : colors.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("timeline.appointment")
        .offset(
            x: labelWidth + CGFloat(placement.column) * columnWidth,
            y: y(minute: item.startMinute, lowerHour: lowerHour) + 1
        )
    }


    // MARK: - NOW

    @ViewBuilder
    private func nowLine(at date: Date, hours: ClosedRange<Int>, width: CGFloat) -> some View {

        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)

        if minute >= hours.lowerBound * 60 && minute <= hours.upperBound * 60 {

            let top = y(minute: minute, lowerHour: hours.lowerBound)

            ZStack(alignment: .topLeading) {

                Rectangle()
                    .fill(colors.accent)
                    .frame(width: max(width - labelWidth, 0), height: 1.5)
                    .offset(x: labelWidth, y: top)

                Circle()
                    .fill(colors.accent)
                    .frame(width: 8, height: 8)
                    .offset(x: labelWidth - 4, y: top - 3.25)
            }
        }
    }
}
