import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 2 // Start with Home tab (center position)
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @StateObject private var localDatabase = LocalDatabaseService.shared
    @StateObject private var socialService = SocialService.shared
    
    var body: some View {
        ZStack {
            // Background gradient for entire app
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.15, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Workout Tab - First in order
                WorkoutTabView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "dumbbell.fill" : "dumbbell")
                        Text("Workout")
                    }
                    .tag(0)
                
                // Nutrition Tab - Second in order  
                NutritionTabView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "leaf.fill" : "leaf")
                        Text("Nutrition")
                    }
                    .tag(1)
                
                // Home Tab - Center position (main dashboard)
                HomeTabView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(2)
                
                // Feed Tab - Fourth in order (social media style)
                FeedTabView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                        Text("Feed")
                    }
                    .tag(3)
                
                // Profile Tab - Last in order
                ProfileTabView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                        Text("Profile")
                    }
                    .tag(4)
            }
            .accentColor(.white)
            .preferredColorScheme(.dark)
            .onAppear {
                setupTabBarAppearance()
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Selected tab color
        appearance.selectionIndicatorTintColor = .white
        
        // Tab item colors
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Tab Views

struct WorkoutTabView: View {
    @State private var selectedWorkoutTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        WorkoutTabButton(
                            title: "Routines",
                            isSelected: selectedWorkoutTab == 0,
                            action: { selectedWorkoutTab = 0 }
                        )
                        
                        WorkoutTabButton(
                            title: "Exercise Search",
                            isSelected: selectedWorkoutTab == 1,
                            action: { selectedWorkoutTab = 1 }
                        )
                        
                        WorkoutTabButton(
                            title: "Templates",
                            isSelected: selectedWorkoutTab == 2,
                            action: { selectedWorkoutTab = 2 }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Tab Content
                    TabView(selection: $selectedWorkoutTab) {
                        WorkoutPlannerView()
                            .tag(0)
                        
                        EnhancedExerciseSearchView()
                            .tag(1)
                        
                        WorkoutTemplatesView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct NutritionTabView: View {
    @State private var selectedNutritionTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        NutritionTabButton(
                            title: "Food Search",
                            isSelected: selectedNutritionTab == 0,
                            action: { selectedNutritionTab = 0 }
                        )
                        
                        NutritionTabButton(
                            title: "Barcode Scanner",
                            isSelected: selectedNutritionTab == 1,
                            action: { selectedNutritionTab = 1 }
                        )
                        
                        NutritionTabButton(
                            title: "Daily Log",
                            isSelected: selectedNutritionTab == 2,
                            action: { selectedNutritionTab = 2 }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Tab Content
                    TabView(selection: $selectedNutritionTab) {
                        USFoodSearchView()
                            .tag(0)
                        
                        BarcodeScannerView()
                            .tag(1)
                        
                        DailyNutritionLogView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HomeTabView: View {
    var body: some View {
        NavigationView {
            ModernDashboardView()
        }
    }
}

struct FeedTabView: View {
    @StateObject private var socialService = SocialService.shared
    @State private var posts: [SocialPost] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                if isLoading {
                    ProgressView("Loading feed...")
                        .foregroundColor(.white)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                SocialPostCard(post: post)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await loadFeed()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await loadFeed()
        }
    }
    
    private func loadFeed() async {
        isLoading = true
        do {
            posts = try await socialService.fetchFeed()
        } catch {
            print("Error loading feed: \(error)")
        }
        isLoading = false
    }
}

struct ProfileTabView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var userStats: UserStats = UserStats()
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        profileHeader
                        
                        // Stats Grid
                        statsGrid
                        
                        // Activity Feed
                        activitySection
                        
                        // Settings & Actions
                        settingsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditProfile.toggle() }) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image & Info
            HStack {
                AsyncImage(url: URL(string: firebaseManager.currentUser?.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(firebaseManager.currentUser?.displayName ?? "FitTracker User")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let email = firebaseManager.currentUser?.email {
                        Text(email)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text("Member since \(memberSinceText)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            // Bio section
            if let bio = firebaseManager.currentUser?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ProfileStatCard(title: "Workouts", value: "\(userStats.totalWorkouts)", icon: "dumbbell.fill", color: .blue)
            ProfileStatCard(title: "Streak", value: "\(userStats.currentStreak)", icon: "flame.fill", color: .orange)
            ProfileStatCard(title: "Following", value: "\(userStats.following)", icon: "person.2.fill", color: .green)
            ProfileStatCard(title: "Followers", value: "\(userStats.followers)", icon: "heart.fill", color: .red)
            ProfileStatCard(title: "Posts", value: "\(userStats.totalPosts)", icon: "photo.fill", color: .purple)
            ProfileStatCard(title: "Points", value: "\(userStats.points)", icon: "star.fill", color: .yellow)
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full activity view
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                ActivityRow(icon: "dumbbell.fill", text: "Completed Push Day workout", time: "2h ago", color: .blue)
                ActivityRow(icon: "trophy.fill", text: "Achieved 7-day streak!", time: "1d ago", color: .yellow)
                ActivityRow(icon: "heart.fill", text: "Liked John's progress photo", time: "2d ago", color: .red)
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var settingsSection: some View {
        VStack(spacing: 12) {
            SettingsRow(icon: "chart.line.uptrend.xyaxis", title: "Analytics", color: .blue) {}
            SettingsRow(icon: "square.and.arrow.down", title: "Export Data", color: .green) {}
            SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange) {}
            SettingsRow(icon: "lock.fill", title: "Privacy", color: .purple) {}
            SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .cyan) {}
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 8)
            
            SettingsRow(icon: "arrow.right.square", title: "Sign Out", color: .red) {
                do {
                    try firebaseManager.signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: firebaseManager.currentUser?.createdAt ?? Date())
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Supporting Views

private var backgroundGradient: some View {
    LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.1),
            Color(red: 0.1, green: 0.1, blue: 0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
}

struct WorkoutTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.8) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutritionTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.green.opacity(0.8) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SocialPostCard: View {
    let post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header
            HStack {
                AsyncImage(url: URL(string: post.userAvatar ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.2))
                        .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.6)))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(post.timestamp, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Post content
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            
            // Post image
            if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(ProgressView().tint(.white))
                }
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .white.opacity(0.7))
                        Text("\(post.likesCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(post.commentsCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ActivityRow: View {
    let icon: String
    let text: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Text("Edit Profile")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct WorkoutTemplatesView: View {
    @State private var templates: [WorkoutTemplate] = []
    @State private var showCreateTemplate = false
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            if templates.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No workout templates yet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Create your first workout template in the Routines tab")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    
                    Button("Create Template") {
                        showCreateTemplate = true
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.8))
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(templates) { template in
                            WorkoutTemplateCard(template: template)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .sheet(isPresented: $showCreateTemplate) {
            WorkoutPlannerView()
        }
        .task {
            await loadTemplates()
        }
    }
    
    private func loadTemplates() async {
        // Load workout templates from local database or Firebase
        templates = []
    }
}

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    
    private var durationText: String {
        if let duration = template.estimatedDuration {
            let minutes = Int(duration / 60)
            return "\(minutes)min"
        } else {
            return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(template.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(durationText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.3))
                    )
            }
            
            if let description = template.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseManager.shared)
}