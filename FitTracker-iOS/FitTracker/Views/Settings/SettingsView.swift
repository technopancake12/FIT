import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var showingDataManagement = false
    @State private var showingExportView = false
    @State private var showingImportView = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(firebaseManager.currentUser?.displayName ?? "Unknown User")
                                .font(.headline)
                            
                            Text(firebaseManager.currentUser?.email ?? "No email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Data Management") {
                    NavigationLink(destination: DataExportView()) {
                        SettingsRowView(
                            icon: "square.and.arrow.down",
                            title: "Export Data",
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: DataImportView()) {
                        SettingsRowView(
                            icon: "square.and.arrow.up",
                            title: "Import Data",
                            color: .green
                        )
                    }
                    
                    NavigationLink(destination: DataManagementView()) {
                        SettingsRowView(
                            icon: "externaldrive",
                            title: "Data Management",
                            color: .orange
                        )
                    }
                }
                
                Section("Analytics") {
                    NavigationLink(destination: AnalyticsView()) {
                        SettingsRowView(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Detailed Analytics",
                            color: .blue
                        )
                    }
                }
                
                Section("Preferences") {
                    SettingsRowView(
                        icon: "bell",
                        title: "Notifications",
                        color: .red
                    )
                    
                    SettingsRowView(
                        icon: "moon",
                        title: "Dark Mode",
                        color: .indigo
                    )
                    
                    SettingsRowView(
                        icon: "globe",
                        title: "Language",
                        color: .green
                    )
                }
                
                Section("About") {
                    SettingsRowView(
                        icon: "info.circle",
                        title: "App Info",
                        color: .blue
                    )
                    
                    SettingsRowView(
                        icon: "doc.text",
                        title: "Privacy Policy",
                        color: .purple
                    )
                    
                    SettingsRowView(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        color: .orange
                    )
                }
                
                Section {
                    Button(action: {
                        firebaseManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView()
        .environmentObject(FirebaseManager.shared)
}