import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var analyticsService: AnalyticsService
    @State private var selectedTimeframe: ProgressTimeframe = .threeMonths
    @State private var selectedMetric: AnalyticsMetric = .volume
    @State private var showingGoalCreation = false
    @State private var progressData: [ProgressDataPoint] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Quick Stats Cards
                    QuickStatsSection()
                    
                    // Progress Chart
                    ProgressChartSection(
                        selectedTimeframe: $selectedTimeframe,
                        selectedMetric: $selectedMetric,
                        progressData: progressData
                    )
                    
                    // Goals Section
                    GoalsSection(onCreateGoal: { showingGoalCreation = true })
                    
                    // Achievements Section
                    AchievementsSection()
                    
                    // Personal Records
                    PersonalRecordsSection()
                    
                    // Detailed Analytics
                    DetailedAnalyticsSection()
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadAnalytics()
            }
            .sheet(isPresented: $showingGoalCreation) {
                CreateGoalView()
            }
        }
        .onAppear {
            Task {
                await loadAnalytics()
            }
        }
        .onChange(of: selectedTimeframe) { _ in
            Task {
                await loadProgressData()
            }
        }
    }
    
    private func loadAnalytics() async {
        do {
            try await analyticsService.getUserGoals()
            await loadProgressData()
        } catch {
            print("Error loading analytics: \(error)")
        }
    }
    
    private func loadProgressData() async {
        do {
            let data = try await analyticsService.getProgressHistory(timeframe: selectedTimeframe)
            await MainActor.run {
                self.progressData = data
            }
        } catch {
            print("Error loading progress data: \(error)")
        }
    }
}

// MARK: - Quick Stats Section
struct QuickStatsSection: View {
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let analytics = analyticsService.currentAnalytics {
                    StatCard(
                        title: "Total Workouts",
                        value: "\(analytics.totalWorkouts)",
                        icon: "dumbbell",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Total Volume",
                        value: formatVolume(analytics.totalVolume),
                        icon: "scalemass",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Current Streak",
                        value: "\(analytics.currentStreak) days",
                        icon: "flame",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Avg Duration",
                        value: formatDuration(analytics.averageWorkoutDuration),
                        icon: "clock",
                        color: .purple
                    )
                } else {
                    // Loading placeholders
                    ForEach(0..<4, id: \.self) { _ in
                        StatCard(
                            title: "Loading...",
                            value: "---",
                            icon: "questionmark",
                            color: .gray
                        )
                    }
                }
            }
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000000 {
            return String(format: "%.1fM lbs", volume / 1000000)
        } else if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        } else {
            return "\(Int(volume)) lbs"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Progress Chart Section
struct ProgressChartSection: View {
    @Binding var selectedTimeframe: ProgressTimeframe
    @Binding var selectedMetric: AnalyticsMetric
    let progressData: [ProgressDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    ForEach(ProgressTimeframe.allCases, id: \.self) { timeframe in
                        Button(timeframe.displayName) {
                            selectedTimeframe = timeframe
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTimeframe.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Metric Selector
            HStack {
                ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                    Button(action: { selectedMetric = metric }) {
                        Text(metric.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMetric == metric ? Color.blue : Color(UIColor.systemGray6))
                            .foregroundColor(selectedMetric == metric ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Chart
            if #available(iOS 16.0, *) {
                Chart(progressData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(selectedMetric.displayName, getMetricValue(dataPoint, metric: selectedMetric))
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                SimpleLineChart(data: progressData, metric: selectedMetric)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func getMetricValue(_ dataPoint: ProgressDataPoint, metric: AnalyticsMetric) -> Double {
        switch metric {
        case .volume:
            return dataPoint.totalVolume
        case .workouts:
            return Double(dataPoint.totalWorkouts)
        case .duration:
            return dataPoint.averageDuration / 60 // Convert to minutes
        }
    }
}

// MARK: - Simple Line Chart (iOS 15 fallback)
struct SimpleLineChart: View {
    let data: [ProgressDataPoint]
    let metric: AnalyticsMetric
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                let maxValue = data.map { getMetricValue($0) }.max() ?? 1
                let minValue = data.map { getMetricValue($0) }.min() ?? 0
                let range = maxValue - minValue
                
                for (index, point) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(data.count - 1)
                    let normalizedValue = range > 0 ? (getMetricValue(point) - minValue) / range : 0.5
                    let y = height * (1 - normalizedValue)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }
    
    private func getMetricValue(_ dataPoint: ProgressDataPoint) -> Double {
        switch metric {
        case .volume:
            return dataPoint.totalVolume
        case .workouts:
            return Double(dataPoint.totalWorkouts)
        case .duration:
            return dataPoint.averageDuration / 60
        }
    }
}

// MARK: - Goals Section
struct GoalsSection: View {
    @EnvironmentObject private var analyticsService: AnalyticsService
    let onCreateGoal: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Goals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Add Goal") {
                    onCreateGoal()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if analyticsService.goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No goals set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Set fitness goals to track your progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(analyticsService.goals.prefix(3)) { goal in
                        GoalCardView(goal: goal)
                    }
                    
                    if analyticsService.goals.count > 3 {
                        NavigationLink("View All Goals") {
                            GoalsListView()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Goal Card View
struct GoalCardView: View {
    let goal: FitnessGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.type.icon)
                    .foregroundColor(.blue)
                
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(goal.progressPercentage))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(goal.isCompleted ? .green : .blue)
            }
            
            ProgressView(value: goal.progressPercentage / 100)
                .tint(goal.isCompleted ? .green : .blue)
            
            HStack {
                Text("\(formatValue(goal.currentProgress)) / \(formatValue(goal.targetValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Due: \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Achievements Section
struct AchievementsSection: View {
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("View All") {
                    AchievementsListView()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if analyticsService.achievements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete workouts to unlock achievements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(analyticsService.achievements.prefix(5)) { achievement in
                            AchievementBadgeView(achievement: achievement)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Achievement Badge View
struct AchievementBadgeView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.rarity == .rare || achievement.rarity == .epic || achievement.rarity == .legendary ? 
                          LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if achievement.rarity == .rare || achievement.rarity == .epic || achievement.rarity == .legendary {
                Text(achievement.rarity.displayName.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Personal Records Section
struct PersonalRecordsSection: View {
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    var personalRecords: [PersonalRecord] {
        analyticsService.currentAnalytics?.personalRecords.prefix(3).map { $0 } ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Personal Records")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("View All") {
                    PersonalRecordsListView()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if personalRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "medal")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No personal records yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete workouts to set new records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(personalRecords) { record in
                        PersonalRecordRowView(record: record)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Personal Record Row View
struct PersonalRecordRowView: View {
    let record: PersonalRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(record.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(formatRecordValue(record.value)) \(record.type.unit)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatRecordValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Detailed Analytics Section
struct DetailedAnalyticsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Analytics")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NavigationLink(destination: WorkoutAnalyticsView()) {
                    AnalyticsOptionCard(
                        title: "Workout Analytics",
                        description: "Detailed workout insights",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: BodyAnalyticsView()) {
                    AnalyticsOptionCard(
                        title: "Body Analytics",
                        description: "Track measurements & weight",
                        icon: "figure.arms.open",
                        color: .green
                    )
                }
                
                NavigationLink(destination: NutritionAnalyticsView()) {
                    AnalyticsOptionCard(
                        title: "Nutrition Analytics",
                        description: "Calorie & macro tracking",
                        icon: "fork.knife",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: ProgressPhotosView()) {
                    AnalyticsOptionCard(
                        title: "Progress Photos",
                        description: "Visual progress tracking",
                        icon: "camera",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Analytics Option Card
struct AnalyticsOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Types
enum AnalyticsMetric: CaseIterable {
    case volume, workouts, duration
    
    var displayName: String {
        switch self {
        case .volume: return "Volume"
        case .workouts: return "Workouts"
        case .duration: return "Duration"
        }
    }
}

enum ProgressTimeframe: CaseIterable {
    case oneWeek, oneMonth, threeMonths, sixMonths, oneYear
    
    var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        }
    }
}

// MARK: - Placeholder Views
struct GoalsListView: View {
    var body: some View {
        Text("Goals List View")
            .navigationTitle("Goals")
    }
}

struct AchievementsListView: View {
    var body: some View {
        Text("Achievements List View")
            .navigationTitle("Achievements")
    }
}

struct PersonalRecordsListView: View {
    var body: some View {
        Text("Personal Records List View")
            .navigationTitle("Personal Records")
    }
}

struct WorkoutAnalyticsView: View {
    var body: some View {
        Text("Workout Analytics View")
            .navigationTitle("Workout Analytics")
    }
}

struct BodyAnalyticsView: View {
    var body: some View {
        Text("Body Analytics View")
            .navigationTitle("Body Analytics")
    }
}

struct NutritionAnalyticsView: View {
    var body: some View {
        Text("Nutrition Analytics View")
            .navigationTitle("Nutrition Analytics")
    }
}

struct ProgressPhotosView: View {
    var body: some View {
        Text("Progress Photos View")
            .navigationTitle("Progress Photos")
    }
}

struct CreateGoalView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Create Goal View")
                .navigationTitle("Create Goal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}