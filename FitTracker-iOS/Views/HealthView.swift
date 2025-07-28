import SwiftUI
import Charts

struct HealthView: View {
    @StateObject private var healthService = HealthKitService.shared
    @State private var showingHealthPermissions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health & Wellness")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your complete health overview powered by Apple Health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if !healthService.isAuthorized {
                        // Health permissions prompt
                        HealthPermissionPrompt(showingPermissions: $showingHealthPermissions)
                            .padding(.horizontal)
                    } else {
                        if healthService.isLoading {
                            LoadingView()
                        } else {
                            // Health data content
                            VStack(spacing: 20) {
                                // Today's stats
                                TodayHealthStats(healthData: healthService.healthData)
                                    .padding(.horizontal)
                                
                                // Weekly activity chart
                                WeeklyActivityChart(healthData: healthService.healthData)
                                    .padding(.horizontal)
                                
                                // Body metrics
                                BodyMetricsSection(healthData: healthService.healthData)
                                    .padding(.horizontal)
                                
                                // Heart health
                                HeartHealthSection(healthData: healthService.healthData)
                                    .padding(.horizontal)
                                
                                // Workout insights
                                WorkoutInsightsSection(healthData: healthService.healthData)
                                    .padding(.horizontal)
                                
                                // Health recommendations
                                HealthRecommendations(healthData: healthService.healthData)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .refreshable {
                if healthService.isAuthorized {
                    healthService.loadAllHealthData()
                }
            }
        }
        .sheet(isPresented: $showingHealthPermissions) {
            HealthPermissionsSheet()
        }
    }
}

struct HealthPermissionPrompt: View {
    @Binding var showingPermissions: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Connect with Apple Health")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Get personalized insights by connecting your health data")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingPermissions = true
            }) {
                Text("Connect to Health")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct HealthPermissionsSheet: View {
    @StateObject private var healthService = HealthKitService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("Health Data Access")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("FitTracker would like to access your health data to provide personalized insights and track your progress.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    PermissionRow(icon: "figure.walk", title: "Daily Activity", description: "Steps, distance, calories")
                    PermissionRow(icon: "heart.fill", title: "Heart Health", description: "Heart rate, HRV, VO2 Max")
                    PermissionRow(icon: "scalemass.fill", title: "Body Metrics", description: "Weight, body composition")
                    PermissionRow(icon: "bolt.fill", title: "Workouts", description: "Exercise sessions and intensity")
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await healthService.requestHealthKitAuthorization()
                            dismiss()
                        }
                    }) {
                        Text("Allow Access")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Health Access")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct TodayHealthStats: View {
    let healthData: HealthData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                HealthStatCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(healthData.todaySteps)",
                    subtitle: "steps",
                    color: .green
                )
                
                HealthStatCard(
                    icon: "location",
                    title: "Distance",
                    value: String(format: "%.1f", healthData.todayDistance),
                    subtitle: "km",
                    color: .blue
                )
                
                HealthStatCard(
                    icon: "flame",
                    title: "Calories",
                    value: "\(healthData.todayCalories)",
                    subtitle: "kcal",
                    color: .orange
                )
            }
        }
    }
}

struct HealthStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct WeeklyActivityChart: View {
    let healthData: HealthData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Activity Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            TabView {
                // Steps chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Steps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Chart(Array(healthData.weeklySteps.enumerated()), id: \.offset) { index, steps in
                        BarMark(
                            x: .value("Day", dayName(for: index)),
                            y: .value("Steps", steps)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 150)
                }
                .padding()
                
                // Distance chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Chart(Array(healthData.weeklyDistance.enumerated()), id: \.offset) { index, distance in
                        BarMark(
                            x: .value("Day", dayName(for: index)),
                            y: .value("Distance", distance)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 150)
                }
                .padding()
                
                // Calories chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Calories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Chart(Array(healthData.weeklyCalories.enumerated()), id: \.offset) { index, calories in
                        BarMark(
                            x: .value("Day", dayName(for: index)),
                            y: .value("Calories", calories)
                        )
                        .foregroundStyle(.orange)
                    }
                    .frame(height: 150)
                }
                .padding()
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func dayName(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let calendar = Calendar.current
        if let date = calendar.date(byAdding: .day, value: index - 6, to: Date()) {
            return formatter.string(from: date)
        }
        return "Day \(index + 1)"
    }
}

struct BodyMetricsSection: View {
    let healthData: HealthData
    @State private var showingBodyMetricsInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Body Metrics")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Update") {
                    showingBodyMetricsInput = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                if healthData.currentWeight > 0 {
                    MetricCard(
                        title: "Weight",
                        value: String(format: "%.1f kg", healthData.currentWeight),
                        icon: "scalemass",
                        color: .purple
                    )
                }
                
                if healthData.currentBodyFat > 0 {
                    MetricCard(
                        title: "Body Fat",
                        value: String(format: "%.1f%%", healthData.currentBodyFat),
                        icon: "percent",
                        color: .orange
                    )
                }
                
                if healthData.currentLeanMass > 0 {
                    MetricCard(
                        title: "Lean Mass",
                        value: String(format: "%.1f kg", healthData.currentLeanMass),
                        icon: "figure.strengthtraining.traditional",
                        color: .green
                    )
                }
                
                if healthData.height > 0 {
                    MetricCard(
                        title: "Height",
                        value: String(format: "%.0f cm", healthData.height),
                        icon: "ruler",
                        color: .blue
                    )
                }
            }
        }
        .sheet(isPresented: $showingBodyMetricsInput) {
            BodyMetricsInputSheet()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct HeartHealthSection: View {
    let healthData: HealthData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heart Health")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                if healthData.restingHeartRate > 0 {
                    MetricCard(
                        title: "Resting HR",
                        value: "\(healthData.restingHeartRate) bpm",
                        icon: "heart",
                        color: .red
                    )
                }
                
                if healthData.heartRateVariability > 0 {
                    MetricCard(
                        title: "HRV",
                        value: String(format: "%.0f ms", healthData.heartRateVariability),
                        icon: "waveform.path.ecg",
                        color: .pink
                    )
                }
                
                if healthData.vo2Max > 0 {
                    MetricCard(
                        title: "VO₂ Max",
                        value: String(format: "%.1f", healthData.vo2Max),
                        icon: "lungs",
                        color: .blue
                    )
                }
            }
            
            // Heart rate trend
            if !healthData.weeklyHeartRate.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Heart Rate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Chart(Array(healthData.weeklyHeartRate.enumerated()), id: \.offset) { index, hr in
                        LineMark(
                            x: .value("Day", dayName(for: index)),
                            y: .value("HR", hr)
                        )
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Day", dayName(for: index)),
                            y: .value("HR", hr)
                        )
                        .foregroundStyle(.red)
                    }
                    .frame(height: 100)
                    .chartYScale(domain: 60...85)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private func dayName(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let calendar = Calendar.current
        if let date = calendar.date(byAdding: .day, value: index - 6, to: Date()) {
            return formatter.string(from: date)
        }
        return "Day \(index + 1)"
    }
}

struct WorkoutInsightsSection: View {
    let healthData: HealthData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "This Week",
                    value: "\(healthData.weeklyWorkouts) workouts",
                    icon: "figure.strengthtraining.traditional",
                    color: .green
                )
                
                MetricCard(
                    title: "Total Time",
                    value: "\(healthData.totalWorkoutDuration) min",
                    icon: "timer",
                    color: .blue
                )
            }
            
            if healthData.averageWorkoutIntensity > 0 {
                MetricCard(
                    title: "Average Intensity",
                    value: String(format: "%.0f cal/workout", healthData.averageWorkoutIntensity),
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }
}

struct HealthRecommendations: View {
    let healthData: HealthData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Recommendations")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                RecommendationCard(
                    icon: "figure.walk",
                    title: "Daily Steps Goal",
                    description: healthData.todaySteps < 8000 ? 
                        "Try to reach 10,000 steps today for optimal health benefits." :
                        "Great job! You're on track with your daily activity.",
                    color: healthData.todaySteps < 8000 ? .orange : .green
                )
                
                RecommendationCard(
                    icon: "heart.fill",
                    title: "Heart Health",
                    description: healthData.restingHeartRate > 0 && healthData.restingHeartRate < 60 ?
                        "Excellent resting heart rate! Keep up the cardio training." :
                        "Consider adding more cardio exercises to improve heart health.",
                    color: .red
                )
                
                RecommendationCard(
                    icon: "bed.double.fill",
                    title: "Recovery",
                    description: "Ensure 7-9 hours of quality sleep for optimal recovery and performance.",
                    color: .purple
                )
            }
        }
    }
}

struct RecommendationCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct BodyMetricsInputSheet: View {
    @State private var weight: String = ""
    @State private var bodyFat: String = ""
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthService = HealthKitService.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Body Measurements") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Body Fat %")
                        Spacer()
                        TextField("%", text: $bodyFat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Save to Health") {
                        Task {
                            if let weightValue = Double(weight) {
                                await healthService.saveBodyWeight(weightValue)
                            }
                            if let bodyFatValue = Double(bodyFat) {
                                await healthService.saveBodyFatPercentage(bodyFatValue)
                            }
                            dismiss()
                        }
                    }
                    .disabled(weight.isEmpty && bodyFat.isEmpty)
                }
            }
            .navigationTitle("Update Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Health Data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    HealthView()
}