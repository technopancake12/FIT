import SwiftUI

struct FocusModeView: View {
    @Binding var isActive: Bool
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = FocusModeViewModel()
    
    var body: some View {
        NavigationView {
            if isActive {
                activeFocusModeView
            } else {
                focusModeSetupView
            }
        }
    }
    
    private var activeFocusModeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Timer Card
                timerCard
                
                // Active Restrictions
                activeRestrictionsCard
                
                // Session Progress
                sessionProgressCard
                
                // Motivational Message
                motivationalCard
            }
            .padding()
        }
        .navigationTitle("Focus Mode")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Exit Focus") {
                    viewModel.endFocusSession()
                    isActive = false
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
            }
        }
        .onAppear {
            viewModel.startFocusSession()
        }
    }
    
    private var focusModeSetupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                settingsView
                startButtonView
            }
            .padding()
        }
        .navigationTitle("Enter Focus Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Enter Focus Mode")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Block distractions and stay focused on your workout")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Settings")
                .font(.headline)
            
            VStack(spacing: 12) {
                SettingToggle(
                    icon: "bell.slash",
                    title: "Block notifications",
                    isOn: $viewModel.blockNotifications
                )
                
                SettingToggle(
                    icon: "eye.slash",
                    title: "Hide non-essential UI",
                    isOn: $viewModel.hideNonEssential
                )
                
                SettingToggle(
                    icon: "speaker.slash",
                    title: "Silent mode",
                    isOn: $viewModel.silentMode
                )
                
                SettingToggle(
                    icon: "sun.max",
                    title: "Keep screen on",
                    isOn: $viewModel.preventScreenOff
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var startButtonView: some View {
        Button(action: {
            isActive = true
        }) {
            HStack {
                Image(systemName: "shield.fill")
                Text("Start Focus Session (\(Int(viewModel.workoutDuration / 60)) minutes)")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline)
        }
    }
    
    private var timerCard: some View {
        VStack(spacing: 16) {
            Text(viewModel.formattedTimeRemaining)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            
            Text("Time remaining in focus session")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 6)
            
            HStack {
                Button(action: viewModel.togglePause) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    Text(viewModel.isPaused ? "Resume" : "Pause")
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var activeRestrictionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Restrictions")
                .font(.headline)
            Text("Features blocked during focus mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                if viewModel.blockNotifications {
                    RestrictionItem(
                        icon: "bell.slash",
                        iconColor: .orange,
                        title: "Notifications Blocked",
                        description: "Only workout alerts allowed"
                    )
                }
                
                if viewModel.hideNonEssential {
                    RestrictionItem(
                        icon: "eye.slash",
                        iconColor: .blue,
                        title: "Simplified Interface",
                        description: "Non-essential elements hidden"
                    )
                }
                
                if viewModel.silentMode {
                    RestrictionItem(
                        icon: "speaker.slash",
                        iconColor: .purple,
                        title: "Silent Mode",
                        description: "Only workout sounds enabled"
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var sessionProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Progress")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack {
                    Text("\(Int(viewModel.elapsedMinutes))m")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Time Elapsed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(Int(viewModel.progressPercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Session Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var motivationalCard: some View {
        VStack(spacing: 8) {
            Text("Stay Focused! 💪")
                .font(.title3)
                .fontWeight(.bold)
            Text("You're in the zone. Keep pushing towards your fitness goals!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SettingToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
    }
}

struct RestrictionItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
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
            
            Text("ACTIVE")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

class FocusModeViewModel: ObservableObject {
    @Published var blockNotifications = true
    @Published var hideNonEssential = true
    @Published var silentMode = true
    @Published var preventScreenOff = true
    
    @Published var timeRemaining: TimeInterval = 3600 // 60 minutes
    @Published var isPaused = false
    
    let workoutDuration: TimeInterval = 3600
    private var timer: Timer?
    private var startTime: Date?
    
    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining) % 3600 / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var progressPercentage: Double {
        (workoutDuration - timeRemaining) / workoutDuration
    }
    
    var elapsedMinutes: Double {
        (workoutDuration - timeRemaining) / 60
    }
    
    func startFocusSession() {
        startTime = Date()
        startTimer()
        
        // iOS-specific focus mode setup
        UIApplication.shared.isIdleTimerDisabled = preventScreenOff
    }
    
    func endFocusSession() {
        stopTimer()
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Show completion notification
        scheduleCompletionNotification()
    }
    
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.endFocusSession()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scheduleCompletionNotification() {
        // Schedule local notification for completion
        // This would use UNUserNotificationCenter in a real app
    }
}

#Preview {
    FocusModeView(isActive: .constant(false))
}