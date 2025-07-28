import SwiftUI

struct ProgressView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("📊")
                        .font(.system(size: 80))
                    
                    Text("Progress Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Visualize your fitness journey with detailed charts and statistics.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        FeatureCard(
                            icon: "chart.bar.fill",
                            title: "Workout Stats",
                            description: "Track volume, frequency, and progression"
                        )
                        
                        FeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Strength Progress",
                            description: "Monitor your lifting improvements"
                        )
                        
                        FeatureCard(
                            icon: "calendar",
                            title: "Weekly Reports",
                            description: "View detailed weekly summaries"
                        )
                        
                        FeatureCard(
                            icon: "target",
                            title: "Goal Tracking",
                            description: "Set and monitor fitness goals"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 40)
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressView()
}