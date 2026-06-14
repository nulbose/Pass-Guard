import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var serviceName: String = ""
    var username: String = ""
    var passwordHash: String = ""
    var keychainRef: String = ""
    var strengthScore: Int = 0
    var patternPenalty: Int = 0
    var isReused: Bool = false
    var createdAt: Date = Date()
    var lastChangedAt: Date = Date()

    init(
        serviceName: String,
        username: String,
        passwordHash: String,
        keychainRef: String,
        strengthScore: Int = 0,
        patternPenalty: Int = 0,
        isReused: Bool = false
    ) {
        self.id = UUID()
        self.serviceName = serviceName
        self.username = username
        self.passwordHash = passwordHash
        self.keychainRef = keychainRef
        self.strengthScore = strengthScore
        self.patternPenalty = patternPenalty
        self.isReused = isReused
        self.createdAt = Date()
        self.lastChangedAt = Date()
    }

    var daysSinceChange: Int {
        Calendar.current.dateComponents([.day], from: lastChangedAt, to: Date()).day ?? 0
    }

    // Score breakdown:
    // 강도: 0~60 (엔트로피 기반)
    // 변경주기: 0~15
    // 패턴 감점: 최대 -20
    // 재사용 감점: -15
    // 총합 = 강도 + 변경주기 - 패턴 - 재사용 → 0~100 클램프

    var ageScore: Int {
        if daysSinceChange <= 90 { return 15 }
        if daysSinceChange <= 180 { return 8 }
        return 0
    }

    var totalScore: Int {
        let base = strengthScore + ageScore - patternPenalty - (isReused ? 15 : 0)
        return max(0, min(100, base))
    }
}
