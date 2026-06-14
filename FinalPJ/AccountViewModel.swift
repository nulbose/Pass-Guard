import Foundation
import SwiftData
import Observation

@Observable
final class AccountViewModel {
    var serviceName = ""
    var accountUsername = ""
    var accountPassword = ""
    var errorMessage = ""
    var showAddSheet = false

    func addAccount(context: ModelContext) {
        guard !serviceName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "서비스 이름을 입력해주세요."; return
        }
        guard !accountUsername.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "계정 이름을 입력해주세요."; return
        }
        guard !accountPassword.isEmpty else {
            errorMessage = "비밀번호를 입력해주세요."; return
        }

        let ref = "passguard_pwd_\(UUID().uuidString)"
        let hash = KeychainManager.sha256(accountPassword)
        let analysis = PasswordAnalyzer.analyze(accountPassword)

        KeychainManager.save(key: ref, value: accountPassword)

        let account = Account(
            serviceName: serviceName,
            username: accountUsername,
            passwordHash: hash,
            keychainRef: ref,
            strengthScore: analysis.strengthScore,
            patternPenalty: analysis.patternPenalty
        )
        context.insert(account)
        refreshReuse(context: context)
        clearFields()
    }

    func updatePassword(_ account: Account, newPassword: String, context: ModelContext) {
        let hash = KeychainManager.sha256(newPassword)
        let analysis = PasswordAnalyzer.analyze(newPassword)
        KeychainManager.save(key: account.keychainRef, value: newPassword)
        account.passwordHash = hash
        account.strengthScore = analysis.strengthScore
        account.patternPenalty = analysis.patternPenalty
        account.lastChangedAt = Date()
        refreshReuse(context: context)
    }

    func deleteAccount(_ account: Account, context: ModelContext) {
        KeychainManager.delete(key: account.keychainRef)
        context.delete(account)
        refreshReuse(context: context)
    }

    func refreshReuse(context: ModelContext) {
        guard let all = try? context.fetch(FetchDescriptor<Account>()) else { return }
        let reused = PasswordAnalyzer.findReusedIDs(all)
        for a in all { a.isReused = reused.contains(a.id) }
    }

    func getPassword(for account: Account) -> String? {
        KeychainManager.load(key: account.keychainRef)
    }

    func clearFields() {
        serviceName = ""
        accountUsername = ""
        accountPassword = ""
        errorMessage = ""
        showAddSheet = false
    }
}
