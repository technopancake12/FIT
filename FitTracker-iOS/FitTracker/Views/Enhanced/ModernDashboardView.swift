import SwiftUI

struct ModernDashboardView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var openWorkoutService = OpenWorkoutService.shared
    @State private var dailyNutrition: DailyNutrition = DailyNutrition()
    @State private var recentWorkouts: [EnhancedWorkout] = []
    @State private var todayProgress: DashboardProgress = DashboardProgress()
    @State private var showQuickActions = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header with greeting and profile
                        headerView
                        
                        // Quick stats overview
                        quickStatsView
                        
                        // Today's progress
                        todayProgressView
                        
                        // Quick actions
                        if showQuickActions {
                            quickActionsView
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Nutrition overview
                        nutritionOverviewView
                        
                        // Recent workouts
                        recentWorkoutsView
                        
                        // Weekly summary
                        weeklySummaryView
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .refreshable {
                    await refreshData()
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: { 
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showQuickActions.toggle()
                            }
                        }) {
                            Image(systemName: showQuickActions ? "xmark" : "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                                .rotationEffect(.degrees(showQuickActions ? 45 : 0))
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showQuickActions)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadDashboardData()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(firebaseManager.currentUser?.displayName ?? "Fitness Enthusiast")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {}) {
                    AsyncImage(url: URL(string: firebaseManager.currentUser?.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                }
            }
            
            // Date selector
            HStack {
                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(selectedDate, style: .date)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .disabled(Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                .opacity(Calendar.current.isDate(selectedDate, inSameDayAs: Date()) ? 0.3 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                title: "Calories",
                value: "\(Int(dailyNutrition.totalCalories))",
                subtitle: "of \(Int(dailyNutrition.goals.calories))",
                progress: dailyNutrition.caloriesProgress,
                color: .orange,
                icon: "flame.fill"
            )
            
            QuickStatCard(
                title: "Workouts",
                value: "\(todayProgress.workoutsCompleted)",
                subtitle: "completed",
                progress: Double(todayProgress.workoutsCompleted) / max(Double(todayProgress.plannedWorkouts), 1.0),
                color: .blue,
                icon: "dumbbell.fill"
            )
            
            QuickStatCard(
                title: "Steps",
                value: "\(todayProgress.steps)",
                subtitle: "today",
                progress: Double(todayProgress.steps) / 10000.0,
                color: .green,
                icon: "figure.walk"
            )
        }
    }
    
    private var todayProgressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Today's Goals")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(todayProgress.overallProgress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                ProgressGoalRow(
                    title: "Protein",
                    current: Int(dailyNutrition.totalProtein),
                    target: Int(dailyNutrition.goals.protein),
                    unit: "g",
                    progress: dailyNutrition.proteinProgress,
                    color: .red
                )
                
                ProgressGoalRow(
                    title: "Water",
                    current: Int(dailyNutrition.waterIntake),
                    target: Int(dailyNutrition.goals.water),
                    unit: "ml",
                    progress: dailyNutrition.waterProgress,
                    color: .blue
                )
                
                ProgressGoalRow(
                    title: "Active Minutes",
                    current: todayProgress.activeMinutes,
                    target: 30,
                    unit: "min",
                    progress: Double(todayProgress.activeMinutes) / 30.0,
                    color: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Start Workout",
                    icon: "play.fill",
                    color: .blue
                ) {
                    // Navigate to workout
                }
                
                QuickActionButton(
                    title: "Log Food",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    // Navigate to food logging
                }
            }
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Add Water",
                    icon: "drop.fill",
                    color: .cyan
                ) {
                    // Quick water logging
                }
                
                QuickActionButton(
                    title: "Take Photo",
                    icon: "camera.fill",
                    color: .purple
                ) {
                    // Progress photo
                }
            }
        }
    }
    
    private var nutritionOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Nutrition Today")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: EnhancedNutritionSearchView(mealType: "General", onFoodSelected: { _ in })) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 16) {
                MacroCircle(
                    title: "Carbs",
                    current: dailyNutrition.totalCarbs,
                    target: dailyNutrition.goals.carbs,
                    color: .yellow
                )
                
                MacroCircle(
                    title: "Protein",
                    current: dailyNutrition.totalProtein,
                    target: dailyNutrition.goals.protein,
                    color: .red
                )
                
                MacroCircle(
                    title: "Fat",
                    current: dailyNutrition.totalFat,
                    target: dailyNutrition.goals.fat,
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var recentWorkoutsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Recent Workouts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: EnhancedExerciseSearchView()) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            if recentWorkouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No workouts yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Start your first workout to see it here")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentWorkouts.prefix(5)) { workout in
                            WorkoutCard(workout: workout)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var weeklySummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("This Week")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                WeeklySummaryItem(
                    title: "Workouts",
                    value: "\(todayProgress.weeklyWorkouts)",
                    change: "+2",
                    isPositive: true
                )
                
                WeeklySummaryItem(
                    title: "Avg Calories",
                    value: "\(todayProgress.avgCalories)",
                    change: "+150",
                    isPositive: true
                )
                
                WeeklySummaryItem(
                    title: "Total Volume",
                    value: "\(Int(todayProgress.totalVolume))kg",
                    change: "+5%",
                    isPositive: true
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private func loadDashboardData() async {
        // Load dashboard data from Firebase and local storage
        // This would typically fetch user's nutrition, workouts, and progress data
    }
    
    private func refreshData() async {
        await loadDashboardData()
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 3)
                    .overlay(
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * min(progress, 1.0), height: 3)
                            .animation(.easeInOut, value: progress),
                        alignment: .leading
                    )
            }
            .frame(height: 3)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ProgressGoalRow: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("\(current)/\(target) \(unit)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 6)
                    .overlay(
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * min(progress, 1.0), height: 6)
                            .animation(.easeInOut, value: progress),
                        alignment: .leading
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .frame(height: 6)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.8))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MacroCircle: View {
    let title: String
    let current: Double
    let target: Double
    let color: Color
    
    var progress: Double {
        guard target > 0 else { return 0.0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(Int(current))g")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct WorkoutCard: View {
    let workout: EnhancedWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                if workout.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
            
            Text(workout.date, style: .date)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    
                    Text("\(workout.exercises.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                if let duration = workout.duration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        
                        Text("\(Int(duration / 60))m")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct WeeklySummaryItem: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isPositive ? .green : .red)
                
                Text(change)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Data Models
struct DashboardProgress {
    var workoutsCompleted: Int = 0
    var plannedWorkouts: Int = 1
    var steps: Int = 0
    var activeMinutes: Int = 0
    var weeklyWorkouts: Int = 0
    var avgCalories: Int = 2000
    var totalVolume: Double = 0.0
    
    var overallProgress: Double {
        let workoutProgress = Double(workoutsCompleted) / max(Double(plannedWorkouts), 1.0)
        let stepProgress = min(Double(steps) / 10000.0, 1.0)
        let activeProgress = min(Double(activeMinutes) / 30.0, 1.0)
        
        return (workoutProgress + stepProgress + activeProgress) / 3.0
    }
}

#Preview {
    ModernDashboardView()
}
