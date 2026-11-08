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
    let onMove: (Appointment, Date) -> Void
    // Запис тягнуть за межі робочого дня
    var onOutsideHours: () -> Void = {}
    var onDragActive: (Bool) -> Void = { _ in }

    @EnvironmentObject var theme: ThemeManager

    private struct Drag: Equatable {
        let id: UUID
        var startMinute: Int
        var isBeyondScale = false
    }

    private enum DragVerdict {
        case free, swap, blocked
    }

    // Під час перетягування шкала показує весь робочий день
    @State private var drag: Drag?

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
        let hours = hourRange(items, compact: drag == nil)
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
                        .zIndex(drag?.id == appointment.id ? 1 : 0)
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


    // MARK: - DRAG

    private func hourRange(_ items: [TimelineItem], compact: Bool) -> ClosedRange<Int> {
        DayTimelineLayout.hourRange(
            items: items,
            workStartMinute: workingHours.startMinute,
            workEndMinute: workingHours.endMinute,
            startsAtFirstItem: compact
        )
    }

    private func beginDrag(_ appointment: Appointment, item: TimelineItem) -> CGFloat {

        let items = items

        drag = Drag(id: appointment.id, startMinute: item.startMinute)
        onDragActive(true)

        let hours = hourRange(items, compact: true).lowerBound - hourRange(items, compact: false).lowerBound

        return CGFloat(hours) * hourHeight
    }

    private func updateDrag(item: TimelineItem, points: CGFloat) {

        guard let current = drag else {
            return
        }

        let hours = hourRange(items, compact: false)
        let duration = item.endMinute - item.startMinute

        drag?.isBeyondScale = DayTimelineLayout.isBeyondScale(
            original: item.startMinute,
            dragPoints: points,
            pointsPerHour: hourHeight,
            duration: duration,
            hours: hours
        )

        let minute = DayTimelineLayout.snappedStart(
            original: item.startMinute,
            dragPoints: points,
            pointsPerHour: hourHeight,
            duration: duration,
            hours: hours
        )

        if minute != current.startMinute {
            drag?.startMinute = minute
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    private func endDrag(_ appointment: Appointment, item: TimelineItem, cancelled: Bool) -> CGFloat {

        let fullLower = hourRange(items, compact: false).lowerBound

        if let current = drag, !cancelled {

            if current.isBeyondScale {
                onOutsideHours()
            } else if current.startMinute != item.startMinute,
                      let newStart = date(minute: current.startMinute, of: appointment) {
                onMove(appointment, newStart)
            }
        }

        drag = nil
        onDragActive(false)

        return CGFloat(hourRange(items, compact: true).lowerBound - fullLower) * hourHeight
    }

    private func date(minute: Int, of appointment: Appointment) -> Date? {
        let calendar = Calendar.current
        return calendar.date(byAdding: .minute, value: minute, to: calendar.startOfDay(for: appointment.startDate))
    }

    // Що станеться, якщо відпустити запис тут: колір блока підказує заздалегідь
    private func verdict(_ appointment: Appointment, current: Drag) -> DragVerdict {

        guard !current.isBeyondScale,
              let start = date(minute: current.startMinute, of: appointment),
              let end = Calendar.current.date(byAdding: .minute, value: appointment.duration, to: start),
              start >= Date()
        else {
            return .blocked
        }

        guard AppointmentEngine.hasConflict(
            newStart: start,
            newEnd: end,
            existing: appointments,
            ignoring: appointment.id
        ) else {
            return .free
        }

        return AppointmentEngine.swapPlan(
            appointment: appointment,
            droppedAt: start,
            existingAppointments: appointments
        ) == nil ? .blocked : .swap
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

        let dragMinute = drag?.id == appointment.id ? drag?.startMinute : nil
        let dragVerdict = drag.flatMap { $0.id == appointment.id ? verdict(appointment, current: $0) : nil }
        let dragTint: Color? = switch dragVerdict {
        case .blocked: colors.danger
        case .swap: colors.warning
        default: nil
        }

        return HStack(spacing: 0) {

            Rectangle()
                .fill(dragTint ?? (isCompleted ? colors.textMuted : colors.buttonPrimary))
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
        .background(dragTint?.opacity(0.25) ?? (isCompleted ? colors.card : colors.cardSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            if dragMinute != nil {
                Text(rangeText(startMinute: dragMinute ?? item.startMinute, minutes: item.endMinute - item.startMinute))
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(dragTint ?? colors.buttonPrimary))
                    .padding(3)
            }
        }
        .shadow(color: dragMinute == nil ? .clear : colors.shadow, radius: 8, y: 3)
        .overlay {
            TimelineDragGesture(
                canDrag: appointment.status == .active,
                onTap: { onSelect(appointment) },
                onBegan: { beginDrag(appointment, item: item) },
                onChanged: { updateDrag(item: item, points: $0) },
                onEnded: { endDrag(appointment, item: item, cancelled: $0) }
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onSelect(appointment) }
        .accessibilityIdentifier("timeline.appointment")
        .offset(
            x: labelWidth + CGFloat(placement.column) * columnWidth,
            y: y(minute: dragMinute ?? item.startMinute, lowerHour: lowerHour) + 1
        )
    }

    private func rangeText(startMinute: Int, minutes: Int) -> String {
        let end = startMinute + minutes
        return String(
            format: "%02d:%02d – %02d:%02d",
            startMinute / 60, startMinute % 60,
            end / 60, end % 60
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
