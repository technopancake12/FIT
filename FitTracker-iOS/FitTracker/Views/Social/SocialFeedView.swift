import SwiftUI

struct SocialFeedView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var posts: [SocialPost] = []
    @State private var isLoading = true
    @State private var refreshing = false
    @State private var showCreatePost = false
    @State private var showUserSearch = false
    
    var body: some View {
        NavigationView {
            RefreshableScrollView(onRefresh: refreshFeed) {
                LazyVStack(spacing: 0) {
                    if isLoading {
                        ForEach(0..<5, id: \.self) { _ in
                            PostSkeletonView()
                        }
                    } else if posts.isEmpty {
                        EmptyFeedView {
                            showUserSearch = true
                        }
                    } else {
                        ForEach(posts, id: \.id) { post in
                            SocialPostView(post: post)
                                .onAppear {
                                    // Load more posts when reaching the end
                                    if post.id == posts.last?.id {
                                        loadMorePosts()
                                    }
                                }
                        }
                    }
                }
                .padding(.top, 1)
            }
            .navigationTitle("FitTracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showUserSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showCreatePost = true
                        }) {
                            Image(systemName: "plus.square")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        
                        NavigationLink(destination: ChatListView()) {
                            Image(systemName: "paperplane")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            setupFeedListener()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $showUserSearch) {
            UserSearchView()
        }
    }
    
    private func setupFeedListener() {
        isLoading = true
        FirestoreService.shared.listenToFeedPosts { newPosts in
            self.posts = newPosts
            self.isLoading = false
        }
    }
    
    private func refreshFeed() {
        refreshing = true
        Task {
            do {
                let newPosts = try await FirestoreService.shared.getFeedPosts(limit: 20)
                await MainActor.run {
                    self.posts = newPosts
                    self.refreshing = false
                }
            } catch {
                await MainActor.run {
                    self.refreshing = false
                }
                print("Error refreshing feed: \(error)")
            }
        }
    }
    
    private func loadMorePosts() {
        // Implementation for pagination
        Task {
            do {
                let morePosts = try await FirestoreService.shared.getFeedPosts(limit: 10)
                await MainActor.run {
                    // Add posts that aren't already in the feed
                    let existingIds = Set(posts.map { $0.id })
                    let newPosts = morePosts.filter { !existingIds.contains($0.id) }
                    self.posts.append(contentsOf: newPosts)
                }
            } catch {
                print("Error loading more posts: \(error)")
            }
        }
    }
}

struct SocialPostView: View {
    let post: SocialPost
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var userProfile: User?
    @State private var isLiked: Bool = false
    @State private var showComments = false
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            PostHeaderView(user: userProfile, post: post)
            
            // Content
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.body)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            // Workout Data (if applicable)
            if let workoutData = post.workoutData {
                WorkoutDataView(workoutData: workoutData)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            // Images
            if !post.photos.isEmpty {
                PostImagesView(photos: post.photos)
            }
            
            // Actions
            PostActionsView(
                post: post,
                isLiked: isLiked,
                onLike: toggleLike,
                onComment: { showComments = true },
                onShare: { showShareSheet = true }
            )
            
            // Like count and comments preview
            PostEngagementView(post: post) {
                showComments = true
            }
            
            Divider()
                .padding(.top, 8)
        }
        .onAppear {
            loadUserProfile()
            checkIfLiked()
        }
        .sheet(isPresented: $showComments) {
            CommentsView(post: post)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [createShareContent()])
        }
    }
    
    private func loadUserProfile() {
        Task {
            do {
                let user = try await FirestoreService.shared.getUserProfile(userId: post.userId)
                await MainActor.run {
                    self.userProfile = user
                }
            } catch {
                print("Error loading user profile: \(error)")
            }
        }
    }
    
    private func checkIfLiked() {
        guard let currentUserId = FirebaseManager.shared.currentUser?.id else { return }
        isLiked = post.likedBy.contains(currentUserId)
    }
    
    private func toggleLike() {
        guard let currentUserId = FirebaseManager.shared.currentUser?.id else { return }
        
        let wasLiked = isLiked
        isLiked.toggle()
        
        Task {
            do {
                if wasLiked {
                    try await FirestoreService.shared.unlikePost(postId: post.id)
                } else {
                    try await FirestoreService.shared.likePost(postId: post.id)
                }
            } catch {
                await MainActor.run {
                    // Revert on error
                    self.isLiked = wasLiked
                }
                print("Error toggling like: \(error)")
            }
        }
    }
    
    private func createShareContent() -> String {
        let username = userProfile?.username ?? "Unknown"
        return "Check out this workout from @\(username) on FitTracker!"
    }
}

struct PostHeaderView: View {
    let user: User?
    let post: SocialPost
    
    var body: some View {
        HStack {
            // Profile picture
            AsyncImage(url: URL(string: user?.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(user?.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if user?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text(post.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct WorkoutDataView: View {
    let workoutData: WorkoutData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.blue)
                Text("Workout Summary")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                WorkoutStatView(title: "Exercise", value: workoutData.exerciseName)
                WorkoutStatView(title: "Weight", value: "\(Int(workoutData.weight))lb")
                WorkoutStatView(title: "Reps", value: "\(workoutData.reps)")
                WorkoutStatView(title: "Sets", value: "\(workoutData.sets)")
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct WorkoutStatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PostImagesView: View {
    let photos: [String]
    
    var body: some View {
        TabView {
            ForEach(photos.indices, id: \.self) { index in
                AsyncImage(url: URL(string: photos[index])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 300)
    }
}

struct PostActionsView: View {
    let post: SocialPost
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onLike) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(isLiked ? .red : .primary)
            }
            
            Button(action: onComment) {
                Image(systemName: "bubble.right")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            
            Button(action: onShare) {
                Image(systemName: "paperplane")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bookmark")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct PostEngagementView: View {
    let post: SocialPost
    let onCommentsTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if post.likes > 0 {
                Text("\(post.likes) likes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
            }
            
            if !post.comments.isEmpty {
                Button(action: onCommentsTap) {
                    Text("View all \(post.comments.count) comments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Show first comment
                if let firstComment = post.comments.first {
                    HStack {
                        Text("@username") // Would need to fetch username
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(firstComment.content)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct PostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 14)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 12)
                }
                Spacer()
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 250)
            
            HStack {
                ForEach(0..<4) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
        }
        .padding()
        .redacted(reason: .placeholder)
    }
}

struct EmptyFeedView: View {
    let onFindFriends: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Welcome to FitTracker!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Follow other users to see their workouts and fitness journey in your feed.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onFindFriends) {
                Text("Find People to Follow")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Supporting Views (Placeholders)
struct CreatePostView: View {
    var body: some View {
        Text("Create Post View")
            .navigationTitle("New Post")
    }
}

struct UserSearchView: View {
    var body: some View {
        Text("User Search View")
            .navigationTitle("Search")
    }
}

struct CommentsView: View {
    let post: SocialPost
    
    var body: some View {
        Text("Comments View")
            .navigationTitle("Comments")
    }
}

struct ChatListView: View {
    var body: some View {
        Text("Chat List View")
            .navigationTitle("Messages")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () -> Void
    let content: Content
    
    init(onRefresh: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            onRefresh()
        }
    }
}

// MARK: - Extensions
extension Date {
    func timeAgoDisplay() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day, .weekOfYear], from: self, to: now)
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w"
        } else if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}