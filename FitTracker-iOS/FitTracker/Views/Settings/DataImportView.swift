import SwiftUI
import UniformTypeIdentifiers

struct DataImportView: View {
    @StateObject private var importService = DataImportService.shared
    @State private var showingFilePicker = false
    @State private var showingImportSummary = false
    @State private var showingErrorAlert = false
    @State private var showingConfirmationAlert = false
    @State private var selectedFileURL: URL?
    @State private var importFileType: ImportFileType?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Import Your Data")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Restore your FitTracker data from a backup file or import data from supported formats like CSV or JSON.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    // Import from File Button
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.blue)
                            
                            Text("Choose File to Import")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(importService.isImporting)
                } header: {
                    Text("Import Actions")
                }
                
                // Import Progress
                if importService.isImporting {
                    Section("Import Progress") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Importing data...")
                                Spacer()
                                Text("\(Int(importService.importProgress * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: importService.importProgress)
                                .tint(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    SupportedFormatRow(
                        title: "FitTracker Backup",
                        description: "Complete backup files (.json)",
                        icon: "externaldrive",
                        color: .green
                    )
                    
                    SupportedFormatRow(
                        title: "JSON Export",
                        description: "Full data exports in JSON format",
                        icon: "doc.text",
                        color: .blue
                    )
                    
                    SupportedFormatRow(
                        title: "CSV Files",
                        description: "Workout or nutrition data in CSV format",
                        icon: "tablecells",
                        color: .orange
                    )
                } header: {
                    Text("Supported Formats")
                } footer: {
                    Text("Choose files exported from FitTracker or compatible fitness apps.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        WarningRow(
                            icon: "exclamationmark.triangle",
                            title: "Data Merging",
                            description: "Imported data will be merged with your existing data. Duplicates may occur."
                        )
                        
                        WarningRow(
                            icon: "clock.arrow.circlepath",
                            title: "Large Files",
                            description: "Importing large datasets may take several minutes to complete."
                        )
                        
                        WarningRow(
                            icon: "wifi.slash",
                            title: "Internet Required",
                            description: "An internet connection is required to sync imported data."
                        )
                    }
                } header: {
                    Text("Important Notes")
                }
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [
                    UTType.json,
                    UTType.commaSeparatedText,
                    UTType(filenameExtension: "backup") ?? UTType.data
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Error", isPresented: $showingErrorAlert) {
                Button("OK") { 
                    importService.clearImportState()
                }
            } message: {
                Text(importService.importError ?? "An unknown error occurred")
            }
            .alert("Import Complete", isPresented: $showingImportSummary) {
                Button("OK") { 
                    importService.clearImportState()
                }
            } message: {
                if let summary = importService.importSummary {
                    Text(generateSummaryMessage(summary))
                }
            }
            .alert("Confirm Import", isPresented: $showingConfirmationAlert) {
                Button("Cancel", role: .cancel) {
                    selectedFileURL = nil
                    importFileType = nil
                }
                Button("Import") {
                    performImport()
                }
            } message: {
                if let fileType = importFileType {
                    Text("Are you sure you want to import this \(fileType.displayName)? This action cannot be undone.")
                }
            }
        }
        .onChange(of: importService.importError) { error in
            if error != nil {
                showingErrorAlert = true
            }
        }
        .onChange(of: importService.importSummary) { summary in
            if summary != nil {
                showingImportSummary = true
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importService.importError = "Unable to access the selected file"
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let fileType = importService.validateImportFile(url: url) {
                selectedFileURL = url
                importFileType = fileType
                showingConfirmationAlert = true
            } else {
                importService.importError = "Unsupported file format. Please select a JSON, CSV, or backup file."
            }
            
        case .failure(let error):
            importService.importError = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    private func performImport() {
        guard let fileURL = selectedFileURL,
              let fileType = importFileType else { return }
        
        Task {
            do {
                switch fileType {
                case .backup:
                    try await importService.importFromBackup(fileURL: fileURL)
                case .json:
                    try await importService.importFromJSON(fileURL: fileURL)
                case .csv:
                    // Determine if it's workout or nutrition CSV based on content
                    try await importService.importWorkoutsFromCSV(fileURL: fileURL)
                }
            } catch {
                print("Import failed: \(error)")
            }
        }
        
        selectedFileURL = nil
        importFileType = nil
    }
    
    private func generateSummaryMessage(_ summary: ImportSummary) -> String {
        var message = "Successfully imported \(summary.totalItemsImported) items:\n\n"
        
        if summary.workoutsImported > 0 {
            message += "• \(summary.workoutsImported) workouts\n"
        }
        if summary.nutritionLogsImported > 0 {
            message += "• \(summary.nutritionLogsImported) nutrition logs\n"
        }
        if summary.goalsImported > 0 {
            message += "• \(summary.goalsImported) goals\n"
        }
        if summary.achievementsImported > 0 {
            message += "• \(summary.achievementsImported) achievements\n"
        }
        if summary.templatesImported > 0 {
            message += "• \(summary.templatesImported) templates\n"
        }
        
        return message
    }
}

struct SupportedFormatRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
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
        .padding(.vertical, 2)
    }
}

struct WarningRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    DataImportView()
}