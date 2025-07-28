import Foundation
import SwiftUI

class SocialService: ObservableObject {
    @Published var posts: [SocialPost] = []
    @Published var users: [User] = []
    @Published var follows: [Follow] = []
    @Published var feed: [FeedItem] = []
    
    private let currentUserId = "user_1"
    
    init() {
        loadFromStorage()
        initializeMockData()
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
    
    // MARK: - Mock Data Initialization
    private func initializeMockData() {
        if users.isEmpty {
            users = [
                User(
                    id: "user_1",
                    username: "you",
                    displayName: "You",
                    avatar: nil,
                    bio: "Fitness enthusiast 💪",
                    stats: UserStats(workouts: 45, followers: 12, following: 8, totalVolume: 15000),
                    joinDate: Date(timeIntervalSinceNow: -365*24*60*60),
                    isVerified: false
                ),
                User(
                    id: "user_2",
                    username: "mikefitness",
                    displayName: "Mike Johnson",
                    avatar: nil,
                    bio: "Personal trainer | Powerlifter 🏋️‍♂️",
                    stats: UserStats(workouts: 250, followers: 1200, following: 150, totalVolume: 85000),
                    joinDate: Date(timeIntervalSinceNow: -200*24*60*60),
                    isVerified: true
                ),
                User(
                    id: "user_3",
                    username: "sarahstrong",
                    displayName: "Sarah Williams",
                    avatar: nil,
                    bio: "Crossfit athlete | Nutrition coach 🥗",
                    stats: UserStats(workouts: 180, followers: 800, following: 95, totalVolume: 62000),
                    joinDate: Date(timeIntervalSinceNow: -150*24*60*60),
                    isVerified: true
                ),
                User(
                    id: "user_4",
                    username: "alexruns",
                    displayName: "Alex Chen",
                    avatar: nil,
                    bio: "Marathon runner | Yoga instructor 🧘‍♀️",
                    stats: UserStats(workouts: 120, followers: 450, following: 200, totalVolume: 25000),
                    joinDate: Date(timeIntervalSinceNow: -30*24*60*60),
                    isVerified: false
                )
            ]
        }
        
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
                        type: .streak,
                        title: "100 Day Streak",
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
}