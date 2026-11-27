//
//  MonthRhythmCard.swift
//  BeautyCRM
//
//  «Ритм місяця» внизу Головної: стовпчик на кожен день, як графік доходу в Аналітиці.
//  Повна висота — робочий день з профілю; заповнена частина — записи, бліда «тінь» над нею — вільний час.
//  Тап по стовпчику показує цей день; стрілки — інший місяць.
//

import SwiftUI
import Charts


struct MonthRhythmCard: View {

    let appointments: [Appointment]
    let dayOffKeys: Set<String>
    let workingHours: DayTimeScale

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var appState: AppState

    // 0 — поточний місяць, 1 — наступний…
    @State private var monthOffset = 0
    @State private var selectedDay: Date?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private func localized(_ key: String) -> String {
        localization.localizedString(for: key)
    }

    private var month: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private var days: [DayLoad] {
        HomeInsights.monthLoad(
            appointments: appointments,
            dayOffKeys: dayOffKeys,
            workingHours: workingHours,
            month: month
        )
    }

    var body: some View {

        let days = days
        let selected = days.first { $0.day == selectedDay }

        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text(localized("home.rhythm.title"))
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)

                Spacer()

                Button {
                    monthOffset -= 1
                } label: {
                    Image(systemName: "chevron.left").frame(width: 32, height: 32)
                }
                .disabled(monthOffset <= -1)
                .accessibilityLabel(localized("home.rhythm.previous"))

                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.textPrimary)
                    .frame(minWidth: 90)

                Button {
                    monthOffset += 1
                } label: {
                    Image(systemName: "chevron.right").frame(width: 32, height: 32)
                }
                .disabled(monthOffset >= 2)
                .accessibilityLabel(localized("home.rhythm.next"))
            }
            .tint(colors.accent)

            // Підпис: загальна заповненість або вибраний день з посиланням на нього в Календарі
            Group {
                if let selected {
                    Button {
                        appState.openCalendarDay = selected.day
                    } label: {
                        (
                            Text(dayText(selected) + "  ")
                                .foregroundColor(colors.textSecondary)
                            + Text(localized("home.rhythm.open") + " →")
                                .foregroundColor(colors.accent)
                                .fontWeight(.semibold)
                        )
                        .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.rhythm.open")
                } else {
                    Text(String(
                        format: localized("home.rhythm.busy"),
                        HomeInsights.percent(days).formatted(.percent.locale(localization.locale))
                    ))
                }
            }
            .font(.subheadline)
            .foregroundColor(colors.textSecondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)

            chart(days)

            HStack(spacing: 14) {
                legend(color: colors.accent, key: "home.rhythm.booked")
                legend(color: colors.accent.opacity(0.18), key: "home.rhythm.free")
                legend(color: dayOffColor, key: "home.rhythm.dayOffLegend", outlined: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(colors.card))
        .onChange(of: monthOffset) { selectedDay = nil }
        .accessibilityIdentifier("home.rhythm")
    }


    private func chart(_ days: [DayLoad]) -> some View {

        Chart(Array(days.enumerated()), id: \.element.day) { index, day in

            let dimmed = selectedDay != nil && selectedDay != day.day
            let hours = Double(day.workingMinutes) / 60
            let booked = Double(min(day.bookedMinutes, day.workingMinutes)) / 60

            if day.isDayOff {
                // Вихідний — прозорий стовпчик; контур малює chartBackground нижче
                BarMark(
                    x: .value("day", String(index)),
                    yStart: .value("start", 0),
                    yEnd: .value("end", maxHours(days)),
                    width: .ratio(0.7)
                )
                .foregroundStyle(Color.clear)
            } else {
                // «Тінь» — увесь робочий день
                BarMark(
                    x: .value("day", String(index)),
                    yStart: .value("start", 0),
                    yEnd: .value("end", hours),
                    width: .ratio(0.7)
                )
                .foregroundStyle(colors.accent.opacity(dimmed ? 0.08 : 0.18))
                .cornerRadius(3)

                // Зайнято записами
                if booked > 0 {
                    BarMark(
                        x: .value("day", String(index)),
                        yStart: .value("start", 0),
                        yEnd: .value("end", booked),
                        width: .ratio(0.7)
                    )
                    .foregroundStyle(colors.accent.opacity(dimmed ? 0.3 : 1))
                    .cornerRadius(3)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: [1, 5, 10, 15, 20, 25, 30].filter { $0 <= days.count }.map { String($0 - 1) }) { value in
                AxisValueLabel {
                    if let key = value.as(String.self), let index = Int(key), days.indices.contains(index) {
                        Text(dayNumber(days[index].day))
                            .font(.caption2)
                            .foregroundColor(isToday(days[index].day) ? colors.accent : colors.textSecondary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...max(maxHours(days), 1))
        // Вихідні — лише світлий контур, щоб не зливались з «тінню» вільного часу
        .chartBackground { proxy in
            GeometryReader { geometry in
                if let plotFrame = proxy.plotFrame {
                    let frame = geometry[plotFrame]
                    let width = frame.width / CGFloat(max(days.count, 1)) * 0.7
                    ForEach(days.indices.filter { days[$0].isDayOff }, id: \.self) { index in
                        if let x = proxy.position(forX: String(index)) {
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(dayOffColor, lineWidth: 0.6)
                                .frame(width: width, height: frame.height)
                                .position(x: frame.minX + x, y: frame.midY)
                                .opacity(selectedDay != nil && selectedDay != days[index].day ? 0.35 : 1)
                        }
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ChartScrubGesture(
                    onTap: { select(at: $0, proxy: proxy, geometry: geometry, days: days) },
                    onScrub: { scrub(at: $0, proxy: proxy, geometry: geometry, days: days) }
                )
            }
        }
        .frame(height: 110)
    }


    private func select(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy, days: [DayLoad]) {
        guard let plotFrame = proxy.plotFrame else { return }
        let x = location.x - geometry[plotFrame].origin.x
        guard let key: String = proxy.value(atX: x), let index = Int(key), days.indices.contains(index) else {
            selectedDay = nil
            return
        }
        let day = days[index].day
        withAnimation(.easeOut(duration: 0.15)) {
            selectedDay = selectedDay == day ? nil : day
        }
    }

    // Провели пальцем — вибрати день під ним (без зняття вибору)
    private func scrub(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy, days: [DayLoad]) -> String? {
        guard let plotFrame = proxy.plotFrame else { return nil }
        let frame = geometry[plotFrame]
        let x = min(max(location.x - frame.origin.x, 0), frame.width - 1)
        guard let key: String = proxy.value(atX: x), let index = Int(key), days.indices.contains(index) else {
            return nil
        }
        selectedDay = days[index].day
        return key
    }

    private func legend(color: Color, key: String, outlined: Bool = false) -> some View {
        HStack(spacing: 5) {
            if outlined {
                RoundedRectangle(cornerRadius: 2).strokeBorder(color, lineWidth: 0.8).frame(width: 10, height: 10)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            }
            Text(localized(key)).font(.caption).foregroundColor(colors.textSecondary)
        }
    }

    // Тонкий приглушений контур: помітний, але не вибивається з теми (і в світлому стилі)
    private var dayOffColor: Color {
        colors.textSecondary.opacity(0.5)
    }

    private func maxHours(_ days: [DayLoad]) -> Double {
        Double(days.map(\.workingMinutes).max() ?? 0) / 60
    }

    // «Пт, 28 листопада · вихідний» або «… · зайнято 4 год з 10 · 3 записи»
    private func dayText(_ day: DayLoad) -> String {
        let date = AppFormatting.template("EEEdMMMM", day.day, locale: localization.locale)
        if day.isDayOff {
            return "\(date) · \(localized("home.rhythm.dayOff"))"
        }
        let booked = DurationText.text(day.bookedMinutes, locale: localization.locale, localized: localized)
        let total = DurationText.text(day.workingMinutes, locale: localization.locale, localized: localized)
        return "\(date) · " + String(format: localized("home.rhythm.dayBooked"), booked, total)
            + " · " + CountFormatting.appointments(day.appointmentCount, locale: localization.locale)
                .replacingOccurrences(of: " ", with: "\u{00A0}")
    }

    private var monthTitle: String {
        let text = AppFormatting.template("LLLL", month, locale: localization.locale)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func dayNumber(_ date: Date) -> String {
        AppFormatting.pattern("d", date, locale: localization.locale)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
