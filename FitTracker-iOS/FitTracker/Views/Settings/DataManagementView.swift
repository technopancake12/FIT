import SwiftUI

struct DataManagementView: View {
    @State private var showingExportView = false
    @State private var showingImportView = false
    @State private var showingClearDataAlert = false
    @State private var dataToDelete: DataType?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "externaldrive.connected.to.line.below")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Data Management")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Export your data for backup, import previous data, or manage your stored information.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Backup & Export") {
                    NavigationLink(destination: DataExportView()) {
                        SettingsRow(
                            icon: "arrow.down.doc",
                            title: "Export Data",
                            description: "Create backups or export in various formats",
                            color: .blue
                        )
                    }
                    
                    QuickExportButton(
                        title: "Quick Backup",
                        subtitle: "Create a complete backup",
                        icon: "externaldrive",
                        color: .green
                    ) {
                        createQuickBackup()
                    }
                }
                
                Section("Import & Restore") {
                    NavigationLink(destination: DataImportView()) {
                        SettingsRow(
                            icon: "arrow.up.doc",
                            title: "Import Data",
                            description: "Restore from backup or import external data",
                            color: .orange
                        )
                    }
                }
                
                Section("Storage Information") {
                    StorageInfoRow(
                        title: "Workouts",
                        count: getWorkoutCount(),
                        icon: "dumbbell",
                        color: .blue
                    )
                    
                    StorageInfoRow(
                        title: "Nutrition Logs",
                        count: getNutritionLogCount(),
                        icon: "fork.knife",
                        color: .green
                    )
                    
                    StorageInfoRow(
                        title: "Achievements",
                        count: getAchievementCount(),
                        icon: "trophy",
                        color: .yellow
                    )
                    
                    StorageInfoRow(
                        title: "Templates",
                        count: getTemplateCount(),
                        icon: "doc.text",
                        color: .purple
                    )
                }
                
                Section("Data Cleanup") {
                    Button(action: { clearData(.oldWorkouts) }) {
                        SettingsRow(
                            icon: "trash",
                            title: "Clear Old Workouts",
                            description: "Remove workouts older than 1 year",
                            color: .orange
                        )
                    }
                    
                    Button(action: { clearData(.nutritionHistory) }) {
                        SettingsRow(
                            icon: "trash",
                            title: "Clear Nutrition History",
                            description: "Remove nutrition logs older than 6 months",
                            color: .orange
                        )
                    }
                    
                    Button(action: { clearData(.analytics) }) {
                        SettingsRow(
                            icon: "trash",
                            title: "Reset Analytics",
                            description: "Clear all analytics and progress data",
                            color: .red
                        )
                    }
                } footer: {
                    Text("Clearing data cannot be undone. Consider creating a backup first.")
                }
                
                Section("Advanced") {
                    NavigationLink(destination: SyncStatusView()) {
                        SettingsRow(
                            icon: "icloud.and.arrow.up",
                            title: "Sync Status",
                            description: "View cloud synchronization status",
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: DataUsageView()) {
                        SettingsRow(
                            icon: "chart.pie",
                            title: "Storage Usage",
                            description: "See detailed storage breakdown",
                            color: .indigo
                        )
                    }
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) {
                    dataToDelete = nil
                }
                Button("Clear", role: .destructive) {
                    if let dataType = dataToDelete {
                        performDataClear(dataType)
                    }
                }
            } message: {
                if let dataType = dataToDelete {
                    Text("Are you sure you want to clear \(dataType.displayName)? This action cannot be undone.")
                }
            }
        }
    }
    
    private func clearData(_ type: DataType) {
        dataToDelete = type
        showingClearDataAlert = true
    }
    
    private func performDataClear(_ type: DataType) {
        Task {
            do {
                switch type {
                case .oldWorkouts:
                    try await FirebaseManager.shared.clearOldWorkouts()
                case .nutritionHistory:
                    try await FirebaseManager.shared.clearOldNutritionLogs()
                case .analytics:
                    try await AnalyticsService.shared.resetAnalytics()
                }
            } catch {
                print("Failed to clear data: \(error)")
            }
        }
        dataToDelete = nil
    }
    
    private func createQuickBackup() {
        Task {
            do {
                let backupURL = try await DataExportService.shared.createBackup()
                // Show share sheet for quick backup
                await MainActor.run {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        DataExportService.shared.shareFile(url: backupURL, from: rootVC)
                    }
                }
            } catch {
                print("Quick backup failed: \(error)")
            }
        }
    }
    
    // MARK: - Data Count Methods
    
    private func getWorkoutCount() -> Int {
        // This would fetch actual count from Firebase/Core Data
        return 47
    }
    
    private func getNutritionLogCount() -> Int {
        return 156
    }
    
    private func getAchievementCount() -> Int {
        return 12
    }
    
    private func getTemplateCount() -> Int {
        return 8
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            
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
        .padding(.vertical, 4)
    }
}

struct QuickExportButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StorageInfoRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

enum DataType {
    case oldWorkouts
    case nutritionHistory
    case analytics
    
    var displayName: String {
        switch self {
        case .oldWorkouts: return "old workouts"
        case .nutritionHistory: return "nutrition history"
        case .analytics: return "analytics data"
        }
    }
}

// MARK: - Placeholder Views

struct SyncStatusView: View {
    var body: some View {
        List {
            Section("Sync Status") {
                SyncStatusRow(service: "Workouts", status: .synced, lastSync: Date())
                SyncStatusRow(service: "Nutrition", status: .syncing, lastSync: Date())
                SyncStatusRow(service: "Analytics", status: .error, lastSync: Date())
                SyncStatusRow(service: "Templates", status: .synced, lastSync: Date())
            }
            
            Section("Actions") {
                Button("Force Sync All") {
                    // Force sync implementation
                }
                
                Button("Reset Sync State") {
                    // Reset sync state implementation
                }
            }
        }
        .navigationTitle("Sync Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SyncStatusRow: View {
    let service: String
    let status: SyncStatus
    let lastSync: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(service)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Last sync: \(lastSync.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
                
                Text(status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(status.color)
            }
        }
        .padding(.vertical, 2)
    }
}

enum SyncStatus {
    case synced
    case syncing
    case error
    
    var displayName: String {
        switch self {
        case .synced: return "Synced"
        case .syncing: return "Syncing"
        case .error: return "Error"
        }
    }
    
    var icon: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .synced: return .green
        case .syncing: return .blue
        case .error: return .red
        }
    }
}

struct DataUsageView: View {
    var body: some View {
        List {
            Section("Storage Breakdown") {
                UsageRow(category: "Workouts", size: "2.3 MB", percentage: 0.4)
                UsageRow(category: "Nutrition", size: "1.8 MB", percentage: 0.3)
                UsageRow(category: "Analytics", size: "0.9 MB", percentage: 0.15)
                UsageRow(category: "Templates", size: "0.5 MB", percentage: 0.1)
                UsageRow(category: "Other", size: "0.3 MB", percentage: 0.05)
            }
            
            Section("Total Usage") {
                HStack {
                    Text("Total Storage Used")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("5.8 MB")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Storage Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UsageRow: View {
    let category: String
    let size: String
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(size)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: percentage)
                .tint(.blue)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Extensions

extension FirebaseManager {
    func clearOldWorkouts() async throws {
        // Implementation would clear workouts older than 1 year
    }
    
    func clearOldNutritionLogs() async throws {
        // Implementation would clear nutrition logs older than 6 months
    }
}

extension AnalyticsService {
    func resetAnalytics() async throws {
        // Implementation would reset all analytics data
    }
}

#Preview {
    DataManagementView()
}