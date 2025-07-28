import Foundation

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String
    let avatar: String?
    let bio: String?
    var stats: UserStats
    let joinDate: Date
    let isVerified: Bool?
}

struct UserStats: Codable {
    var workouts: Int
    var followers: Int
    var following: Int
    var totalVolume: Double
}

struct SocialPost: Identifiable, Codable {
    let id: String
    let userId: String
    let type: PostType
    let content: String
    let photos: [String]
    let workoutData: WorkoutData?
    let achievementData: AchievementData?
    var likes: Int
    var likedBy: [String]
    var comments: [Comment]
    let createdAt: Date
    let location: String?
    let tags: [String]
    let visibility: PostVisibility
}

enum PostType: String, CaseIterable, Codable {
    case workout = "workout"
    case progress = "progress"
    case achievement = "achievement"
    case general = "general"
}

struct WorkoutData: Codable {
    let exerciseName: String
    let weight: Double
    let reps: Int
    let sets: Int
    let duration: TimeInterval?
}

struct AchievementData: Codable {
    let type: AchievementType
    let title: String
    let value: String
}

enum AchievementType: String, CaseIterable, Codable {
    case pr = "pr"
    case streak = "streak"
    case milestone = "milestone"
}

enum PostVisibility: String, CaseIterable, Codable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
}

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let content: String
    let createdAt: Date
    var likes: Int
    var likedBy: [String]
    let replies: [Comment]?
}

struct Follow: Codable {
    let followerId: String
    let followingId: String
    let createdAt: Date
}

struct FeedItem: Identifiable {
    let id: String
    let post: SocialPost
    let user: User
    let isLiked: Bool
    let isFollowing: Bool
}