//
//  Reminders.swift
//  BeautyCRM
//
//  Нагадування майстру: «Через 1 годину — Олена» і «Завершіть запис».
//  Це локальні сповіщення iPhone: їх розклад ставить сам телефон, тож вони
//  приходять, навіть якщо додаток закритий і немає інтернету.
//
//  ReminderPlanner — чистий розрахунок (що й коли нагадати), його перевіряють тести.
//  ReminderScheduler — передає цей розклад iPhone.
//  ReminderSyncView — стежить за записами й налаштуваннями та оновлює розклад.
//

import SwiftUI
import SwiftData
import UserNotifications


// MARK: - SETTINGS

// За скільки до запису нагадати
nonisolated enum ReminderLead: String, CaseIterable, Identifiable {

    case min15
    case min30
    case hour1
    case hour2
    case eveningBefore

    var id: String { rawValue }

    // Підпис у Налаштуваннях: «за 1 годину»
    var titleKey: String { "reminders.lead.\(rawValue)" }

    // Заголовок сповіщення: «Через 1 годину — %@»
    var notificationTitleKey: String { "reminders.upcoming.\(rawValue)" }

    func fireDate(before start: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .min15: return start.addingTimeInterval(-15 * 60)
        case .min30: return start.addingTimeInterval(-30 * 60)
        case .hour1: return start.addingTimeInterval(-60 * 60)
        case .hour2: return start.addingTimeInterval(-2 * 60 * 60)
        case .eveningBefore:
            // Напередодні о 20:00
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: start)) ?? start
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dayBefore) ?? dayBefore
        }
    }
}

// Налаштування нагадувань — на цьому телефоні (UserDefaults)
nonisolated struct ReminderSettings: Equatable {

    static let beforeEnabledKey = "reminders.before.enabled"
    static let leadKey = "reminders.lead"
    static let finishEnabledKey = "reminders.finish.enabled"

    var beforeEnabled = true
    var lead: ReminderLead = .hour1
    var finishEnabled = true

    static func load(_ defaults: UserDefaults = .standard) -> ReminderSettings {
        ReminderSettings(
            beforeEnabled: defaults.object(forKey: beforeEnabledKey) as? Bool ?? true,
            lead: ReminderLead(rawValue: defaults.string(forKey: leadKey) ?? "") ?? .hour1,
            finishEnabled: defaults.object(forKey: finishEnabledKey) as? Bool ?? true
        )
    }
}


// MARK: - PLANNER

// Тільки те, що потрібно для розкладу (без SwiftData — легко перевіряти тестами)
nonisolated struct ReminderAppointment: Equatable {
    let id: UUID
    let start: Date
    let end: Date
    let isActive: Bool
}

nonisolated struct PlannedReminder: Equatable {

    enum Kind: String {
        case upcoming
        case finish
    }

    let kind: Kind
    let appointmentID: UUID
    let fireDate: Date

    var identifier: String {
        "\(ReminderPlanner.identifierPrefix)\(kind.rawValue).\(appointmentID.uuidString)"
    }
}

nonisolated enum ReminderPlanner {

    static let identifierPrefix = "reminder."

    // iPhone тримає щонайбільше 64 заплановані сповіщення від додатку — лишаємо запас
    static let maxPending = 60

    // «Завершіть запис» — через 5 хвилин після кінця, щоб не заважати майстру прибрати місце
    static let finishDelay: TimeInterval = 5 * 60

    static func plan(
        appointments: [ReminderAppointment],
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar = .current
    ) -> [PlannedReminder] {

        var result: [PlannedReminder] = []

        for appointment in appointments where appointment.isActive {

            if settings.beforeEnabled {
                let fire = settings.lead.fireDate(before: appointment.start, calendar: calendar)
                // Минулий час не ставимо: про запис, що вже от-от почнеться, майстер знає
                if fire > now {
                    result.append(PlannedReminder(kind: .upcoming, appointmentID: appointment.id, fireDate: fire))
                }
            }

            if settings.finishEnabled {
                let fire = appointment.end.addingTimeInterval(finishDelay)
                // Уже прострочені записи й так видно на Головній («Потрібно завершити»)
                if fire > now {
                    result.append(PlannedReminder(kind: .finish, appointmentID: appointment.id, fireDate: fire))
                }
            }
        }

        // Найближчі — найважливіші
        return Array(result.sorted { $0.fireDate < $1.fireDate }.prefix(maxPending))
    }
}


// MARK: - SCHEDULER

enum ReminderScheduler {

    private static var center: UNUserNotificationCenter { .current() }

    // Перебудувати розклад: прибрати старі нагадування й поставити нові.
    // Дозвіл питаємо, коли в майстра з'являється перший майбутній запис.
    static func reschedule(
        appointments: [Appointment],
        settings: ReminderSettings,
        localization: LocalizationManager,
        now: Date = Date()
    ) async {

        let byID = Dictionary(appointments.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        let plan = ReminderPlanner.plan(
            appointments: appointments.map {
                ReminderAppointment(id: $0.id, start: $0.startDate, end: $0.endDate, isActive: $0.status == .active)
            },
            settings: settings,
            now: now
        )

        // Текст збираємо одразу: далі йде очікування, а записи SwiftData краще не тримати
        let requests: [UNNotificationRequest] = plan.compactMap { reminder in
            guard let appointment = byID[reminder.appointmentID] else {
                return nil
            }
            return request(for: reminder, appointment: appointment, settings: settings, localization: localization)
        }

        var status = await center.notificationSettings().authorizationStatus

        if status == .notDetermined && !requests.isEmpty {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            status = await center.notificationSettings().authorizationStatus
        }

        await removePending()

        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    // Після виходу з акаунта чужі нагадування не мають приходити
    static func removeAll() {
        Task {
            await removePending()
        }
    }

    private static func removePending() async {
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(ReminderPlanner.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func request(
        for reminder: PlannedReminder,
        appointment: Appointment,
        settings: ReminderSettings,
        localization: LocalizationManager
    ) -> UNNotificationRequest {

        let content = UNMutableNotificationContent()
        let start = AppFormatting.clock(appointment.startDate)
        let services = appointment.services.map(\.serviceName).joined(separator: ", ")

        switch reminder.kind {

        case .upcoming:
            content.title = String(
                format: localization.localizedString(for: settings.lead.notificationTitleKey),
                appointment.clientName
            )
            content.body = services.isEmpty ? start : "\(start) · \(services)"

        case .finish:
            content.title = localization.localizedString(for: "reminders.finish.title")
            content.body = String(
                format: localization.localizedString(for: "reminders.finish.body"),
                appointment.clientName,
                "\(start)–\(AppFormatting.clock(appointment.endDate))"
            )
        }

        content.sound = .default
        content.userInfo = ["appointmentID": appointment.id.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.fireDate
        )

        return UNNotificationRequest(
            identifier: reminder.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }
}


// MARK: - TAP ON NOTIFICATION

// Тап по сповіщенню відкриває цей запис на Головній
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationRouter()

    // Тап міг прийти ще до того, як з'явився екран, — тоді запам'ятовуємо
    private var pendingAppointmentID: UUID?

    weak var appState: AppState? {
        didSet { deliverPending() }
    }

    private func open(_ id: UUID) {
        pendingAppointmentID = id
        deliverPending()
    }

    private func deliverPending() {
        guard let appState, let id = pendingAppointmentID else {
            return
        }
        pendingAppointmentID = nil
        appState.openAppointmentID = id
    }

    // Додаток відкритий — сповіщення все одно показуємо зверху
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let idString = response.notification.request.content.userInfo["appointmentID"] as? String
        guard let idString, let id = UUID(uuidString: idString) else {
            return
        }
        await MainActor.run {
            NotificationRouter.shared.open(id)
        }
    }
}


// MARK: - SYNC

// Невидимий помічник у головних вкладках: будь-яка зміна записів чи налаштувань
// (новий запис, перенесення, завершення, скасування) перебудовує розклад
struct ReminderSyncView: View {

    @Query private var appointments: [Appointment]

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(ReminderSettings.beforeEnabledKey) private var beforeEnabled = true
    @AppStorage(ReminderSettings.leadKey) private var leadRaw = ReminderLead.hour1.rawValue
    @AppStorage(ReminderSettings.finishEnabledKey) private var finishEnabled = true

    // Повернення в додаток — теж привід перевірити (дозвіл могли увімкнути в налаштуваннях iPhone)
    @State private var activations = 0

    private var userAppointments: [Appointment] {
        guard let userID = appState.session.userID else {
            return []
        }
        return appointments.filter { $0.userID == userID && $0.status == .active }
    }

    private var settings: ReminderSettings {
        ReminderSettings(
            beforeEnabled: beforeEnabled,
            lead: ReminderLead(rawValue: leadRaw) ?? .hour1,
            finishEnabled: finishEnabled
        )
    }

    // Змінилось будь-що з цього — розклад перебудовується
    private var signature: String {
        let items = userAppointments
            .map { "\($0.id.uuidString)|\($0.startDate.timeIntervalSince1970)|\($0.duration)|\($0.clientName)|\($0.services.count)" }
            .sorted()
            .joined(separator: ";")
        return "\(items)#\(beforeEnabled)\(leadRaw)\(finishEnabled)#\(localization.languageCode)#\(activations)"
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .task(id: signature) {
                // Кілька змін поспіль (перетягування запису) — перебудовуємо один раз
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else {
                    return
                }
                await ReminderScheduler.reschedule(
                    appointments: userAppointments,
                    settings: settings,
                    localization: localization
                )
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    activations += 1
                }
            }
    }
}
