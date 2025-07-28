import Foundation

struct Challenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: ChallengeType
    let category: ChallengeCategory
    let difficulty: ChallengeDifficulty
    let duration: Int // days
    let startDate: Date
    let endDate: Date
    let status: ChallengeStatus
    let requirements: [ChallengeRequirement]
    let participants: [Participant]
    let maxParticipants: Int?
    let rewards: [Reward]
    let leaderboard: [LeaderboardEntry]
    let createdBy: String
    let createdAt: Date
    let featured: Bool
    let tags: [String]
    let imageUrl: String?
    let progressMetric: ProgressMetric
    let progressUnit: String
}

enum ChallengeType: String, CaseIterable, Codable {
    case individual = "individual"
    case team = "team"
    case global = "global"
}

enum ChallengeCategory: String, CaseIterable, Codable {
    case workout = "workout"
    case nutrition = "nutrition"
    case steps = "steps"
    case strength = "strength"
    case endurance = "endurance"
    case consistency = "consistency"
}

enum ChallengeDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case extreme = "Extreme"
}

enum ChallengeStatus: String, CaseIterable, Codable {
    case upcoming = "upcoming"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum ProgressMetric: String, CaseIterable, Codable {
    case total = "total"
    case average = "average"
    case best = "best"
    case completionRate = "completion_rate"
}

struct ChallengeRequirement: Identifiable, Codable {
    let id: String
    let type: RequirementType
    let target: Double
    let unit: String
    let description: String
    let exerciseId: String?
}

enum RequirementType: String, CaseIterable, Codable {
    case workoutCount = "workout_count"
    case exerciseReps = "exercise_reps"
    case weightLifted = "weight_lifted"
    case caloriesBurned = "calories_burned"
    case steps = "steps"
    case distance = "distance"
    case duration = "duration"
}

struct Participant: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let avatar: String?
    let joinedAt: Date
    let progress: [String: Double] // requirementId: progress
    let completed: Bool
    let rank: Int?
    let team: String?
}

struct Reward: Identifiable, Codable {
    let id: String
    let type: RewardType
    let name: String
    let description: String
    let value: Double
    let imageUrl: String?
    let condition: RewardCondition
}

enum RewardType: String, CaseIterable, Codable {
    case badge = "badge"
    case points = "points"
    case title = "title"
    case streakMultiplier = "streak_multiplier"
}

enum RewardCondition: String, CaseIterable, Codable {
    case completion = "completion"
    case top3 = "top_3"
    case top10 = "top_10"
    case participation = "participation"
}

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let avatar: String?
    let score: Double
    let progress: Double // percentage
    let rank: Int
    let team: String?
    let lastUpdate: Date
}

struct UserAchievement: Identifiable, Codable {
    let id: String
    let userId: String
    let challengeId: String
    let rewardId: String
    let earnedAt: Date
    let title: String
    let description: String
    let imageUrl: String?
}

struct Team: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let captain: String
    let members: [String]
    let totalScore: Double
    let averageScore: Double
    let createdAt: Date
    let color: String
    let motto: String?
}