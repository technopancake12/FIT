import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var userProfile = OnboardingUserProfile()
    @State private var showingSignUp = false
    @Environment(\.dismiss) private var dismiss
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressView(currentPage: currentPage, totalPages: pages.count)
                    .padding(.top, 20)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(
                            page: page,
                            userProfile: $userProfile,
                            onNext: { moveToNextPage() },
                            onSkip: { skipToEnd() }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Navigation buttons
                OnboardingNavigationView(
                    currentPage: currentPage,
                    totalPages: pages.count,
                    onPrevious: { moveToPreviousPage() },
                    onNext: { moveToNextPage() },
                    onGetStarted: { completeOnboarding() }
                )
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView(userProfile: userProfile) {
                completeOnboarding()
            }
        }
    }
    
    private func moveToNextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        } else {
            completeOnboarding()
        }
    }
    
    private func moveToPreviousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    private func skipToEnd() {
        currentPage = pages.count - 1
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Show sign up if not already authenticated
        if !userProfile.isAuthenticated {
            showingSignUp = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Progress View
struct OnboardingProgressView: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 30 : 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var userProfile: OnboardingUserProfile
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                // Image/Icon
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                // Title and Description
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Interactive content based on page type
                switch page.type {
                case .welcome:
                    WelcomeContentView()
                case .fitnessGoals:
                    FitnessGoalsSelectionView(userProfile: $userProfile)
                case .experienceLevel:
                    ExperienceLevelSelectionView(userProfile: $userProfile)
                case .workoutPreferences:
                    WorkoutPreferencesView(userProfile: $userProfile)
                case .features:
                    FeaturesHighlightView()
                case .permissions:
                    PermissionsRequestView()
                case .getStarted:
                    GetStartedView()
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Navigation View
struct OnboardingNavigationView: View {
    let currentPage: Int
    let totalPages: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onGetStarted: () -> Void
    
    var body: some View {
        HStack {
            // Back button
            if currentPage > 0 {
                Button("Back") {
                    onPrevious()
                }
                .foregroundColor(.blue)
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Next/Get Started button
            Button(action: {
                if currentPage == totalPages - 1 {
                    onGetStarted()
                } else {
                    onNext()
                }
            }) {
                Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 50)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Welcome Content
struct WelcomeContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                FeatureRow(icon: "dumbbell", title: "Track Workouts", description: "Log exercises, sets, and reps")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "View Progress", description: "Monitor your fitness journey")
                FeatureRow(icon: "person.2", title: "Social Features", description: "Connect with fitness friends")
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Fitness Goals Selection
struct FitnessGoalsSelectionView: View {
    @Binding var userProfile: OnboardingUserProfile
    
    private let goals = [
        FitnessGoalOption(id: "lose_weight", title: "Lose Weight", icon: "figure.walk", description: "Burn calories and reduce body fat"),
        FitnessGoalOption(id: "build_muscle", title: "Build Muscle", icon: "figure.strengthtraining.traditional", description: "Increase muscle mass and strength"),
        FitnessGoalOption(id: "get_stronger", title: "Get Stronger", icon: "dumbbell", description: "Improve overall strength"),
        FitnessGoalOption(id: "improve_endurance", title: "Improve Endurance", icon: "figure.run", description: "Boost cardiovascular fitness"),
        FitnessGoalOption(id: "general_fitness", title: "General Fitness", icon: "heart", description: "Overall health and wellness"),
        FitnessGoalOption(id: "athletic_performance", title: "Athletic Performance", icon: "sportscourt", description: "Enhance sports performance")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("What are your fitness goals?")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            Text("Select all that apply")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(goals) { goal in
                    GoalSelectionCard(
                        goal: goal,
                        isSelected: userProfile.selectedGoals.contains(goal.id)
                    ) {
                        toggleGoal(goal.id)
                    }
                }
            }
        }
    }
    
    private func toggleGoal(_ goalId: String) {
        if userProfile.selectedGoals.contains(goalId) {
            userProfile.selectedGoals.remove(goalId)
        } else {
            userProfile.selectedGoals.insert(goalId)
        }
    }
}

struct GoalSelectionCard: View {
    let goal: FitnessGoalOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                VStack(spacing: 4) {
                    Text(goal.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.center)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Experience Level Selection
struct ExperienceLevelSelectionView: View {
    @Binding var userProfile: OnboardingUserProfile
    
    private let levels = [
        ExperienceLevel(id: "beginner", title: "Beginner", description: "New to fitness", icon: "tortoise"),
        ExperienceLevel(id: "intermediate", title: "Intermediate", description: "Some experience", icon: "figure.walk"),
        ExperienceLevel(id: "advanced", title: "Advanced", description: "Very experienced", icon: "hare")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your experience level?")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(levels) { level in
                    ExperienceLevelCard(
                        level: level,
                        isSelected: userProfile.experienceLevel == level.id
                    ) {
                        userProfile.experienceLevel = level.id
                    }
                }
            }
        }
    }
}

struct ExperienceLevelCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(level.description)
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
            .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Preferences
struct WorkoutPreferencesView: View {
    @Binding var userProfile: OnboardingUserProfile
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Workout Preferences")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Workout frequency
                PreferenceSection(title: "How often do you want to work out?") {
                    WorkoutFrequencySelector(selectedFrequency: $userProfile.workoutFrequency)
                }
                
                // Preferred workout types
                PreferenceSection(title: "Preferred workout types:") {
                    WorkoutTypeSelector(selectedTypes: $userProfile.preferredWorkoutTypes)
                }
                
                // Equipment access
                PreferenceSection(title: "What equipment do you have access to?") {
                    EquipmentSelector(selectedEquipment: $userProfile.availableEquipment)
                }
            }
        }
    }
}

struct PreferenceSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            content()
        }
    }
}

struct WorkoutFrequencySelector: View {
    @Binding var selectedFrequency: String
    
    private let frequencies = [
        ("1-2", "1-2 times per week"),
        ("3-4", "3-4 times per week"),
        ("5-6", "5-6 times per week"),
        ("daily", "Daily")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(frequencies, id: \.0) { frequency in
                Button(action: { selectedFrequency = frequency.0 }) {
                    HStack {
                        Text(frequency.1)
                            .foregroundColor(selectedFrequency == frequency.0 ? .white : .primary)
                        
                        Spacer()
                        
                        if selectedFrequency == frequency.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(selectedFrequency == frequency.0 ? Color.blue : Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct WorkoutTypeSelector: View {
    @Binding var selectedTypes: Set<String>
    
    private let workoutTypes = [
        ("strength", "Strength Training"),
        ("cardio", "Cardio"),
        ("yoga", "Yoga"),
        ("hiit", "HIIT"),
        ("sports", "Sports")
    ]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(workoutTypes, id: \.0) { type in
                Button(action: { toggleWorkoutType(type.0) }) {
                    Text(type.1)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTypes.contains(type.0) ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTypes.contains(type.0) ? Color.blue : Color(UIColor.systemGray6))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func toggleWorkoutType(_ type: String) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
}

struct EquipmentSelector: View {
    @Binding var selectedEquipment: Set<String>
    
    private let equipment = [
        ("gym", "Full Gym"),
        ("home_gym", "Home Gym"),
        ("dumbbells", "Dumbbells"),
        ("bodyweight", "Bodyweight Only"),
        ("resistance_bands", "Resistance Bands")
    ]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(equipment, id: \.0) { item in
                Button(action: { toggleEquipment(item.0) }) {
                    Text(item.1)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedEquipment.contains(item.0) ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedEquipment.contains(item.0) ? Color.blue : Color(UIColor.systemGray6))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func toggleEquipment(_ equipment: String) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }
}

// MARK: - Features Highlight
struct FeaturesHighlightView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Features you'll love")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                FeatureHighlightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Tracking",
                    description: "Visualize your fitness journey with detailed analytics"
                )
                
                FeatureHighlightCard(
                    icon: "person.2.fill",
                    title: "Social Features",
                    description: "Share workouts and connect with friends"
                )
                
                FeatureHighlightCard(
                    icon: "doc.text.fill",
                    title: "Workout Templates",
                    description: "Use proven workout plans or create your own"
                )
                
                FeatureHighlightCard(
                    icon: "trophy.fill",
                    title: "Achievements",
                    description: "Unlock rewards as you reach new milestones"
                )
            }
        }
    }
}

struct FeatureHighlightCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Permissions Request
struct PermissionsRequestView: View {
    @State private var healthKitEnabled = false
    @State private var notificationsEnabled = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Enable Features")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                PermissionCard(
                    icon: "heart.fill",
                    title: "Health Data",
                    description: "Sync with Apple Health for better insights",
                    isEnabled: $healthKitEnabled
                ) {
                    requestHealthKitPermission()
                }
                
                PermissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get reminders and workout encouragement",
                    isEnabled: $notificationsEnabled
                ) {
                    requestNotificationPermission()
                }
            }
            
            Text("You can change these settings later in the app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func requestHealthKitPermission() {
        // TODO: Implement HealthKit permission request
        healthKitEnabled.toggle()
    }
    
    private func requestNotificationPermission() {
        Task {
            let granted = await PushNotificationService.shared.requestNotificationPermission()
            await MainActor.run {
                notificationsEnabled = granted
            }
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEnabled ? .blue : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Text(isEnabled ? "Enabled" : "Enable")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isEnabled ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isEnabled ? Color.blue : Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Get Started View
struct GetStartedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("You're all set!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ready to start your fitness journey with FitTracker?")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Text("✓ Personalized recommendations")
                Text("✓ Progress tracking")
                Text("✓ Social features")
                Text("✓ Achievement system")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }
}

// MARK: - Supporting Models
struct OnboardingUserProfile {
    var selectedGoals: Set<String> = []
    var experienceLevel: String = ""
    var workoutFrequency: String = ""
    var preferredWorkoutTypes: Set<String> = []
    var availableEquipment: Set<String> = []
    var isAuthenticated: Bool = false
}

struct FitnessGoalOption: Identifiable {
    let id: String
    let title: String
    let icon: String
    let description: String
}

struct ExperienceLevel: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
}

enum OnboardingPageType {
    case welcome
    case fitnessGoals
    case experienceLevel
    case workoutPreferences
    case features
    case permissions
    case getStarted
}

struct OnboardingPage {
    let type: OnboardingPageType
    let title: String
    let description: String
    let imageName: String
    
    static let allPages = [
        OnboardingPage(
            type: .welcome,
            title: "Welcome to FitTracker",
            description: "Your complete fitness companion for tracking workouts, progress, and connecting with friends",
            imageName: "figure.strengthtraining.traditional"
        ),
        OnboardingPage(
            type: .fitnessGoals,
            title: "Set Your Goals",
            description: "Tell us what you want to achieve so we can personalize your experience",
            imageName: "target"
        ),
        OnboardingPage(
            type: .experienceLevel,
            title: "Experience Level",
            description: "Help us customize workouts and recommendations for your fitness level",
            imageName: "chart.line.uptrend.xyaxis"
        ),
        OnboardingPage(
            type: .workoutPreferences,
            title: "Workout Preferences",
            description: "Let us know your preferences to suggest the best workouts for you",
            imageName: "dumbbell"
        ),
        OnboardingPage(
            type: .features,
            title: "Powerful Features",
            description: "Discover everything FitTracker has to offer to supercharge your fitness journey",
            imageName: "sparkles"
        ),
        OnboardingPage(
            type: .permissions,
            title: "Enable Features",
            description: "Allow access to unlock the full potential of FitTracker",
            imageName: "lock.shield"
        ),
        OnboardingPage(
            type: .getStarted,
            title: "Ready to Start",
            description: "Everything is set up! Let's begin your fitness transformation",
            imageName: "checkmark.circle"
        )
    ]
}

// MARK: - Sign Up View Placeholder
struct SignUpView: View {
    let userProfile: OnboardingUserProfile
    let onComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Sign Up View")
                    .font(.title)
                
                Text("User profile data would be used here for account creation")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Complete Sign Up") {
                    onComplete()
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Create Account")
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