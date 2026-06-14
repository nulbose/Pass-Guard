import Foundation
import UIKit
import Observation

@Observable
final class PasswordGeneratorViewModel {
    var length: Double = 12
    var useLowercase = true
    var useUppercase = true
    var useNumbers = true
    var useSpecial = true
    var excludeAmbiguous = true  // l, I, 1, O, 0 등 혼동 문자 제외

    /// 최소 1개 종류는 켜져 있어야 함
    var canToggleOff: Bool {
        [useLowercase, useUppercase, useNumbers, useSpecial].filter { $0 }.count > 1
    }
    var generated = ""
    var copied = false

    var analysis: PasswordAnalysis {
        PasswordAnalyzer.analyze(generated)
    }

    var score: Int {
        let a = analysis
        return max(0, min(100, a.strengthScore - a.patternPenalty + 15))
    }

    // Preset options
    enum Preset: String, CaseIterable {
        case pin = "숫자 PIN"
        case standard = "일반"
        case strong = "최강"

        var icon: String {
            switch self {
            case .pin: return "number.square"
            case .standard: return "lock"
            case .strong: return "lock.shield"
            }
        }
    }

    func applyPreset(_ preset: Preset) {
        switch preset {
        case .pin:
            length = 6
            useLowercase = false
            useUppercase = false
            useNumbers = true
            useSpecial = false
            excludeAmbiguous = false
        case .standard:
            length = 12
            useLowercase = true
            useUppercase = true
            useNumbers = true
            useSpecial = false
            excludeAmbiguous = true
        case .strong:
            length = 20
            useLowercase = true
            useUppercase = true
            useNumbers = true
            useSpecial = true
            excludeAmbiguous = true
        }
        generate()
    }

    func generate() {
        let ambiguousChars: Set<Character> = ["l", "I", "1", "O", "0", "|"]

        var lower = "abcdefghijklmnopqrstuvwxyz"
        var upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var digits = "0123456789"
        var specials = "!@#$%^&*()-_=+[]{}:,.<>?"

        if excludeAmbiguous {
            lower = String(lower.filter { !ambiguousChars.contains($0) })
            upper = String(upper.filter { !ambiguousChars.contains($0) })
            digits = String(digits.filter { !ambiguousChars.contains($0) })
            specials = String(specials.filter { !ambiguousChars.contains($0) })
        }

        var pool = ""
        if useLowercase { pool += lower }
        if useUppercase { pool += upper }
        if useNumbers { pool += digits }
        if useSpecial { pool += specials }

        let len = Int(length)
        guard len >= 4, !pool.isEmpty else {
            generated = String((0..<len).map { _ in pool.isEmpty ? "a" : pool.randomElement()! })
            copied = false
            return
        }

        // Try up to 50 times to generate a perfectly clean password
        var best = ""
        var bestScore = -1

        for _ in 0..<50 {
            var chars: [Character] = (0..<len).map { _ in pool.randomElement()! }

            // Guarantee at least one from each enabled category at random positions
            var slots = Array(0..<len)
            slots.shuffle()
            var slotIdx = 0

            if useLowercase && slotIdx < len { chars[slots[slotIdx]] = lower.randomElement()!; slotIdx += 1 }
            if useUppercase && slotIdx < len { chars[slots[slotIdx]] = upper.randomElement()!; slotIdx += 1 }
            if useNumbers && slotIdx < len { chars[slots[slotIdx]] = digits.randomElement()!; slotIdx += 1 }
            if useSpecial && slotIdx < len { chars[slots[slotIdx]] = specials.randomElement()!; slotIdx += 1 }

            chars.shuffle()

            let candidate = String(chars)

            // Quick rejection: consecutive repeats (aaa)
            if candidate.range(of: "(.)\\1{2,}", options: .regularExpression) != nil { continue }

            // Quick rejection: sequential chars (abc, 321)
            if hasSequential(candidate) { continue }

            // Full analysis — reject if any pattern found
            let a = PasswordAnalyzer.analyze(candidate)
            if !a.patterns.isEmpty { continue }

            let s = max(0, min(100, a.strengthScore - a.patternPenalty + 15))

            if s > bestScore {
                best = candidate
                bestScore = s
            }

            // Perfect score — stop immediately
            if a.patternPenalty == 0 && s >= 70 { break }
        }

        // Fallback: if all 50 attempts had patterns, use the best one found
        if best.isEmpty {
            let chars: [Character] = (0..<len).map { _ in pool.randomElement()! }
            best = String(chars)
        }

        generated = best
        copied = false
    }

    func copy() {
        UIPasteboard.general.string = generated
        copied = true
    }

    /// Check for 3+ sequential ascending/descending characters
    private func hasSequential(_ password: String) -> Bool {
        let vals = Array(password.unicodeScalars.map { Int($0.value) })
        guard vals.count >= 3 else { return false }
        var asc = 1, desc = 1
        for i in 1..<vals.count {
            if vals[i] == vals[i-1] + 1 { asc += 1; if asc >= 3 { return true } } else { asc = 1 }
            if vals[i] == vals[i-1] - 1 { desc += 1; if desc >= 3 { return true } } else { desc = 1 }
        }
        return false
    }

    // Security level description
    var securityLevel: String {
        if generated.isEmpty { return "" }
        if score >= 80 { return "매우 강력한 비밀번호입니다" }
        if score >= 70 { return "안전한 비밀번호입니다" }
        if score >= 50 { return "보통 수준입니다. 길이를 늘려보세요" }
        if score >= 30 { return "약한 비밀번호입니다. 특수문자를 추가하세요" }
        return "매우 약합니다. 옵션을 더 켜주세요"
    }

    // Estimated crack time (approximate)
    var crackTimeText: String {
        guard !generated.isEmpty else { return "" }
        let entropy = analysis.entropy
        // Assume 10 billion guesses/sec
        let seconds = pow(2.0, entropy) / 10_000_000_000
        if seconds < 1 { return "즉시 해독 가능" }
        if seconds < 60 { return "약 \(Int(seconds))초" }
        if seconds < 3600 { return "약 \(Int(seconds / 60))분" }
        if seconds < 86400 { return "약 \(Int(seconds / 3600))시간" }
        if seconds < 86400 * 365 { return "약 \(Int(seconds / 86400))일" }
        if seconds < 86400 * 365 * 1000 { return "약 \(Int(seconds / (86400 * 365)))년" }
        if seconds < 86400 * 365 * 1_000_000 { return "약 \(Int(seconds / (86400 * 365 * 1000)))천년" }
        return "사실상 해독 불가능"
    }
}
