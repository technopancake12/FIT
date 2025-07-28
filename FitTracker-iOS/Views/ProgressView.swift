import SwiftUI

struct ProgressView: View {
    @StateObject private var progressService = ProgressService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress & Analytics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track your fitness journey with detailed insights")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Time range selector
                    TimeRangeSelector(selectedRange: $progressService.selectedTimeRange)
                        .onChange(of: progressService.selectedTimeRange) { newValue in
                            progressService.updateTimeRange(newValue)
                        }
                    
                    // Quick stats overview
                    ProgressStatsOverview(
                        weeklyStats: progressService.getWeeklyStats(),
                        streakData: progressService.getWorkoutStreakData()
                    )
                    
                    // Exercise selector for strength chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercise Filter")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ExerciseSelector(
                            selectedExercise: $progressService.selectedExercise,
                            exercises: ["All Exercises", "Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull-ups"]
                        )
                        .onChange(of: progressService.selectedExercise) { newValue in
                            progressService.updateSelectedExercise(newValue)
                        }
                    }
                    
                    // Charts section
                    VStack(spacing: 20) {
                        WorkoutFrequencyChart(
                            data: progressService.workoutFrequencyData,
                            timeRange: progressService.selectedTimeRange
                        )
                        .padding(.horizontal)
                        
                        VolumeChart(
                            data: progressService.volumeData,
                            timeRange: progressService.selectedTimeRange
                        )
                        .padding(.horizontal)
                        
                        StrengthProgressChart(
                            data: progressService.strengthData,
                            selectedExercise: progressService.selectedExercise
                        )
                        .padding(.horizontal)
                        
                        // Nutrition charts in a horizontal scroll
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition Analytics")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    NutritionChart(
                                        data: progressService.nutritionData,
                                        timeRange: progressService.selectedTimeRange
                                    )
                                    .frame(width: 300)
                                    
                                    MacroDistributionChart(
                                        protein: progressService.getMacroTrends().protein,
                                        carbs: progressService.getMacroTrends().carbs,
                                        fat: progressService.getMacroTrends().fat
                                    )
                                    .frame(width: 250)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        BodyStatsChart(data: progressService.bodyStatsData)
                            .padding(.horizontal)
                        
                        PersonalRecordsView(records: progressService.personalRecords)
                            .padding(.horizontal)
                    }
                    
                    // Insights section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Insights & Recommendations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            InsightCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Consistency Improvement",
                                description: "You've worked out 4 times this week! Try to maintain this consistency.",
                                color: .green
                            )
                            
                            InsightCard(
                                icon: "scalemass",
                                title: "Volume Progress",
                                description: "Your training volume has increased 15% this month. Great progressive overload!",
                                color: .blue
                            )
                            
                            InsightCard(
                                icon: "heart.fill",
                                title: "Recovery Reminder",
                                description: "Consider taking a rest day soon to optimize recovery and prevent overtraining.",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct InsightCard: View {
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

#Preview {
    ProgressView()
}