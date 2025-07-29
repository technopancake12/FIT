import Foundation

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String
    let email: String?
    let avatar: String?
    let bio: String?
    var stats: UserStats
    let joinDate: Date
    let createdAt: Date
    let isVerified: Bool?
    
    init(id: String, username: String, displayName: String, email: String? = nil, avatar: String? = nil, bio: String? = nil, stats: UserStats = UserStats(), joinDate: Date = Date(), createdAt: Date = Date(), isVerified: Bool? = false) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.email = email
        self.avatar = avatar
        self.bio = bio
        self.stats = stats
        self.joinDate = joinDate
        self.createdAt = createdAt
        self.isVerified = isVerified
    }
}

struct UserStats: Codable {
    var workouts: Int
    var followers: Int
    var following: Int
    var totalVolume: Double
    var totalWorkouts: Int
    var currentStreak: Int
    var totalPosts: Int
    var points: Int
    
    init(workouts: Int = 0, followers: Int = 0, following: Int = 0, totalVolume: Double = 0, totalWorkouts: Int = 0, currentStreak: Int = 0, totalPosts: Int = 0, points: Int = 0) {
        self.workouts = workouts
        self.followers = followers
        self.following = following
        self.totalVolume = totalVolume
        self.totalWorkouts = totalWorkouts
        self.currentStreak = currentStreak
        self.totalPosts = totalPosts
        self.points = points
    }
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
    
    // UI convenience properties
    var userName: String { return "User" } // This would be populated from the User data
    var userAvatar: String? { return nil } // This would be populated from the User data
    var timestamp: Date { return createdAt }
    var isLiked: Bool { return false } // This would be computed based on current user
    var likesCount: Int { return likes }
    var commentsCount: Int { return comments.count }
    var imageUrl: String? { return photos.first }
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
    let type: String
    let title: String
    let description: String
    let value: String
}

// Note: AchievementType is defined in Analytics.swift

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

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let email: String
    let avatarUrl: String?
    let bio: String?
    let dateOfBirth: Date?
    let height: Double? // in cm
    let weight: Double? // in kg
    let fitnessLevel: FitnessLevel
    let goals: [FitnessGoal]
    let preferences: UserPreferences
    let privacySettings: PrivacySettings
    let createdAt: Date
    let updatedAt: Date
    
    enum FitnessLevel: String, CaseIterable, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
    }
    
    enum FitnessGoal: String, CaseIterable, Codable {
        case weightLoss = "weight_loss"
        case muscleGain = "muscle_gain"
        case strength = "strength"
        case endurance = "endurance"
        case generalFitness = "general_fitness"
        case maintenance = "maintenance"
    }
    
    struct UserPreferences: Codable {
        let units: MeasurementUnits
        let notifications: NotificationPreferences
        let theme: AppTheme
        
        enum MeasurementUnits: String, CaseIterable, Codable {
            case metric = "metric"
            case imperial = "imperial"
        }
        
        enum AppTheme: String, CaseIterable, Codable {
            case light = "light"
            case dark = "dark"
            case system = "system"
        }
    }
    
    struct NotificationPreferences: Codable {
        let workoutReminders: Bool
        let progressUpdates: Bool
        let socialInteractions: Bool
        let achievements: Bool
    }
    
    struct PrivacySettings: Codable {
        let profileVisibility: ProfileVisibility
        let workoutVisibility: WorkoutVisibility
        let progressVisibility: ProgressVisibility
        
        enum ProfileVisibility: String, CaseIterable, Codable {
            case `public` = "public"
            case friends = "friends"
            case `private` = "private"
        }
        
        enum WorkoutVisibility: String, CaseIterable, Codable {
            case `public` = "public"
            case friends = "friends"
            case `private` = "private"
        }
        
        enum ProgressVisibility: String, CaseIterable, Codable {
            case `public` = "public"
            case friends = "friends"
            case `private` = "private"
        }
    }
}