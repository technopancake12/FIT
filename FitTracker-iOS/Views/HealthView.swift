import SwiftUI

struct HealthView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("❤️")
                        .font(.system(size: 80))
                    
                    Text("Health Integration")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Connect with Apple Health and other health apps to get a complete picture of your wellness.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        FeatureCard(
                            icon: "heart.text.square.fill",
                            title: "Apple Health",
                            description: "Sync with Apple Health app"
                        )
                        
                        FeatureCard(
                            icon: "figure.walk",
                            title: "Activity Tracking",
                            description: "Monitor daily steps and activity"
                        )
                        
                        FeatureCard(
                            icon: "bed.double.fill",
                            title: "Sleep Tracking",
                            description: "Track sleep quality and duration"
                        )
                        
                        FeatureCard(
                            icon: "waveform.path.ecg",
                            title: "Health Metrics",
                            description: "Monitor heart rate and other vitals"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 40)
            }
            .navigationTitle("Health")
        }
    }
}

#Preview {
    HealthView()
}