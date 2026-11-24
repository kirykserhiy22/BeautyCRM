//
//  AccountDeletion.swift
//  BeautyCRM
//
//  «Видалити акаунт» (вимога App Store, крок S4).
//  Сервер: delete_my_account() стирає акаунт і робочий простір, де майстер єдиний власник.
//  Телефон: усі дані цього акаунта стираються остаточно — це єдине місце в додатку, де видалення
//  не «м'яке» (deletedAt), бо після видалення акаунта зберігати чужі персональні дані не можна.
//

import Foundation
import SwiftData
import Supabase

enum AccountDeletion {

    // Пошта поточного акаунта — майстер вводить її для підтвердження
    static func email(userID: String) -> String? {
        if AuthMode.usesServer {
            return SupabaseService.client?.auth.currentUser?.email
        }
        // Тестовий режим: старі паролі могли вже прибрати — тоді пошта є лише в табличці «email → акаунт»
        return LocalAuthService().email(for: userID)
            ?? LegacyAccounts.accounts().first { $0.value == userID }?.key
    }

    // nil — акаунт видалено; інакше помилка (наприклад, немає інтернету) і нічого не стерто
    static func deleteAccount(userID: String, context: ModelContext) async -> AuthError? {

        if AuthMode.usesServer {
            guard let client = SupabaseService.client else { return .serverError }
            do {
                try await client.rpc("delete_my_account").execute()
            } catch {
                return ServerAuth.map(error)
            }
            await ServerAuth.signOut()
        } else {
            LocalAuthService().deleteAccount(userID: userID)
        }

        wipeLocalData(userID: userID, context: context)
        return nil
    }

    // Усе, що належить акаунту на цьому телефоні: профіль, клієнти з фото (і файли), послуги,
    // записи, вихідні, позначки гіда й незавершеної реєстрації
    @discardableResult
    static func wipeLocalData(userID: String, context: ModelContext) -> Bool {

        let clients = (try? context.fetch(FetchDescriptor<Client>(predicate: #Predicate { $0.userID == userID }))) ?? []
        for client in clients {
            for photo in client.photos {
                ClientPhotoStorage.deleteImage(at: photo.fileName)
                context.delete(photo)
            }
            if let avatar = client.avatarPath {
                ClientPhotoStorage.deleteImage(at: avatar)
            }
            context.delete(client)
        }

        for appointment in (try? context.fetch(FetchDescriptor<Appointment>(predicate: #Predicate { $0.userID == userID }))) ?? [] {
            appointment.services.forEach { context.delete($0) }
            context.delete(appointment)
        }
        for service in (try? context.fetch(FetchDescriptor<Service>(predicate: #Predicate { $0.userID == userID }))) ?? [] {
            context.delete(service)
        }
        for dayOff in (try? context.fetch(FetchDescriptor<DayOff>(predicate: #Predicate { $0.userID == userID }))) ?? [] {
            context.delete(dayOff)
        }
        for profile in (try? context.fetch(FetchDescriptor<UserProfile>(predicate: #Predicate { $0.authUserID == userID }))) ?? [] {
            context.delete(profile)
        }

        OnboardingStore.markSeen(userID: userID)
        PendingSignUp.clear()
        ReminderScheduler.removeAll()

        return context.saveReportingErrors()
    }
}
