import SwiftUI

struct AdvancedSearchView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var searchText = ""
    @State private var selectedSearchType: SearchType = .all
    @State private var searchResults: SearchResults = SearchResults()
    @State private var isSearching = false
    @State private var showFilters = false
    @State private var searchFilters = SearchFilters()
    @State private var recentSearches: [String] = []
    @State private var suggestedUsers: [User] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(
                    searchText: $searchText,
                    onSearchSubmit: performSearch,
                    onFiltersToggle: { showFilters.toggle() }
                )
                
                // Search Type Selector
                SearchTypeSelector(selectedType: $selectedSearchType)
                
                // Content
                if searchText.isEmpty {
                    SearchDiscoveryView(
                        recentSearches: recentSearches,
                        suggestedUsers: suggestedUsers,
                        onRecentSearchTap: { search in
                            searchText = search
                            performSearch()
                        },
                        onUserTap: { user in
                            // Navigate to user profile
                        }
                    )
                } else if isSearching {
                    SearchLoadingView()
                } else {
                    SearchResultsView(
                        results: searchResults,
                        searchType: selectedSearchType
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFilters) {
                SearchFiltersView(filters: $searchFilters) {
                    performSearch()
                }
            }
        }
        .onAppear {
            loadSuggestedUsers()
            loadRecentSearches()
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSearching = true
        
        // Add to recent searches
        addToRecentSearches(searchText)
        
        Task {
            do {
                let results = try await SearchService.shared.performAdvancedSearch(
                    query: searchText,
                    type: selectedSearchType,
                    filters: searchFilters
                )
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                }
                print("Search error: \(error)")
            }
        }
    }
    
    private func loadSuggestedUsers() {
        Task {
            do {
                let users = try await FirestoreService.shared.searchUsers(query: "", limit: 10)
                await MainActor.run {
                    self.suggestedUsers = users
                }
            } catch {
                print("Error loading suggested users: \(error)")
            }
        }
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recent_searches") ?? []
    }
    
    private func addToRecentSearches(_ search: String) {
        var searches = recentSearches
        searches.removeAll { $0 == search }
        searches.insert(search, at: 0)
        searches = Array(searches.prefix(10))
        
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recent_searches")
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    let onSearchSubmit: () -> Void
    let onFiltersToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search users, workouts, exercises...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        onSearchSubmit()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            
            Button(action: onFiltersToggle) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct SearchTypeSelector: View {
    @Binding var selectedType: SearchType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(SearchType.allCases, id: \.self) { type in
                    SearchTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        action: { selectedType = type }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct SearchTypeButton: View {
    let type: SearchType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct SearchDiscoveryView: View {
    let recentSearches: [String]
    let suggestedUsers: [User]
    let onRecentSearchTap: (String) -> Void
    let onUserTap: (User) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent Searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Searches")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentSearches, id: \.self) { search in
                                    Button(action: {
                                        onRecentSearchTap(search)
                                    }) {
                                        Text(search)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(UIColor.systemGray6))
                                            .foregroundColor(.primary)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Suggested Users
                if !suggestedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Users")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(suggestedUsers, id: \.id) { user in
                                SuggestedUserRow(user: user) {
                                    onUserTap(user)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Trending Topics
                TrendingTopicsView()
            }
            .padding(.vertical)
        }
    }
}

struct SuggestedUserRow: View {
    let user: User
    let onTap: () -> Void
    @State private var isFollowing = false
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: {
                toggleFollow()
            }) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isFollowing ? .primary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(isFollowing ? Color(UIColor.systemGray6) : Color.blue)
                    .cornerRadius(16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func toggleFollow() {
        isFollowing.toggle()
        
        Task {
            do {
                if isFollowing {
                    try await FirestoreService.shared.followUser(userId: user.id)
                } else {
                    try await FirestoreService.shared.unfollowUser(userId: user.id)
                }
            } catch {
                // Revert on error
                await MainActor.run {
                    self.isFollowing.toggle()
                }
                print("Error toggling follow: \(error)")
            }
        }
    }
}

struct TrendingTopicsView: View {
    @State private var trendingTopics: [TrendingTopic] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(trendingTopics, id: \.tag) { topic in
                    TrendingTopicRow(topic: topic)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            loadTrendingTopics()
        }
    }
    
    private func loadTrendingTopics() {
        // Mock trending topics - in production, this would come from analytics
        trendingTopics = [
            TrendingTopic(tag: "pushday", count: 1234),
            TrendingTopic(tag: "deadlift", count: 987),
            TrendingTopic(tag: "proteingains", count: 765),
            TrendingTopic(tag: "morningworkout", count: 543),
            TrendingTopic(tag: "legday", count: 321)
        ]
    }
}

struct TrendingTopicRow: View {
    let topic: TrendingTopic
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("#\(topic.tag)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(topic.count) posts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Handle trending topic tap
        }
    }
}

struct SearchLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchResultsView: View {
    let results: SearchResults
    let searchType: SearchType
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch searchType {
                case .all:
                    SearchAllResultsView(results: results)
                case .users:
                    SearchUsersResultsView(users: results.users)
                case .workouts:
                    SearchWorkoutsResultsView(workouts: results.workouts)
                case .exercises:
                    SearchExercisesResultsView(exercises: results.exercises)
                case .posts:
                    SearchPostsResultsView(posts: results.posts)
                }
            }
            .padding()
        }
    }
}

struct SearchAllResultsView: View {
    let results: SearchResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !results.users.isEmpty {
                SearchSectionView(title: "Users", count: results.users.count) {
                    SearchUsersResultsView(users: Array(results.users.prefix(3)))
                }
            }
            
            if !results.workouts.isEmpty {
                SearchSectionView(title: "Workouts", count: results.workouts.count) {
                    SearchWorkoutsResultsView(workouts: Array(results.workouts.prefix(3)))
                }
            }
            
            if !results.posts.isEmpty {
                SearchSectionView(title: "Posts", count: results.posts.count) {
                    SearchPostsResultsView(posts: Array(results.posts.prefix(3)))
                }
            }
        }
    }
}

struct SearchSectionView<Content: View>: View {
    let title: String
    let count: Int
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if count > 3 {
                    Button("See All") {
                        // Handle see all
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            content()
        }
    }
}

struct SearchUsersResultsView: View {
    let users: [User]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(users, id: \.id) { user in
                SuggestedUserRow(user: user) {
                    // Navigate to user profile
                }
            }
        }
    }
}

struct SearchWorkoutsResultsView: View {
    let workouts: [EnhancedWorkout]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(workouts, id: \.id) { workout in
                WorkoutSearchResultRow(workout: workout)
            }
        }
    }
}

struct WorkoutSearchResultRow: View {
    let workout: EnhancedWorkout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                    Label("\(Int(workout.totalVolume))lb", systemImage: "scalemass")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if workout.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct SearchExercisesResultsView: View {
    let exercises: [Exercise]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(exercises, id: \.id) { exercise in
                ExerciseSearchResultRow(exercise: exercise)
            }
        }
    }
}

struct ExerciseSearchResultRow: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(exercise.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !exercise.primaryMuscles.isEmpty {
                    HStack {
                        ForEach(exercise.primaryMuscles.prefix(3), id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct SearchPostsResultsView: View {
    let posts: [SocialPost]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(posts, id: \.id) { post in
                PostSearchResultRow(post: post)
            }
        }
    }
}

struct PostSearchResultRow: View {
    let post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("@username") // Would need to fetch username
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(post.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(post.content)
                .font(.subheadline)
                .lineLimit(3)
            
            HStack {
                Label("\(post.likes)", systemImage: "heart")
                Label("\(post.comments.count)", systemImage: "bubble.right")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types
enum SearchType: String, CaseIterable {
    case all = "all"
    case users = "users"
    case workouts = "workouts"
    case exercises = "exercises"
    case posts = "posts"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .users: return "Users"
        case .workouts: return "Workouts"
        case .exercises: return "Exercises"
        case .posts: return "Posts"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .users: return "person.2"
        case .workouts: return "dumbbell"
        case .exercises: return "list.bullet"
        case .posts: return "square.and.pencil"
        }
    }
}

struct SearchResults {
    var users: [User] = []
    var workouts: [EnhancedWorkout] = []
    var exercises: [Exercise] = []
    var posts: [SocialPost] = []
}

struct SearchFilters {
    var location: String?
    var dateRange: ClosedRange<Date>?
    var workoutType: String?
    var muscleGroup: String?
    var difficulty: String?
    var equipment: [String] = []
    var isVerified: Bool?
}

struct TrendingTopic {
    let tag: String
    let count: Int
}

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    let onApply: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Search Filters")
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Apply") {
                            onApply()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}