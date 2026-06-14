import SwiftUI

struct LoginView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        ScrollView {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            Image(systemName: "shield.checkered")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .padding(.bottom, 8)

            Text("PassGuard")
                .font(.largeTitle.bold())

            Text("비밀번호 보안 관리")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 36)

            VStack(spacing: 14) {
                TextField("아이디", text: $authVM.username)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                SecureField("비밀번호", text: $authVM.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.oneTimeCode)

                if authVM.isSignUp {
                    SecureField("비밀번호 확인", text: $authVM.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.oneTimeCode)
                }
            }
            .padding(.horizontal, 32)

            if !authVM.successMessage.isEmpty {
                Text(authVM.successMessage)
                    .font(.caption).foregroundStyle(.green)
                    .padding(.top, 8)
            }
            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .font(.caption).foregroundStyle(.red)
                    .padding(.top, 4)
            }

            Button {
                if authVM.isSignUp { authVM.signUp() }
                else { authVM.login() }
            } label: {
                Text(authVM.isSignUp ? "회원가입" : "로그인")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)

            Button {
                withAnimation {
                    authVM.isSignUp.toggle()
                    authVM.errorMessage = ""
                    authVM.successMessage = ""
                    authVM.password = ""
                    authVM.confirmPassword = ""
                }
            } label: {
                Text(authVM.isSignUp ? "이미 계정이 있나요? 로그인" : "계정이 없나요? 회원가입")
                    .font(.subheadline)
            }
            .padding(.top, 14)

            Spacer(minLength: 60)
        }
        .frame(minHeight: 700)
        }
    }
}
