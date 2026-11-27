//
//  AnalyticsSections.swift
//  BeautyCRM
//
//  Картки екрана «Аналітика»:
//  - «Дохід за послугами» — кругова діаграма у відтінках фірмового кольору з легендою; тап по сегменту
//    або рядку підсвічує послугу, і в центрі видно її частку й суму;
//  - «Клієнти» — уся база, не залежить від вибраного періоду.
//

import SwiftUI
import Charts


// MARK: - SERVICE DONUT

struct ServiceDonutCard: View {

    let slices: [AnalyticsServiceSlice]
    // Підпис над карткою: «Листопад», «2026»…
    let periodTitle: String

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager

    @State private var selectedID: String?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var total: Decimal {
        slices.reduce(Decimal(0)) { $0 + $1.revenue }
    }

    private var selected: AnalyticsServiceSlice? {
        slices.first { $0.id == selectedID }
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.localizedString(for: "analytics.byService"))
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
                Text(periodTitle)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }

            ZStack {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("revenue", slice.revenue.doubleValue),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(color(for: slice))
                    .opacity(selectedID == nil || selectedID == slice.id ? 1 : 0.3)
                }
                .chartLegend(.hidden)
                // Свій тап замість chartAngleSelection: той не спрацьовує всередині прокрутки
                .chartOverlay { _ in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                select(at: location, in: geometry.size)
                            }
                    }
                }
                .frame(height: 210)

                centerLabel
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                ForEach(slices) { slice in
                    legendRow(slice)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.card)
        .cornerRadius(18)
        .accessibilityIdentifier("analytics.byService")
    }


    // Без вибору — уся сума; з вибором — назва, частка й сума послуги
    private var centerLabel: some View {
        VStack(spacing: 2) {
            if let selected {
                Text(name(selected))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: 120)
                Text(percent(selected.share))
                    .font(.title2.bold())
                    .foregroundColor(colors.textPrimary)
                Text(currency.format(selected.revenue))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            } else {
                Text(localization.localizedString(for: "analytics.byService.total"))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                Text(currency.format(total))
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 120)
            }
        }
    }


    private func legendRow(_ slice: AnalyticsServiceSlice) -> some View {

        let dimmed = selectedID != nil && selectedID != slice.id

        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedID = selectedID == slice.id ? nil : slice.id
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(color(for: slice))
                    .frame(width: 10, height: 10)
                Text(name(slice))
                    .font(.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(percent(slice.share))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.textPrimary)
                    .monospacedDigit()
                Text(currency.format(slice.revenue))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 70, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .opacity(dimmed ? 0.45 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }


    // Відтінки фірмового кольору від насиченого до блідого; «Інші» — нейтральний
    private func color(for slice: AnalyticsServiceSlice) -> Color {
        if slice.isOther {
            return colors.textSecondary.opacity(0.35)
        }
        let shades: [Double] = [1, 0.75, 0.55, 0.4, 0.3, 0.22]
        let index = slices.firstIndex { $0.id == slice.id } ?? 0
        return colors.accent.opacity(shades[min(index, shades.count - 1)])
    }

    private func name(_ slice: AnalyticsServiceSlice) -> String {
        slice.isOther ? localization.localizedString(for: "analytics.byService.other") : slice.name
    }

    private func percent(_ share: Double) -> String {
        share.formatted(.percent.precision(.fractionLength(1)).locale(localization.locale))
    }

    // Тап по кільцю — вибрати послугу, у центр чи поза кільце — зняти вибір
    private func select(at location: CGPoint, in size: CGSize) {
        let dx = location.x - size.width / 2
        let dy = location.y - size.height / 2
        let distance = (dx * dx + dy * dy).squareRoot()
        let outer = min(size.width, size.height) / 2
        let id: String?
        if distance < outer * 0.55 || distance > outer * 1.05 {
            id = nil
        } else {
            // Кут від верху за годинниковою стрілкою, 0…1 від повного кола
            var angle = atan2(dx, -dy)
            if angle < 0 { angle += 2 * .pi }
            let totalValue = total.doubleValue
            id = slice(at: angle / (2 * .pi) * totalValue)?.id
        }
        withAnimation(.easeOut(duration: 0.2)) {
            selectedID = id
        }
    }

    // Яку послугу зачепили пальцем: кут діаграми — це накопичена сума доходу
    private func slice(at value: Double) -> AnalyticsServiceSlice? {
        var running = 0.0
        for slice in slices {
            running += slice.revenue.doubleValue
            if value <= running {
                return slice
            }
        }
        return slices.last
    }
}


// MARK: - CLIENT BASE

struct ClientBaseCard: View {

    let base: AnalyticsClientBase

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private func localized(_ key: String) -> String {
        localization.localizedString(for: key)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 2) {
                Text(localized("analytics.clientBase"))
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
                Text(localized("analytics.clientBase.hint"))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                tile(value: "\(base.total)", title: localized("analytics.clientBase.total"), detail: nil)

                tile(
                    value: base.newThisMonth > 0 ? "+\(base.newThisMonth)" : "0",
                    title: localized("analytics.clientBase.newThisMonth"),
                    detail: nil
                )

                tile(
                    value: base.returningPercent.formatted(.percent.locale(localization.locale)),
                    title: localized("analytics.clientBase.returning"),
                    detail: String(format: localized("analytics.clientBase.returningDetail"), base.returning, base.visited)
                )

                tile(
                    value: "\(base.dormant)",
                    title: localized("analytics.clientBase.dormant"),
                    detail: localized("analytics.clientBase.dormantDetail")
                )
            }

            if !base.loyal.isEmpty {

                Divider().overlay(colors.divider)

                VStack(alignment: .leading, spacing: 8) {
                    Text(localized("analytics.loyalClients"))
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)

                    ForEach(base.loyal) { client in
                        HStack(alignment: .firstTextBaseline) {
                            Text(client.name)
                                .font(.headline)
                                .foregroundColor(colors.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(CountFormatting.visits(client.visits, locale: localization.locale))
                                .font(.subheadline)
                                .foregroundColor(colors.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.card)
        .cornerRadius(18)
        .accessibilityIdentifier("analytics.clientBase")
    }

    private func tile(value: String, title: String, detail: String?) -> some View {

        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(colors.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(colors.cardSecondary)
        .cornerRadius(14)
    }
}
