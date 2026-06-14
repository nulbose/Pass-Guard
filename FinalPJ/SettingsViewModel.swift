import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI
import Observation

@Observable
final class SettingsViewModel {
    var reminderOn: Bool {
        didSet { UserDefaults.standard.set(reminderOn, forKey: "reminderOn") }
    }
    var intervalDays: Int {
        didSet { UserDefaults.standard.set(intervalDays, forKey: "intervalDays") }
    }
    var showDeleteAlert = false

    init() {
        self.reminderOn = UserDefaults.standard.bool(forKey: "reminderOn")
        let saved = UserDefaults.standard.integer(forKey: "intervalDays")
        self.intervalDays = saved > 0 ? saved : 90
    }

    func exportJSON(context: ModelContext) -> Data? {
        guard let accounts = try? context.fetch(FetchDescriptor<Account>()) else { return nil }
        let formatter = ISO8601DateFormatter()
        var items: [[String: Any]] = []
        for a in accounts {
            var d: [String: Any] = [
                "serviceName": a.serviceName,
                "username": a.username,
                "passwordHash": a.passwordHash,
                "createdAt": formatter.string(from: a.createdAt),
                "lastChangedAt": formatter.string(from: a.lastChangedAt)
            ]
            if let pwd = KeychainManager.load(key: a.keychainRef) {
                d["password"] = pwd
            }
            items.append(d)
        }
        return try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted)
    }

    func importJSON(_ data: Data, context: ModelContext) -> Int {
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return 0 }
        let fmt = ISO8601DateFormatter()
        var count = 0
        for d in arr {
            guard let svc = d["serviceName"] as? String,
                  let usr = d["username"] as? String,
                  let pwd = d["password"] as? String else { continue }
            let ref = "passguard_pwd_\(UUID().uuidString)"
            let analysis = PasswordAnalyzer.analyze(pwd)
            KeychainManager.save(key: ref, value: pwd)
            let account = Account(
                serviceName: svc, username: usr,
                passwordHash: KeychainManager.sha256(pwd), keychainRef: ref,
                strengthScore: analysis.strengthScore, patternPenalty: analysis.patternPenalty
            )
            if let c = (d["createdAt"] as? String).flatMap({ fmt.date(from: $0) }) { account.createdAt = c }
            if let l = (d["lastChangedAt"] as? String).flatMap({ fmt.date(from: $0) }) { account.lastChangedAt = l }
            context.insert(account)
            count += 1
        }
        if let all = try? context.fetch(FetchDescriptor<Account>()) {
            let reused = PasswordAnalyzer.findReusedIDs(all)
            for a in all { a.isReused = reused.contains(a.id) }
        }
        return count
    }

    func deleteAll(context: ModelContext) {
        guard let accounts = try? context.fetch(FetchDescriptor<Account>()) else { return }
        for a in accounts {
            KeychainManager.delete(key: a.keychainRef)
            context.delete(a)
        }
    }
}

struct JSONDoc: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
