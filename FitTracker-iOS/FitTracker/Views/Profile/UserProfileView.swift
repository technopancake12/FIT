import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var userPosts: [SocialPost] = []
    @State private var userWorkouts: [EnhancedWorkout] = []
    @State private var isLoading = true
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var selectedTab = 0
    @State private var followerCount = 0
    @State private var followingCount = 0
    
    var currentUser: User? {
        firebaseManager.currentUser
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    ProfileHeaderView(
                        user: currentUser,
                        followerCount: followerCount,
                        followingCount: followingCount,
                        onEditProfile: { showEditProfile = true },
                        onSettings: { showSettings = true }
                    )
                    
                    // Stats Grid
                    ProfileStatsView(user: currentUser, workouts: userWorkouts)
                    
                    // Tab Selector
                    ProfileTabSelector(selectedTab: $selectedTab)
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        // Posts Grid
                        PostsGridView(posts: userPosts)
                    } else if selectedTab == 1 {
                        // Workouts List
                        WorkoutsListView(workouts: userWorkouts)
                    } else {
                        // Achievements
                        AchievementsView(user: currentUser)
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await loadUserData()
            }
        }
        .onAppear {
            Task {
                await loadUserData()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    @MainActor
    private func loadUserData() async {
        guard let currentUser = currentUser else { return }
        
        isLoading = true
        
        do {
            // Load user posts
            let posts = try await firebaseManager.getFeedPosts(limit: 50)
            userPosts = posts.filter { $0.userId == currentUser.id }
            
            // Load user workouts
            userWorkouts = try await firebaseManager.getUserWorkouts(userId: currentUser.id, limit: 20)
            
            // Update stats
            followerCount = currentUser.stats.followers
            followingCount = currentUser.stats.following
            
        } catch {
            print("Error loading user data: \(error)")
        }
        
        isLoading = false
    }
}

struct ProfileHeaderView: View {
    let user: User?
    let followerCount: Int
    let followingCount: Int
    let onEditProfile: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Profile Picture
            AsyncImage(url: URL(string: user?.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Text(user?.displayName.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            
            // User Info
            VStack(spacing: 4) {
                HStack {
                    Text(user?.displayName ?? "Unknown User")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if user?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                
                Text("@\(user?.username ?? "unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = user?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            
            // Stats Row
            HStack(spacing: 40) {
                StatView(count: user?.stats.workouts ?? 0, label: "Workouts")
                StatView(count: followerCount, label: "Followers")
                StatView(count: followingCount, label: "Following")
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onEditProfile) {
                    Text("Edit Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Share Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct StatView: View {
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileStatsView: View {
    let user: User?
    let workouts: [EnhancedWorkout]
    
    var totalVolume: Double {
        workouts.reduce(0) { $0 + $1.totalVolume }
    }
    
    var averageWorkoutDuration: Double {
        let completedWorkouts = workouts.filter { $0.completed }
        let totalDuration = completedWorkouts.compactMap { $0.duration }.reduce(0, +)
        return completedWorkouts.isEmpty ? 0 : totalDuration / Double(completedWorkouts.count)
    }
    
    var currentStreak: Int {
        // Calculate workout streak
        let sortedWorkouts = workouts.filter { $0.completed }.sorted { $0.date > $1.date }
        var streak = 0
        var lastDate: Date?
        
        for workout in sortedWorkouts {
            if let last = lastDate {
                let daysDiff = Calendar.current.dateComponents([.day], from: workout.date, to: last).day ?? 0
                if daysDiff > 1 {
                    break
                }
            }
            streak += 1
            lastDate = workout.date
        }
        
        return streak
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCardView(
                title: "Total Volume",
                value: "\(Int(totalVolume))lb",
                icon: "scalemass.fill",
                color: .blue
            )
            
            StatCardView(
                title: "Workout Streak",
                value: "\(currentStreak) days",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCardView(
                title: "Avg Duration",
                value: "\(Int(averageWorkoutDuration / 60))min",
                icon: "clock.fill",
                color: .green
            )
            
            StatCardView(
                title: "This Month",
                value: "\(workoutsThisMonth) workouts",
                icon: "calendar",
                color: .purple
            )
        }
        .padding()
    }
    
    private var workoutsThisMonth: Int {
        let now = Date()
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
        return workouts.filter { $0.date >= startOfMonth && $0.completed }.count
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ProfileTabSelector: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                icon: "square.grid.3x3",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                icon: "dumbbell",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabButton(
                icon: "trophy",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .bottom
        )
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? .primary : .clear),
                    alignment: .bottom
                )
        }
    }
}

struct PostsGridView: View {
    let posts: [SocialPost]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts, id: \.id) { post in
                PostThumbnailView(post: post)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

struct PostThumbnailView: View {
    let post: SocialPost
    
    var body: some View {
        AsyncImage(url: URL(string: post.photos.first ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    VStack {
                        Image(systemName: post.type == .workout ? "dumbbell.fill" : "text.alignleft")
                            .font(.title2)
                            .foregroundColor(.white)
                        if post.photos.count > 1 {
                            Image(systemName: "square.on.square")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                )
        }
        .clipped()
    }
}

struct WorkoutsListView: View {
    let workouts: [EnhancedWorkout]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(workouts, id: \.id) { workout in
                WorkoutRowView(workout: workout)
            }
        }
        .padding()
    }
}

struct WorkoutRowView: View {
    let workout: EnhancedWorkout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                    Label("\(Int(workout.totalVolume))lb", systemImage: "scalemass")
                    if let duration = workout.duration {
                        Label("\(Int(duration / 60))min", systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if workout.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AchievementsView: View {
    let user: User?
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            AchievementCardView(
                title: "First Workout",
                description: "Completed your first workout",
                icon: "trophy.fill",
                color: .yellow,
                isUnlocked: true
            )
            
            AchievementCardView(
                title: "Week Warrior",
                description: "7-day workout streak",
                icon: "flame.fill",
                color: .orange,
                isUnlocked: true
            )
            
            AchievementCardView(
                title: "Heavy Lifter",
                description: "Lift 1000lb total volume",
                icon: "scalemass.fill",
                color: .blue,
                isUnlocked: false
            )
            
            AchievementCardView(
                title: "Social Star",
                description: "Get 100 post likes",
                icon: "heart.fill",
                color: .red,
                isUnlocked: false
            )
        }
        .padding()
    }
}

struct AchievementCardView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(isUnlocked ? color : .gray)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .gray)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Supporting Views (Placeholders)
struct EditProfileView: View {
    var body: some View {
        NavigationView {
            Text("Edit Profile")
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// SettingsView is defined in Views/Settings/SettingsView.swift