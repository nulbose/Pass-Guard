import Foundation
import Observation

@Observable
final class AuthViewModel {
    var username = ""
    var password = ""
    var confirmPassword = ""
    var isLoggedIn = false
    var errorMessage = ""
    var successMessage = ""
    var isSignUp = false

    func signUp() {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "아이디를 입력해주세요."; return
        }
        guard password.count >= 6 else {
            errorMessage = "비밀번호는 6자 이상이어야 합니다."; return
        }
        guard password == confirmPassword else {
            errorMessage = "비밀번호가 일치하지 않습니다."; return
        }
        let key = "passguard_auth_\(username.lowercased())"
        guard !KeychainManager.exists(key: key) else {
            errorMessage = "이미 존재하는 아이디입니다."; return
        }
        KeychainManager.save(key: key, value: KeychainManager.sha256(password))
        errorMessage = ""
        successMessage = "회원가입 완료! 로그인해주세요."
        isSignUp = false
        password = ""
        confirmPassword = ""
    }

    func login() {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "아이디를 입력해주세요."; return
        }
        guard !password.isEmpty else {
            errorMessage = "비밀번호를 입력해주세요."; return
        }
        let key = "passguard_auth_\(username.lowercased())"
        guard let stored = KeychainManager.load(key: key) else {
            errorMessage = "등록되지 않은 아이디입니다."; return
        }
        guard stored == KeychainManager.sha256(password) else {
            errorMessage = "비밀번호가 올바르지 않습니다."; return
        }
        errorMessage = ""
        successMessage = ""
        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
        username = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
        successMessage = ""
    }

    /// 계정 탈퇴: Keychain에서 인증 정보 삭제 후 로그아웃
    func deleteUser() {
        let key = "passguard_auth_\(username.lowercased())"
        KeychainManager.delete(key: key)
        logout()
    }
}
