import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Home")
                }
                .tag(0)
            
            WorkoutView()
                .tabItem {
                    Image(systemName: "dumbbell")
                    Text("Workout")
                }
                .tag(1)
            
            NutritionView()
                .tabItem {
                    Image(systemName: "apple")
                    Text("Nutrition")
                }
                .tag(2)
            
            SocialView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Social")
                }
                .tag(3)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Analytics")
                }
                .tag(4)
            
            HealthView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Health")
                }
                .tag(5)
        }
        .accentColor(.blue)
    }
}