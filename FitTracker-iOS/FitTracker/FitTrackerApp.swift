import SwiftUI
import Firebase

@main
struct FitTrackerApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(firebaseManager)
        }
    }
}