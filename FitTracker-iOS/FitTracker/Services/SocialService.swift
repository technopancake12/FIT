import Foundation
import SwiftUI
import FirebaseFirestore

class SocialService: ObservableObject {
    static let shared = SocialService()
    
    @Published var posts: [SocialPost] = []
    @Published var users: [User] = []
    @Published var follows: [Follow] = []
    @Published var feed: [FeedItem] = []
    
    private let currentUserId = "user_1"
    private let db = Firestore.firestore()
    
    init() {
        loadFromStorage()
        Task {
            await loadDataFromFirebase()
        }
        updateFeed()
    }
    
    // MARK: - Data Persistence
    private func loadFromStorage() {
        if let postsData = UserDefaults.standard.data(forKey: "social_posts"),
           let decodedPosts = try? JSONDecoder().decode([SocialPost].self, from: postsData) {
            self.posts = decodedPosts
        }
        
        if let usersData = UserDefaults.standard.data(forKey: "social_users"),
           let decodedUsers = try? JSONDecoder().decode([User].self, from: usersData) {
            self.users = decodedUsers
        }
        
        if let followsData = UserDefaults.standard.data(forKey: "social_follows"),
           let decodedFollows = try? JSONDecoder().decode([Follow].self, from: followsData) {
            self.follows = decodedFollows
        }
    }
    
    private func saveToStorage() {
        if let postsData = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(postsData, forKey: "social_posts")
        }
        
        if let usersData = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(usersData, forKey: "social_users")
        }
        
        if let followsData = try? JSONEncoder().encode(follows) {
            UserDefaults.standard.set(followsData, forKey: "social_follows")
        }
    }
    
    // MARK: - Data Loading from Firebase
    private func loadDataFromFirebase() async {
        // Load users from Firebase
        await loadUsersFromFirebase()
        
        // Load posts from Firebase
        await loadPostsFromFirebase()
        
        // Load follows from Firebase  
        await loadFollowsFromFirebase()
        
        // Add sample users if needed
        if users.isEmpty {
            users = [
                User(id: "user_1", username: "johndoe", displayName: "John Doe", email: "john@example.com", avatar: nil, bio: "Fitness enthusiast and personal trainer", stats: UserStats(workouts: 125, followers: 245, following: 89, totalVolume: 12500, totalWorkouts: 125, currentStreak: 7, totalPosts: 34, points: 2400)),
                User(id: "user_2", username: "fitnessguru", displayName: "Sarah Johnson", email: "sarah@example.com", avatar: nil, bio: "Strength coach • Nutritionist • Mom of 2", stats: UserStats(workouts: 89, followers: 523, following: 142, totalVolume: 8900, totalWorkouts: 89, currentStreak: 14, totalPosts: 67, points: 3200)),
                User(id: "user_3", username: "mikefits", displayName: "Mike Chen", email: "mike@example.com", avatar: nil, bio: "Powerlifter | Competing since 2019 🏋️‍♂️", stats: UserStats(workouts: 156, followers: 189, following: 67, totalVolume: 18600, totalWorkouts: 156, currentStreak: 21, totalPosts: 89, points: 4100)),
                User(id: "user_4", username: "yogalife", displayName: "Emma Wilson", email: "emma@example.com", avatar: nil, bio: "Yoga instructor • Mindfulness advocate ✨", stats: UserStats(workouts: 234, followers: 387, following: 203, totalVolume: 2340, totalWorkouts: 234, currentStreak: 42, totalPosts: 123, points: 2800))
            ]
        }
        
        // Fallback to sample data only if Firebase is empty
        if posts.isEmpty {
            posts = [
                SocialPost(
                    id: "post_1",
                    userId: "user_2",
                    type: .workout,
                    content: "New PR on deadlifts today! 💀 Form felt perfect and the weight moved smoothly. Training consistency really pays off!",
                    photos: [],
                    workoutData: WorkoutData(
                        exerciseName: "Deadlift",
                        weight: 180,
                        reps: 5,
                        sets: 3,
                        duration: 45
                    ),
                    achievementData: nil,
                    likes: 24,
                    likedBy: ["user_1", "user_3"],
                    comments: [
                        Comment(
                            id: "comment_1",
                            userId: "user_3",
                            content: "Beast mode! 🔥 What's your next goal?",
                            createdAt: Date(timeIntervalSinceNow: -2*60*60),
                            likes: 3,
                            likedBy: ["user_1", "user_2"],
                            replies: []
                        ),
                        Comment(
                            id: "comment_2",
                            userId: "user_1",
                            content: "Incredible strength! Any tips for deadlift form?",
                            createdAt: Date(timeIntervalSinceNow: -1*60*60),
                            likes: 1,
                            likedBy: ["user_2"],
                            replies: []
                        )
                    ],
                    createdAt: Date(timeIntervalSinceNow: -3*60*60),
                    location: nil,
                    tags: ["deadlift", "pr", "strength"],
                    visibility: .public
                ),
                SocialPost(
                    id: "post_2",
                    userId: "user_3",
                    type: .achievement,
                    content: "Hit my 100-day workout streak! 🎉 Consistency is everything. Here's to the next 100!",
                    photos: [],
                    workoutData: nil,
                    achievementData: AchievementData(
                        type: "streak",
                        title: "100 Day Streak",
                        description: "Completed 100 consecutive workout days",
                        value: "100 days"
                    ),
                    likes: 45,
                    likedBy: ["user_1", "user_2", "user_4"],
                    comments: [
                        Comment(
                            id: "comment_3",
                            userId: "user_2",
                            content: "Amazing dedication! You're an inspiration 💪",
                            createdAt: Date(timeIntervalSinceNow: -30*60),
                            likes: 5,
                            likedBy: ["user_1", "user_3", "user_4"],
                            replies: []
                        )
                    ],
                    createdAt: Date(timeIntervalSinceNow: -5*60*60),
                    location: nil,
                    tags: ["streak", "milestone", "motivation"],
                    visibility: .public
                ),
                SocialPost(
                    id: "post_3",
                    userId: "user_4",
                    type: .progress,
                    content: "Morning yoga session complete! 🧘‍♀️ Starting the day with mindfulness and movement. Today's focus was on hip flexibility.",
                    photos: [],
                    workoutData: WorkoutData(
                        exerciseName: "Yoga Flow",
                        weight: 0,
                        reps: 1,
                        sets: 1,
                        duration: 30
                    ),
                    achievementData: nil,
                    likes: 18,
                    likedBy: ["user_1", "user_3"],
                    comments: [],
                    createdAt: Date(timeIntervalSinceNow: -8*60*60),
                    location: nil,
                    tags: ["yoga", "flexibility", "mindfulness"],
                    visibility: .public
                )
            ]
        }
        
        if follows.isEmpty {
            follows = [
                Follow(followerId: "user_1", followingId: "user_2", createdAt: Date()),
                Follow(followerId: "user_1", followingId: "user_3", createdAt: Date()),
                Follow(followerId: "user_2", followingId: "user_1", createdAt: Date()),
                Follow(followerId: "user_3", followingId: "user_1", createdAt: Date()),
                Follow(followerId: "user_4", followingId: "user_1", createdAt: Date())
            ]
        }
        
        saveToStorage()
    }
    
    private func loadUsersFromFirebase() async {
        do {
            let snapshot = try await db.collection("users")
                .limit(to: 20)
                .getDocuments()
            
            let fetchedUsers = snapshot.documents.compactMap { document -> User? in
                let data = document.data()
                return User(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "",
                    email: data["email"] as? String,
                    avatar: data["avatar"] as? String,
                    bio: data["bio"] as? String,
                    stats: UserStats(
                        workouts: data["workouts"] as? Int ?? 0,
                        followers: data["followers"] as? Int ?? 0,
                        following: data["following"] as? Int ?? 0,
                        totalVolume: data["totalVolume"] as? Double ?? 0
                    ),
                    joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    isVerified: data["isVerified"] as? Bool ?? false
                )
            }
            
            await MainActor.run {
                self.users = fetchedUsers
            }
        } catch {
            print("Error loading users: \(error)")
        }
    }
    
    private func loadPostsFromFirebase() async {
        do {
            let snapshot = try await db.collection("social_posts")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            let fetchedPosts = snapshot.documents.compactMap { document -> SocialPost? in
                let data = document.data()
                
                var workoutData: WorkoutData?
                if let workoutDict = data["workoutData"] as? [String: Any] {
                    workoutData = WorkoutData(
                        exerciseName: workoutDict["exerciseName"] as? String ?? "",
                        weight: workoutDict["weight"] as? Double ?? 0,
                        reps: workoutDict["reps"] as? Int ?? 0,
                        sets: workoutDict["sets"] as? Int ?? 0,
                        duration: workoutDict["duration"] as? TimeInterval
                    )
                }
                
                var achievementData: AchievementData?
                if let achievementDict = data["achievementData"] as? [String: Any] {
                    achievementData = AchievementData(
                        type: achievementDict["type"] as? String ?? "",
                        title: achievementDict["title"] as? String ?? "",
                        description: achievementDict["description"] as? String ?? "",
                        value: achievementDict["value"] as? String ?? ""
                    )
                }
                
                return SocialPost(
                    id: document.documentID,
                    userId: data["userId"] as? String ?? "",
                    type: PostType(rawValue: data["type"] as? String ?? "general") ?? .general,
                    content: data["content"] as? String ?? "",
                    photos: data["photos"] as? [String] ?? [],
                    workoutData: workoutData,
                    achievementData: achievementData,
                    likes: data["likes"] as? Int ?? 0,
                    likedBy: data["likedBy"] as? [String] ?? [],
                    comments: [], // Comments loaded separately
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    location: data["location"] as? String,
                    tags: data["tags"] as? [String] ?? [],
                    visibility: PostVisibility(rawValue: data["visibility"] as? String ?? "public") ?? .public
                )
            }
            
            await MainActor.run {
                self.posts = fetchedPosts
            }
        } catch {
            print("Error loading posts: \(error)")
        }
    }
    
    private func loadFollowsFromFirebase() async {
        do {
            let snapshot = try await db.collection("follows")
                .getDocuments()
            
            let fetchedFollows = snapshot.documents.compactMap { document -> Follow? in
                let data = document.data()
                return Follow(
                    followerId: data["followerId"] as? String ?? "",
                    followingId: data["followingId"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
            
            await MainActor.run {
                self.follows = fetchedFollows
            }
        } catch {
            print("Error loading follows: \(error)")
        }
    }
    
    // MARK: - Post Management
    func createPost(
        type: PostType,
        content: String,
        photos: [String] = [],
        workoutData: WorkoutData? = nil,
        achievementData: AchievementData? = nil,
        tags: [String] = []
    ) {
        let newPost = SocialPost(
            id: "post_\(Date().timeIntervalSince1970)",
            userId: currentUserId,
            type: type,
            content: content,
            photos: photos,
            workoutData: workoutData,
            achievementData: achievementData,
            likes: 0,
            likedBy: [],
            comments: [],
            createdAt: Date(),
            location: nil,
            tags: tags,
            visibility: .public
        )
        
        posts.insert(newPost, at: 0)
        saveToStorage()
        updateFeed()
    }
    
    func deletePost(postId: String) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == postId }),
              posts[index].userId == currentUserId else {
            return false
        }
        
        posts.remove(at: index)
        saveToStorage()
        updateFeed()
        return true
    }
    
    // MARK: - Interactions
    func likePost(postId: String) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            return false
        }
        
        let isLiked = posts[index].likedBy.contains(currentUserId)
        
        if isLiked {
            posts[index].likedBy.removeAll { $0 == currentUserId }
            posts[index].likes -= 1
        } else {
            posts[index].likedBy.append(currentUserId)
            posts[index].likes += 1
        }
        
        saveToStorage()
        updateFeed()
        return !isLiked
    }
    
    func addComment(postId: String, content: String) -> Comment? {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            return nil
        }
        
        let comment = Comment(
            id: "comment_\(Date().timeIntervalSince1970)",
            userId: currentUserId,
            content: content,
            createdAt: Date(),
            likes: 0,
            likedBy: [],
            replies: []
        )
        
        posts[index].comments.append(comment)
        saveToStorage()
        updateFeed()
        return comment
    }
    
    func likeComment(postId: String, commentId: String) -> Bool {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }),
              let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == commentId }) else {
            return false
        }
        
        let isLiked = posts[postIndex].comments[commentIndex].likedBy.contains(currentUserId)
        
        if isLiked {
            posts[postIndex].comments[commentIndex].likedBy.removeAll { $0 == currentUserId }
            posts[postIndex].comments[commentIndex].likes -= 1
        } else {
            posts[postIndex].comments[commentIndex].likedBy.append(currentUserId)
            posts[postIndex].comments[commentIndex].likes += 1
        }
        
        saveToStorage()
        updateFeed()
        return !isLiked
    }
    
    // MARK: - Follow System
    func followUser(userId: String) -> Bool {
        guard userId != currentUserId else { return false }
        
        if let index = follows.firstIndex(where: { $0.followerId == currentUserId && $0.followingId == userId }) {
            // Unfollow
            follows.remove(at: index)
            
            // Update stats
            if let userIndex = users.firstIndex(where: { $0.id == userId }) {
                users[userIndex].stats.followers -= 1
            }
            if let currentUserIndex = users.firstIndex(where: { $0.id == currentUserId }) {
                users[currentUserIndex].stats.following -= 1
            }
            
            saveToStorage()
            updateFeed()
            return false
        } else {
            // Follow
            let follow = Follow(followerId: currentUserId, followingId: userId, createdAt: Date())
            follows.append(follow)
            
            // Update stats
            if let userIndex = users.firstIndex(where: { $0.id == userId }) {
                users[userIndex].stats.followers += 1
            }
            if let currentUserIndex = users.firstIndex(where: { $0.id == currentUserId }) {
                users[currentUserIndex].stats.following += 1
            }
            
            saveToStorage()
            updateFeed()
            return true
        }
    }
    
    // MARK: - Feed Generation
    func updateFeed() {
        let followingIds = follows
            .filter { $0.followerId == currentUserId }
            .map { $0.followingId }
        
        let relevantPosts = posts.filter { post in
            post.userId == currentUserId ||
            followingIds.contains(post.userId) ||
            post.visibility == .public
        }
        
        feed = relevantPosts.compactMap { post in
            guard let user = users.first(where: { $0.id == post.userId }) else {
                return nil
            }
            
            let isLiked = post.likedBy.contains(currentUserId)
            let isFollowing = post.userId == currentUserId ? false : 
                follows.contains { $0.followerId == currentUserId && $0.followingId == post.userId }
            
            return FeedItem(
                id: post.id,
                post: post,
                user: user,
                isLiked: isLiked,
                isFollowing: isFollowing
            )
        }.sorted { $0.post.createdAt > $1.post.createdAt }
    }
    
    // MARK: - User Management
    func getCurrentUser() -> User? {
        return users.first { $0.id == currentUserId }
    }
    
    func getUser(userId: String) -> User? {
        return users.first { $0.id == userId }
    }
    
    func searchUsers(query: String) -> [User] {
        let lowercaseQuery = query.lowercased()
        return users.filter { user in
            user.username.lowercased().contains(lowercaseQuery) ||
            user.displayName.lowercased().contains(lowercaseQuery)
        }
    }
    
    func isFollowing(userId: String) -> Bool {
        return follows.contains { $0.followerId == currentUserId && $0.followingId == userId }
    }
    
    // MARK: - Helper Methods
    func timeAgoString(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if hours < 1 {
            return "Just now"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(days)d ago"
        }
    }
    
    func commentTimeString(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        
        if minutes < 1 {
            return "now"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            return "\(hours)h"
        }
    }
    
    // MARK: - Async Methods for UI
    func fetchFeed() async throws -> [SocialPost] {
        await MainActor.run {
            updateFeed()
        }
        return posts
    }
}