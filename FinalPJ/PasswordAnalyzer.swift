import Foundation

struct PasswordAnalysis {
    var strengthScore: Int
    var patternPenalty: Int
    var entropy: Double
    var patterns: [String]
}

enum PasswordAnalyzer {

    // MARK: - Expanded dictionary (100+)

    private static let dictionary: [String] = [
        "password", "qwerty", "abc123", "monkey", "master",
        "dragon", "login", "letmein", "welcome", "shadow",
        "sunshine", "princess", "football", "iloveyou", "admin",
        "passw0rd", "trustno1", "batman", "baseball", "access",
        "hello", "charlie", "donald", "michael", "jordan",
        "love", "star", "ninja", "angel", "friend",
        "samsung", "apple", "google", "naver", "kakao",
        "computer", "internet", "soccer", "hockey", "tennis",
        "summer", "winter", "spring", "flower", "butterfly",
        "diamond", "forever", "freedom", "secret", "magic",
        "super", "power", "lucky", "happy", "smile",
        "death", "killer", "hunter", "gamer", "hacker",
        "cookie", "banana", "orange", "pepper", "cheese",
        "guitar", "piano", "music", "movie", "anime",
        "seoul", "korea", "hansung", "university", "student",
        "test", "sample", "example", "default", "temp",
        "abcdef", "aaaaaa", "zzzzzz", "asdfgh", "zxcvbn",
        "qazwsx", "nothing", "whatever", "changeme", "matrix",
        "pokemon", "minecraft", "roblox", "fortnite", "league"
    ]

    // MARK: - Keyboard patterns

    private static let keyboards: [String] = [
        "qwerty", "qwertyui", "qwertyu", "asdf", "asdfgh",
        "asdfghjk", "zxcv", "zxcvbn", "zxcvbnm",
        "1234", "12345", "123456", "1234567", "12345678", "123456789",
        "abcdef", "abcdefgh", "qazwsx", "1qaz2wsx",
        "!@#$", "!@#$%", "!@#$%^"
    ]

    // MARK: - Leet speak mapping

    private static let leetMap: [Character: Character] = [
        "@": "a", "4": "a",
        "8": "b",
        "(": "c",
        "3": "e",
        "6": "g",
        "#": "h",
        "!": "i", "1": "i",
        "0": "o",
        "$": "s", "5": "s",
        "7": "t",
        "+": "t",
        "2": "z",
    ]

    /// Convert leet speak to plain text: P@ssw0rd → password
    private static func deLeet(_ input: String) -> String {
        String(input.lowercased().map { leetMap[$0] ?? $0 })
    }

    // MARK: - Full Analysis

    static func analyze(_ password: String) -> PasswordAnalysis {
        let entropy = calcEntropy(password)
        // 60 bits = 60점 (만점). 10자+대소문자+숫자+특수문자 ≈ 65비트로 만점 도달
        let strength = min(60, Int(entropy / 60.0 * 60.0))
        let (penalty, patterns) = detectPatterns(password)
        return PasswordAnalysis(
            strengthScore: strength,
            patternPenalty: min(penalty, 20),
            entropy: entropy,
            patterns: patterns
        )
    }

    // MARK: - Entropy

    static func calcEntropy(_ password: String) -> Double {
        guard !password.isEmpty else { return 0 }
        var pool = 0
        if password.range(of: "[a-z]", options: .regularExpression) != nil { pool += 26 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { pool += 26 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { pool += 10 }
        if password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { pool += 32 }
        guard pool > 0 else { return 0 }
        return log2(Double(pool)) * Double(password.count)
    }

    // MARK: - Pattern Detection (enhanced)

    static func detectPatterns(_ password: String) -> (Int, [String]) {
        var penalty = 0
        var found: [String] = []
        let low = password.lowercased()
        let deleet = deLeet(password)

        // 1. Dictionary word check (-5)
        var dictFound = false
        for word in dictionary where word.count >= 4 {
            if low.contains(word) {
                penalty += 5
                found.append("사전 단어: \(word)")
                dictFound = true
                break
            }
        }

        // 2. Leet speak detection (-5) - only if plain dict didn't match
        if !dictFound {
            for word in dictionary where word.count >= 4 {
                if deleet.contains(word) {
                    penalty += 5
                    found.append("치환 단어 감지: \(word) (예: P@ss → pass)")
                    break
                }
            }
        }

        // 3. Keyboard pattern check (-5)
        for kb in keyboards where low.contains(kb) {
            penalty += 5
            found.append("키보드 패턴: \(kb)")
            break
        }

        // 4. Consecutive repeated characters (-3): "aaa", "111"
        if password.range(of: "(.)\\1{2,}", options: .regularExpression) != nil {
            penalty += 3
            found.append("연속 반복 문자 (예: aaa)")
        }

        // 5. Sequential characters (-3): "abc", "321", "xyz"
        if hasSequential(password, minLen: 3) {
            penalty += 3
            found.append("순차/역순 문자열 (예: abc, 987)")
        }

        // 6. Date format (-2)
        if password.range(of: "(19|20)\\d{2}", options: .regularExpression) != nil {
            penalty += 2
            found.append("날짜 형식 (예: 2024)")
        }

        // 7. Character distribution bias (-3)
        if hasDistributionBias(password) {
            penalty += 3
            found.append("문자 종류 편향 (한 종류에 치우침)")
        }

        // 8. Word + number suffix (-3): "hello123", "admin2024"
        if !dictFound {
            if hasWordNumberCombo(low) || hasWordNumberCombo(deleet) {
                penalty += 3
                found.append("단어+숫자 조합 (예: hello123)")
            }
        }

        return (penalty, found)
    }

    // MARK: - Sequential detection

    /// Detect 3+ ascending or descending consecutive characters
    private static func hasSequential(_ password: String, minLen: Int) -> Bool {
        let scalars = Array(password.unicodeScalars.map { Int($0.value) })
        guard scalars.count >= minLen else { return false }

        var ascCount = 1
        var descCount = 1

        for i in 1..<scalars.count {
            if scalars[i] == scalars[i - 1] + 1 {
                ascCount += 1
                if ascCount >= minLen { return true }
            } else {
                ascCount = 1
            }

            if scalars[i] == scalars[i - 1] - 1 {
                descCount += 1
                if descCount >= minLen { return true }
            } else {
                descCount = 1
            }
        }
        return false
    }

    // MARK: - Distribution bias

    /// Check if one character category dominates (>70% of total length)
    private static func hasDistributionBias(_ password: String) -> Bool {
        guard password.count >= 6 else { return false }
        let total = Double(password.count)

        let lowerCount = password.filter { $0.isLowercase }.count
        let upperCount = password.filter { $0.isUppercase }.count
        let digitCount = password.filter { $0.isNumber }.count
        let specialCount = password.filter { !$0.isLetter && !$0.isNumber }.count

        let counts = [lowerCount, upperCount, digitCount, specialCount].filter { $0 > 0 }

        // If only 1 category is used, entropy already handles it
        guard counts.count >= 2 else { return false }

        // If any single category is >70% of the password
        for c in counts {
            if Double(c) / total > 0.7 { return true }
        }
        return false
    }

    // MARK: - Word + Number combo

    /// Detect patterns like "hello123", "admin2024"
    private static func hasWordNumberCombo(_ input: String) -> Bool {
        for word in dictionary where word.count >= 4 {
            if input.hasPrefix(word) {
                let suffix = String(input.dropFirst(word.count))
                if !suffix.isEmpty && suffix.allSatisfy({ $0.isNumber }) { return true }
            }
            if input.hasSuffix(word) {
                let prefix = String(input.dropLast(word.count))
                if !prefix.isEmpty && prefix.allSatisfy({ $0.isNumber }) { return true }
            }
        }
        return false
    }

    // MARK: - Utilities

    static func findReusedIDs(_ accounts: [Account]) -> Set<UUID> {
        var map: [String: [UUID]] = [:]
        for a in accounts { map[a.passwordHash, default: []].append(a.id) }
        var result: Set<UUID> = []
        for ids in map.values where ids.count > 1 { result.formUnion(ids) }
        return result
    }

    static func overallScore(_ accounts: [Account]) -> Int {
        guard !accounts.isEmpty else { return 0 }
        return accounts.reduce(0) { $0 + $1.totalScore } / accounts.count
    }

    static func label(_ score: Int) -> String {
        if score >= 70 { return "안전" }
        if score >= 40 { return "주의" }
        return "위험"
    }
}
