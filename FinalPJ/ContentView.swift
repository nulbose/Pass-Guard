import SwiftUI

struct ContentView: View {
    @State private var authVM = AuthViewModel()
    @State private var settingsVM = SettingsViewModel()

    var body: some View {
        if authVM.isLoggedIn {
            TabView {
                HomeDashboardView()
                    .tabItem { Label("홈", systemImage: "house.fill") }

                AccountListView()
                    .tabItem { Label("계정", systemImage: "key.fill") }

                PasswordGeneratorView()
                    .tabItem { Label("생성기", systemImage: "wand.and.stars") }

                SettingsView(settingsVM: settingsVM, authVM: authVM)
                    .tabItem { Label("설정", systemImage: "gearshape.fill") }
            }
            .tint(.blue)
        } else {
            LoginView(authVM: authVM)
        }
    }
}
