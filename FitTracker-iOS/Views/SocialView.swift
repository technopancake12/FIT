import SwiftUI

struct SocialView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("👥")
                        .font(.system(size: 80))
                    
                    Text("Social Fitness")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Connect with the fitness community, share your progress, and get motivated by others.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        FeatureCard(
                            icon: "person.2.fill",
                            title: "Follow Friends",
                            description: "Connect with friends and fitness enthusiasts"
                        )
                        
                        FeatureCard(
                            icon: "square.and.pencil",
                            title: "Share Workouts",
                            description: "Post your workout achievements"
                        )
                        
                        FeatureCard(
                            icon: "heart.fill",
                            title: "Like & Comment",
                            description: "Engage with the community"
                        )
                        
                        FeatureCard(
                            icon: "trophy.fill",
                            title: "Achievements",
                            description: "Celebrate fitness milestones"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 40)
            }
            .navigationTitle("Social")
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    SocialView()
}