import SwiftUI
import CoreData
import Firebase

@main
struct FitTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseManager.isAuthenticated {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    LoginView()
                }
            }
            .environmentObject(firebaseManager)
        }
    }
}