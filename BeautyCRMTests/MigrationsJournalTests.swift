//
//  MigrationsJournalTests.swift
//  BeautyCRMTests
//
//  Кожен SQL-файл у supabase/migrations має рядок у «Журналі міграцій» (supabase/README.md) —
//  щоб не забути запустити його на сервері перед синхронізацією.
//

import XCTest

final class MigrationsJournalTests: XCTestCase {

    private var repo: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    func testEveryMigrationIsInJournal() throws {
        let folder = repo.appendingPathComponent("supabase/migrations")
        guard FileManager.default.fileExists(atPath: folder.path) else {
            throw XCTSkip("Тести запущено без вихідного коду поруч")
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path).filter { $0.hasSuffix(".sql") }
        let readme = try String(contentsOf: repo.appendingPathComponent("supabase/README.md"), encoding: .utf8)

        XCTAssertFalse(files.isEmpty)
        for file in files {
            XCTAssertTrue(readme.contains("| `\(file)` |"), "\(file) немає в «Журналі міграцій» supabase/README.md")
        }
    }
}
