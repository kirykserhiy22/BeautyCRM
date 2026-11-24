//
//  ServerAuth.swift
//  BeautyCRM
//
//  Вхід і реєстрація через Supabase (крок S3a).
//  Пароль знає лише сервер; на телефоні — тільки сесія в Keychain (її зберігає бібліотека).
//
//  AuthMode — сервер чи старий локальний вхід (лише для автоматичних тестів і коли немає ключів).
//  ServerAuth — реєстрація з кодом з листа, вхід, вихід.
//  ServerAccount — робочий простір і профіль майстра на сервері.
//  PendingSignUp — дані реєстрації (ім'я, салон…), поки майстер не ввів код з листа.
//

import Foundation
import SwiftData
import Supabase


// MARK: - MODE

enum AuthMode {

    // Сервер, якщо є ключі. У Debug автоматичні тести й контент-симулятор вмикають локальний вхід:
    // аргументом запуску -localAuth або налаштуванням localAuth = YES (simctl … defaults write).
    static var usesServer: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-localAuth")
            || UserDefaults.standard.bool(forKey: "localAuth") {
            return false
        }
        #endif
        return SupabaseService.isConfigured
    }
}


// MARK: - AUTH

enum ServerAuth {

    enum SignUpOutcome {
        case codeSent
        case alreadyRegistered
    }

    private static var auth: AuthClient? {
        SupabaseService.client?.auth
    }

    // Реєстрація: сервер надсилає лист із кодом. Якщо email уже має акаунт,
    // сервер (з міркувань безпеки) не повертає помилку — лише користувача без «identities».
    static func signUp(email: String, password: String) async -> Result<SignUpOutcome, AuthError> {
        guard let auth else { return .failure(.serverError) }
        do {
            let response = try await auth.signUp(email: normalized(email), password: password)
            if response.user.identities?.isEmpty == true {
                return .success(.alreadyRegistered)
            }
            return .success(.codeSent)
        } catch {
            return .failure(map(error))
        }
    }

    // Код з листа після реєстрації → сесія. Повертає userID.
    static func verifySignUp(email: String, code: String) async -> Result<String, AuthError> {
        guard let auth else { return .failure(.serverError) }
        do {
            let response = try await auth.verifyOTP(email: normalized(email), token: code, type: .signup)
            return .success(response.user.id.uuidString)
        } catch {
            return .failure(map(error))
        }
    }

    static func resendSignUpCode(email: String) async -> AuthError? {
        guard let auth else { return .serverError }
        do {
            try await auth.resend(email: normalized(email), type: .signup)
            return nil
        } catch {
            return map(error)
        }
    }

    // Вхід email + пароль. Непідтверджена пошта → .emailNotConfirmed (екран коду).
    static func signIn(email: String, password: String) async -> Result<String, AuthError> {
        guard let auth else { return .failure(.serverError) }
        do {
            let session = try await auth.signIn(email: normalized(email), password: password)
            return .success(session.user.id.uuidString)
        } catch {
            return .failure(map(error))
        }
    }

    // «Забули пароль?»: лист із кодом. Для невідомого email сервер теж відповідає «надіслано» —
    // так чужі адреси не перевірити.
    static func sendPasswordReset(email: String) async -> AuthError? {
        guard let auth else { return .serverError }
        do {
            try await auth.resetPasswordForEmail(normalized(email))
            return nil
        } catch {
            return map(error)
        }
    }

    // Код з листа → сесія → новий пароль. Повертає userID.
    static func resetPassword(email: String, code: String, newPassword: String) async -> Result<String, AuthError> {
        guard let auth else { return .failure(.serverError) }
        do {
            let response = try await auth.verifyOTP(email: normalized(email), token: code, type: .recovery)
            _ = try await auth.update(user: UserAttributes(password: newPassword))
            return .success(response.user.id.uuidString)
        } catch {
            return .failure(map(error))
        }
    }

    // Без інтернету — лише локально: сесію з Keychain однаково прибираємо
    static func signOut() async {
        guard let auth else { return }
        do {
            try await auth.signOut(scope: .local)
        } catch {
            // Сесію на телефоні бібліотека вже видалила; нічого показувати не треба
        }
    }

    // Збережена сесія (може бути простроченою — бібліотека оновить її сама, коли буде інтернет)
    static var currentUserID: String? {
        auth?.currentSession?.user.id.uuidString
    }

    static func normalized(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Помилки бібліотеки → наші, з перекладом. Сирий текст сервера не показуємо.
    nonisolated static func map(_ error: Error) -> AuthError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost, .dataNotAllowed:
                return .noConnection
            default:
                return .serverError
            }
        }
        guard let authError = error as? Supabase.AuthError else {
            return .serverError
        }
        switch authError.errorCode {
        case .invalidCredentials:
            return .wrongPassword
        case .emailNotConfirmed:
            return .emailNotConfirmed
        case .otpExpired:
            return .invalidCode
        case .overEmailSendRateLimit, .overRequestRateLimit, .overSMSSendRateLimit:
            return .tooManyRequests
        case .userAlreadyExists, .emailExists:
            return .userAlreadyExists
        case .weakPassword:
            return .weakPassword
        case .samePassword:
            return .samePassword
        case .validationFailed:
            return .invalidEmail
        default:
            return .serverError
        }
    }
}


// MARK: - PENDING SIGN-UP

// Ім'я, салон, валюта, спеціалізація з кроків реєстрації — до підтвердження пошти.
// Якщо закрити додаток на екрані коду, після входу профіль усе одно створиться з цими даними.
nonisolated struct PendingSignUp: Codable, Equatable {

    var email: String
    var firstName: String
    var lastName: String
    var businessName: String?
    var currencyCode: String
    var languageCode: String
    var professionRaw: String?

    private static let key = "pending_signup"

    static func load(email: String, defaults: UserDefaults = .standard) -> PendingSignUp? {
        guard
            let data = defaults.data(forKey: key),
            let pending = try? JSONDecoder().decode(PendingSignUp.self, from: data),
            pending.email == email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return nil
        }
        return pending
    }

    func save(defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(self), forKey: Self.key)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}


// MARK: - ACCOUNT ON SERVER

enum ServerAccount {

    // Рядок таблиці profiles (snake_case — як у базі)
    nonisolated struct RemoteProfile: Codable {
        var user_id: UUID
        var id: UUID
        var workspace_id: UUID
        var first_name: String
        var last_name: String
        var business_name: String?
        var currency_code: String
        var language_code: String
        var profession: String?
        var work_start_minute: Int?
        var work_end_minute: Int?
        var reminder_address: String?
        var reminder_template: String?
        var reminder_signature: String?
        var updated_at: Date
    }

    nonisolated private struct WorkspaceParams: Encodable {
        let p_id: UUID
        let p_name: String?
    }

    // Локальний профіль для щойно підтвердженого акаунта:
    // 1) уже є на телефоні — нічого не робимо;
    // 2) є дані з кроків реєстрації — створюємо з них;
    // 3) профіль є на сервері (інший телефон) — копіюємо;
    // 4) інакше — порожній профіль, майстер заповнить у Налаштуваннях.
    static func ensureLocalProfile(
        userID: String,
        email: String,
        languageCode: String,
        context: ModelContext
    ) async -> UserProfile? {

        if let existing = UserProfileManager.profile(context: context, userID: userID) {
            return existing
        }

        let profile: UserProfile

        if let pending = PendingSignUp.load(email: email) {
            profile = UserProfile(
                authUserID: userID,
                firstName: pending.firstName,
                lastName: pending.lastName,
                businessName: pending.businessName,
                currencyCode: pending.currencyCode,
                languageCode: pending.languageCode
            )
            profile.professionRaw = pending.professionRaw
        } else if let remote = await fetchProfile(userID: userID) {
            profile = UserProfile(
                authUserID: userID,
                firstName: remote.first_name,
                lastName: remote.last_name,
                businessName: remote.business_name,
                currencyCode: remote.currency_code,
                languageCode: remote.language_code
            )
            profile.id = remote.id
            profile.workspaceID = remote.workspace_id
            profile.professionRaw = remote.profession
            profile.workStartMinute = remote.work_start_minute
            profile.workEndMinute = remote.work_end_minute
            profile.reminderAddress = remote.reminder_address
            profile.reminderTemplate = remote.reminder_template
            profile.reminderSignature = remote.reminder_signature
        } else {
            profile = UserProfile(
                authUserID: userID,
                firstName: "",
                lastName: "",
                currencyCode: "EUR",
                languageCode: languageCode
            )
        }

        context.insert(profile)
        guard context.saveReportingErrors() else {
            return nil
        }
        PendingSignUp.clear()
        return profile
    }

    // Робочий простір і профіль на сервері. Безпечно викликати багато разів (при кожному запуску):
    // якщо щось не вдалося без інтернету — спрацює наступного разу.
    static func push(profile: UserProfile) async {

        guard
            AuthMode.usesServer,
            let client = SupabaseService.client,
            let userID = client.auth.currentSession?.user.id,
            userID.uuidString == profile.authUserID,
            let workspaceID = profile.workspaceID
        else {
            return
        }

        let row = RemoteProfile(
            user_id: userID,
            id: profile.id,
            workspace_id: workspaceID,
            first_name: profile.firstName,
            last_name: profile.lastName,
            business_name: profile.businessName,
            currency_code: profile.currencyCode,
            language_code: profile.languageCode,
            profession: profile.professionRaw,
            work_start_minute: profile.workStartMinute,
            work_end_minute: profile.workEndMinute,
            reminder_address: profile.reminderAddress,
            reminder_template: profile.reminderTemplate,
            reminder_signature: profile.reminderSignature,
            updated_at: profile.updatedAt ?? profile.createdAt
        )

        do {
            try await client.rpc("create_workspace", params: WorkspaceParams(p_id: workspaceID, p_name: profile.businessName)).execute()
            try await client.from("profiles").upsert(row, onConflict: "user_id").execute()
        } catch {
            #if DEBUG
            print("Supabase: профіль не надіслано, спробуємо пізніше")
            #endif
        }
    }

    static func fetchProfile(userID: String) async -> RemoteProfile? {
        guard let client = SupabaseService.client else { return nil }
        do {
            let rows: [RemoteProfile] = try await client.from("profiles")
                .select()
                .eq("user_id", value: userID.lowercased())
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            return nil
        }
    }
}


// MARK: - ENTRY

// Спільне завершення входу й реєстрації: профіль на телефоні → сесія → Головна.
// Профіль на сервер відправляє MainTabView (при кожному відкритті, поки не вийде).
enum AccountEntry {

    static func enter(
        userID: String,
        email: String,
        context: ModelContext,
        appState: AppState,
        router: AppRouter,
        localization: LocalizationManager,
        currency: CurrencyManager,
        profession: ProfessionManager
    ) async -> AuthError? {

        // Дані старого локального акаунта з тим самим email переходять до цього акаунта
        let movedLegacyData = LegacyAccounts.migrate(email: email, to: userID, context: context)
        if movedLegacyData {
            PendingSignUp.clear()
        }

        let isNewAccount = PendingSignUp.load(email: email) != nil

        guard await ServerAccount.ensureLocalProfile(
            userID: userID,
            email: email,
            languageCode: localization.languageCode,
            context: context
        ) != nil else {
            return .serverError
        }

        appState.session.login(userID: userID)

        // Новий майстер один раз побачить короткий гід по додатку
        if isNewAccount {
            OnboardingStore.markPending(userID: userID)
        }

        UserProfileLoader.load(
            context: context,
            userID: userID,
            localization: localization,
            currency: currency,
            profession: profession
        )

        router.currentScreen = .main
        return nil
    }
}
