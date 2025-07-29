import SwiftUI

struct DataExportView: View {
    @StateObject private var exportService = DataExportService.shared
    @State private var selectedFormat: ExportFormat = .json
    @State private var selectedExportType: ExportType = .allData
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Export Your Data")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Export your fitness data to keep a backup or transfer to another device")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Export Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What to Export")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(ExportType.allCases, id: \.self) { type in
                                ExportTypeCard(
                                    type: type,
                                    isSelected: selectedExportType == type
                                ) {
                                    selectedExportType = type
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Format Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Format")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                FormatButton(
                                    format: format,
                                    isSelected: selectedFormat == format
                                ) {
                                    selectedFormat = format
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Export Progress
                    if exportService.isExporting {
                        VStack(spacing: 12) {
                            ProgressView(value: exportService.exportProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            Text("Exporting... \(Int(exportService.exportProgress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Export Button
                    Button(action: performExport) {
                        HStack {
                            if exportService.isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                            }
                            
                            Text(exportService.isExporting ? "Exporting..." : "Export Data")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(exportService.isExporting)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            InfoRow(icon: "shield.checkered", title: "Secure", description: "Your data is encrypted during export")
                            InfoRow(icon: "icloud", title: "Backup Ready", description: "Files can be saved to iCloud or shared")
                            InfoRow(icon: "doc.text", title: "Multiple Formats", description: "Choose JSON, CSV, or Excel format")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ExportShareSheet(items: [url])
            }
        }
        .alert("Export Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: exportService.exportError) { error in
            if let error = error {
                alertMessage = "Export failed: \(error)"
                showingAlert = true
            }
        }
    }
    
    private func performExport() {
        Task {
            do {
                let fileURL: URL
                
                switch selectedExportType {
                case .allData:
                    fileURL = try await exportService.exportAllData(format: selectedFormat)
                case .workouts:
                    fileURL = try await exportService.exportWorkoutData(format: selectedFormat)
                case .nutrition:
                    fileURL = try await exportService.exportNutritionData(format: selectedFormat)
                case .analytics:
                    fileURL = try await exportService.exportAnalyticsData(format: selectedFormat)
                case .backup:
                    fileURL = try await exportService.createBackup()
                }
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    showingShareSheet = true
                    alertMessage = "Export completed successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Export failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Export Type Card
struct ExportTypeCard: View {
    let type: ExportType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let format: ExportFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(format.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Share Sheet
struct ExportShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Types
enum ExportType: CaseIterable {
    case allData
    case workouts
    case nutrition
    case analytics
    case backup
    
    var title: String {
        switch self {
        case .allData: return "All Data"
        case .workouts: return "Workouts Only"
        case .nutrition: return "Nutrition Only"
        case .analytics: return "Analytics Only"
        case .backup: return "Complete Backup"
        }
    }
    
    var description: String {
        switch self {
        case .allData: return "Export all your fitness data including workouts, nutrition, and analytics"
        case .workouts: return "Export only your workout history and exercise data"
        case .nutrition: return "Export only your nutrition logs and meal data"
        case .analytics: return "Export only your progress and analytics data"
        case .backup: return "Create a complete backup including user profile and settings"
        }
    }
    
    var icon: String {
        switch self {
        case .allData: return "doc.text.fill"
        case .workouts: return "dumbbell.fill"
        case .nutrition: return "fork.knife"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .backup: return "externaldrive.fill"
        }
    }
}

extension ExportFormat {
    var icon: String {
        switch self {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .xlsx: return "doc.richtext"
        }
    }
}

#Preview {
    DataExportView()
}