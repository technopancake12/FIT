import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ModernDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            EnhancedExerciseSearchView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Workouts")
                }
                .tag(1)
            
            EnhancedNutritionView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Nutrition")
                }
                .tag(2)
            
            SocialView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Social")
                }
                .tag(3)
            
            ProgressScreenView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Progress")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseManager.shared)
}