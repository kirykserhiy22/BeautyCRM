//
//  TimelineMoveModel.swift
//  BeautyCRM
//
//  Перенесення запису зі шкали і повідомлення «Перенесено на 16:00 · Скасувати».
//

import SwiftUI
import SwiftData
import Combine


struct TimelineNotice: Equatable {
    let id = UUID()
    let text: String
    let canUndo: Bool
}


final class TimelineMoveModel: ObservableObject {

    @Published private(set) var notice: TimelineNotice?
    // Запис кинули на інший: чекаємо відповіді майстра
    @Published private(set) var pendingSwap: AppointmentSwapPlan?

    private var previousStarts: [(appointment: Appointment, start: Date)] = []
    private var hideTask: Task<Void, Never>?

    func move(
        _ appointment: Appointment,
        to newStart: Date,
        existing: [Appointment],
        context: ModelContext,
        localization: LocalizationManager
    ) {

        let previousStart = appointment.startDate

        let result = AppointmentEngine.reschedule(
            appointment: appointment,
            to: newStart,
            existingAppointments: existing
        )

        switch result {

        case .success:
            guard context.saveReportingErrors() else {
                appointment.startDate = previousStart
                return
            }

            previousStarts = [(appointment, previousStart)]

            show(
                String(
                    format: localization.localizedString(for: "timeline.moved"),
                    locale: localization.locale,
                    AppFormatting.clock(newStart)
                ),
                canUndo: true
            )

        case .failure(.timeConflict):
            if let plan = AppointmentEngine.swapPlan(
                appointment: appointment,
                droppedAt: newStart,
                existingAppointments: existing
            ) {
                pendingSwap = plan
            } else {
                show(localization.localizedString(for: "appointment.timeOccupied"), canUndo: false)
            }

        case .failure(let error):
            show(localization.localizedString(for: error.localizationKey), canUndo: false)
        }
    }

    func showOutsideHours(localization: LocalizationManager) {
        show(localization.localizedString(for: "timeline.outsideHours"), canUndo: false)
    }

    func cancelSwap() {
        pendingSwap = nil
    }

    func confirmSwap(
        existing: [Appointment],
        context: ModelContext,
        localization: LocalizationManager
    ) {

        guard let plan = pendingSwap else {
            return
        }

        pendingSwap = nil

        let previous = [
            (appointment: plan.moved, start: plan.moved.startDate),
            (appointment: plan.other, start: plan.other.startDate)
        ]

        guard AppointmentEngine.setStarts(
            [
                (appointment: plan.moved, start: plan.movedStart),
                (appointment: plan.other, start: plan.otherStart)
            ],
            existingAppointments: existing
        ) else {
            show(localization.localizedString(for: "appointment.timeOccupied"), canUndo: false)
            return
        }

        guard context.saveReportingErrors() else {
            previous.forEach { $0.appointment.startDate = $0.start }
            return
        }

        previousStarts = previous
        show(localization.localizedString(for: "timeline.swapped"), canUndo: true)
    }

    func undo(
        existing: [Appointment],
        context: ModelContext,
        localization: LocalizationManager
    ) {

        let previous = previousStarts
        previousStarts = []

        if AppointmentEngine.setStarts(previous, existingAppointments: existing) {
            context.saveReportingErrors()
            hide()
        } else {
            show(localization.localizedString(for: "appointment.timeOccupied"), canUndo: false)
        }
    }

    private func show(_ text: String, canUndo: Bool) {

        withAnimation(.snappy(duration: 0.25)) {
            notice = TimelineNotice(text: text, canUndo: canUndo)
        }

        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else {
                return
            }
            self?.hide()
        }
    }

    private func hide() {
        hideTask?.cancel()
        withAnimation(.snappy(duration: 0.25)) {
            notice = nil
        }
    }
}


private struct TimelineNoticeModifier: ViewModifier {

    @ObservedObject var model: TimelineMoveModel
    let existing: [Appointment]
    let bottomPadding: CGFloat

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.modelContext) private var context

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    func body(content: Content) -> some View {

        content
            .overlay(alignment: .bottom) {

                if let notice = model.notice {

                    HStack {

                        Text(notice.text)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(colors.textPrimary)

                        Spacer()

                        if notice.canUndo {
                            Button(localization.localizedString(for: "timeline.undo")) {
                                model.undo(existing: existing, context: context, localization: localization)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(colors.accent)
                            .accessibilityIdentifier("timeline.undo")
                        }
                    }
                    .padding(14)
                    .background(colors.cardSecondary)
                    .cornerRadius(14)
                    .shadow(color: colors.shadow, radius: 8, y: 3)
                    .padding(.horizontal)
                    .padding(.bottom, bottomPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert(
                localization.localizedString(for: "timeline.swap.title"),
                isPresented: Binding(
                    get: { model.pendingSwap != nil },
                    set: { if !$0 { model.cancelSwap() } }
                ),
                presenting: model.pendingSwap
            ) { _ in
                Button(localization.localizedString(for: "common.cancel"), role: .cancel) {}
                Button(localization.localizedString(for: "timeline.swap.confirm")) {
                    model.confirmSwap(existing: existing, context: context, localization: localization)
                }
            } message: { plan in
                Text("\(plan.moved.clientName) — \(AppFormatting.clock(plan.movedStart))\n\(plan.other.clientName) — \(AppFormatting.clock(plan.otherStart))")
            }
    }
}


extension View {

    func timelineNotice(
        _ model: TimelineMoveModel,
        existing: [Appointment],
        bottomPadding: CGFloat = 12
    ) -> some View {
        modifier(TimelineNoticeModifier(model: model, existing: existing, bottomPadding: bottomPadding))
    }
}
