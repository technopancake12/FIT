import SwiftUI

struct DashboardView: View {
    @State private var showFocusMode = false
    @State private var focusModeActive = false
    @ObservedObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerView
                    
                    // Quick Stats
                    quickStatsView
                    
                    // Today's Goals
                    todaysGoalsView
                    
                    // Quick Actions
                    quickActionsView
                    
                    // Advanced Features
                    advancedFeaturesView
                }
                .padding()
            }
            .navigationTitle("Good Morning! 💪")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFocusMode) {
                FocusModeView(isActive: $focusModeActive)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Good morning! 💪")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Ready for today's workout?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showFocusMode = true }) {
                Image(systemName: "shield")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderedButtonStyle())
        }
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "bolt.fill",
                iconColor: .orange,
                title: "Streak",
                value: "7 days"
            )
            
            StatCard(
                icon: "calendar",
                iconColor: .blue,
                title: "This Week",
                value: "4 workouts"
            )
        }
    }
    
    private var todaysGoalsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Goals")
                .font(.headline)
            
            VStack(spacing: 12) {
                GoalProgressView(
                    title: "Calories Burned",
                    current: 450,
                    target: 600,
                    color: .red
                )
                
                GoalProgressView(
                    title: "Protein Intake",
                    current: 120,
                    target: 150,
                    unit: "g",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var quickActionsView: some View {
        HStack(spacing: 16) {
            ActionButton(
                title: "Start Workout",
                icon: "play.fill",
                color: .blue,
                action: { /* Navigate to workout */ }
            )
            
            ActionButton(
                title: "Log Meal",
                icon: "plus",
                color: .green,
                isOutlined: true,
                action: { /* Navigate to nutrition */ }
            )
        }
    }
    
    private var advancedFeaturesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore Features")
                .font(.headline)
            Text("Access all advanced functionality")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                AdvancedFeatureCard(
                    title: "Challenges",
                    description: "Join fitness challenges",
                    icon: "trophy.fill"
                )
                
                AdvancedFeatureCard(
                    title: "Video Tutorials",
                    description: "Exercise form guides",
                    icon: "video.fill"
                )
                
                AdvancedFeatureCard(
                    title: "Meal Planning",
                    description: "Plan your nutrition",
                    icon: "fork.knife"
                )
                
                AdvancedFeatureCard(
                    title: "Custom Builder",
                    description: "Create custom workouts",
                    icon: "wrench.and.screwdriver.fill"
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GoalProgressView: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String?
    let color: Color
    
    init(title: String, current: Int, target: Int, unit: String? = nil, color: Color) {
        self.title = title
        self.current = current
        self.target = target
        self.unit = unit
        self.color = color
    }
    
    var progress: Double {
        Double(current) / Double(target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(current)/\(target)" + (unit ?? ""))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isOutlined: Bool
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, isOutlined: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isOutlined = isOutlined
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .foregroundColor(isOutlined ? color : .white)
            .background(isOutlined ? Color.clear : color)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isOutlined ? 2 : 0)
            )
            .cornerRadius(12)
        }
    }
}

struct AdvancedFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

class DashboardViewModel: ObservableObject {
    @Published var streak: Int = 7
    @Published var weeklyWorkouts: Int = 4
    @Published var caloriesBurned: Int = 450
    @Published var caloriesTarget: Int = 600
    @Published var proteinIntake: Int = 120
    @Published var proteinTarget: Int = 150
    
    init() {
        loadDashboardData()
    }
    
    private func loadDashboardData() {
        // Load data from Core Data or UserDefaults
        // This would typically fetch from your data persistence layer
    }
}

#Preview {
    DashboardView()
}