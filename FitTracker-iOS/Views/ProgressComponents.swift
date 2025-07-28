import SwiftUI
import Charts

struct WorkoutFrequencyChart: View {
    let data: [WorkoutFrequencyData]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Frequency")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data, id: \.date) { item in
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Workouts", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Workouts", item.count)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .frame(height: 200)
            .chartYScale(domain: 0...2)
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange == .week ? .day : .weekOfYear)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 1, 2]) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct VolumeChart: View {
    let data: [VolumeData]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Volume")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.volume)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.volume)
                )
                .foregroundStyle(.green)
                .symbolSize(30)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange == .week ? .day : .weekOfYear)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel { value in
                        Text("\(Int(value.as(Double.self) ?? 0))kg")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StrengthProgressChart: View {
    let data: [StrengthData]
    let selectedExercise: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            if data.isEmpty {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No strength data available")
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
            } else {
                Chart(data, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Weight", item.weight)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Weight", item.weight)
                    )
                    .foregroundStyle(.orange)
                    .symbolSize(40)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel { value in
                            Text("\(Int(value.as(Double.self) ?? 0))kg")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct NutritionChart: View {
    let data: [NutritionProgressData]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data, id: \.date) { item in
                // Calories line
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Calories", item.calories)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // Protein bars
                BarMark(
                    x: .value("Date", item.date),
                    y: .value("Protein", item.protein * 4) // Convert to calories
                )
                .foregroundStyle(.blue.opacity(0.7))
                .position(by: .value("Macro", "Protein"))
            }
            .frame(height: 200)
            .chartForegroundStyleScale([
                "Calories": .red,
                "Protein": .blue,
                "Carbs": .green,
                "Fat": .yellow
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange == .week ? .day : .weekOfYear)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MacroDistributionChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    
    private var total: Double {
        protein + carbs + fat
    }
    
    private var macroData: [(name: String, value: Double, color: Color)] {
        [
            ("Protein", protein, .blue),
            ("Carbs", carbs, .green),
            ("Fat", fat, .yellow)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Distribution")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Pie chart using Chart framework
                Chart(macroData, id: \.name) { item in
                    SectorMark(
                        angle: .value("Grams", item.value),
                        innerRadius: .ratio(0.4),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .opacity(0.8)
                }
                .frame(width: 120, height: 120)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(macroData, id: \.name) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(Int(item.value))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct BodyStatsChart: View {
    let data: [BodyStatsData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Composition")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Weight", item.weight)
                )
                .foregroundStyle(.purple)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                if let bodyFat = item.bodyFat {
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Body Fat", bodyFat)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                }
            }
            .frame(height: 200)
            .chartForegroundStyleScale([
                "Weight": .purple,
                "Body Fat": .orange
            ])
            .chartXAxis {
                AxisMarks {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PersonalRecordsView: View {
    let records: [PersonalRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
                .foregroundColor(.primary)
            
            if records.isEmpty {
                VStack {
                    Image(systemName: "trophy")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No personal records yet")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(records.prefix(5), id: \.id) { record in
                        PersonalRecordRow(record: record)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PersonalRecordRow: View {
    let record: PersonalRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if record.weight > 0 {
                    Text("\(Int(record.weight))kg")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text("\(record.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "trophy.fill")
                .foregroundColor(.yellow)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

struct ExerciseSelector: View {
    @Binding var selectedExercise: String
    let exercises: [String]
    
    var body: some View {
        Menu {
            ForEach(exercises, id: \.self) { exercise in
                Button(exercise) {
                    selectedExercise = exercise
                }
            }
        } label: {
            HStack {
                Text(selectedExercise)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

struct ProgressStatsOverview: View {
    let weeklyStats: (workouts: Int, volume: Int, avgDuration: Int)
    let streakData: (current: Int, longest: Int)
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "This Week",
                value: "\(weeklyStats.workouts)",
                subtitle: "workouts",
                icon: "calendar.badge.clock",
                color: .blue
            )
            
            StatCard(
                title: "Total Volume",
                value: "\(weeklyStats.volume / 1000)k",
                subtitle: "kg lifted",
                icon: "scalemass",
                color: .green
            )
            
            StatCard(
                title: "Current Streak",
                value: "\(streakData.current)",
                subtitle: "days",
                icon: "flame",
                color: .orange
            )
            
            StatCard(
                title: "Avg Duration",
                value: "\(weeklyStats.avgDuration)",
                subtitle: "minutes",
                icon: "timer",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
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