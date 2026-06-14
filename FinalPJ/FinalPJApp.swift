import SwiftUI
import SwiftData

@main
struct FinalPJApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Account.self)
    }
}
