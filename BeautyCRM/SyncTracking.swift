//
//  SyncTracking.swift
//  BeautyCRM
//

import Foundation
import SwiftData


// Поля, потрібні для майбутньої синхронізації з сервером:
// чий запис, коли змінений, чи видалений
protocol SyncTrackable: AnyObject {

    var workspaceID: UUID? { get set }
    var updatedAt: Date? { get set }
    var deletedAt: Date? { get set }
}


extension SyncTrackable {

    // М'яке видалення: запис лишається в базі з позначкою часу,
    // щоб сервер потім дізнався про видалення. Екрани такі записи не показують.
    func markDeleted() {
        deletedAt = Date()
    }
}


enum SyncTracking {


    // Робочий простір користувача, який зараз увійшов
    static var currentWorkspaceID: UUID?


    private static var observer: NSObjectProtocol?



    // MARK: - AUTO STAMP


    // Перед кожним збереженням (і ручним, і автоматичним) проставляє
    // updatedAt і workspaceID новим та зміненим записам.
    // Так не треба пам'ятати про це в кожному екрані окремо.
    static func start() {

        guard observer == nil else {
            return
        }

        observer = NotificationCenter.default.addObserver(
            forName: ModelContext.willSave,
            object: nil,
            queue: nil
        ) { notification in

            guard let context = notification.object as? ModelContext else {
                return
            }

            stamp(
                context.insertedModelsArray +
                context.changedModelsArray
            )
        }
    }


    private static func stamp(
        _ models: [any PersistentModel]
    ) {

        let now = Date()

        for case let model as SyncTrackable in models {

            model.updatedAt = now

            if model.workspaceID == nil {
                model.workspaceID = currentWorkspaceID
            }
        }
    }



    // MARK: - WORKSPACE


    // Викликається, коли користувач потрапляє в додаток.
    // Гарантує, що в нього є робочий простір, і дописує його
    // старим записам, створеним до появи цього поля.
    static func prepareWorkspace(
        context: ModelContext,
        userID: String
    ) {

        guard let profile = UserProfileManager.profile(
            context: context,
            userID: userID
        ) else {
            return
        }


        let workspaceID = profile.workspaceID ?? UUID()

        profile.workspaceID = workspaceID
        currentWorkspaceID = workspaceID


        let clients = fetch(
            FetchDescriptor<Client>(
                predicate: #Predicate { $0.userID == userID }
            ),
            context: context
        )

        let photos = clients.flatMap { $0.photos }

        let services = fetch(
            FetchDescriptor<Service>(
                predicate: #Predicate { $0.userID == userID }
            ),
            context: context
        )

        let appointments = fetch(
            FetchDescriptor<Appointment>(
                predicate: #Predicate { $0.userID == userID }
            ),
            context: context
        )

        let daysOff = fetch(
            FetchDescriptor<DayOff>(
                predicate: #Predicate { $0.userID == userID }
            ),
            context: context
        )


        var records: [SyncTrackable] = []
        records += clients as [SyncTrackable]
        records += photos as [SyncTrackable]
        records += services as [SyncTrackable]
        records += appointments as [SyncTrackable]
        records += daysOff as [SyncTrackable]

        for record in records where record.workspaceID == nil {
            record.workspaceID = workspaceID
        }


        context.saveReportingErrors()
    }


    private static func fetch<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>,
        context: ModelContext
    ) -> [T] {

        (try? context.fetch(descriptor)) ?? []
    }
}
