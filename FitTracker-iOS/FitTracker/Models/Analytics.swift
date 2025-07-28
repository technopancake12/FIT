import Foundation
import Firebase
import FirebaseFirestore

// MARK: - User Analytics
struct UserAnalytics: Identifiable, Codable {
    let id: String
    let userId: String
    var totalWorkouts: Int
    var totalVolume: Double
    var totalDuration: TimeInterval
    var workoutsThisWeek: Int
    var workoutsThisMonth: Int
    var averageWorkoutDuration: TimeInterval
    var lastWorkoutDate: Date?
    var strengthMetrics: StrengthMetrics
    var bodyMetrics: BodyMetrics
    var cardioMetrics: CardioMetrics
    var updatedAt: Date
    var currentStreak: Int = 0
    var personalRecords: [PersonalRecord] = []
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        totalWorkouts: Int = 0,
        totalVolume: Double = 0,
        totalDuration: TimeInterval = 0,
        workoutsThisWeek: Int = 0,
        workoutsThisMonth: Int = 0,
        averageWorkoutDuration: TimeInterval = 0,
        lastWorkoutDate: Date? = nil,
        strengthMetrics: StrengthMetrics = StrengthMetrics(),
        bodyMetrics: BodyMetrics = BodyMetrics(),
        cardioMetrics: CardioMetrics = CardioMetrics(),
        updatedAt: Date = Date(),
        currentStreak: Int = 0,
        personalRecords: [PersonalRecord] = []
    ) {
        self.id = id
        self.userId = userId
        self.totalWorkouts = totalWorkouts
        self.totalVolume = totalVolume
        self.totalDuration = totalDuration
        self.workoutsThisWeek = workoutsThisWeek
        self.workoutsThisMonth = workoutsThisMonth
        self.averageWorkoutDuration = averageWorkoutDuration
        self.lastWorkoutDate = lastWorkoutDate
        self.strengthMetrics = strengthMetrics
        self.bodyMetrics = bodyMetrics
        self.cardioMetrics = cardioMetrics
        self.updatedAt = updatedAt
        self.currentStreak = currentStreak
        self.personalRecords = personalRecords
    }
    
    static func createDefault(userId: String) -> UserAnalytics {
        return UserAnalytics(userId: userId)
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "totalWorkouts": totalWorkouts,
            "totalVolume": totalVolume,
            "totalDuration": totalDuration,
            "workoutsThisWeek": workoutsThisWeek,
            "workoutsThisMonth": workoutsThisMonth,
            "averageWorkoutDuration": averageWorkoutDuration,
            "lastWorkoutDate": lastWorkoutDate as Any,
            "strengthMetrics": strengthMetrics.toDictionary(),
            "bodyMetrics": bodyMetrics.toDictionary(),
            "cardioMetrics": cardioMetrics.toDictionary(),
            "updatedAt": Timestamp(date: updatedAt),
            "currentStreak": currentStreak,
            "personalRecords": personalRecords.map { $0.toDictionary() }
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> UserAnalytics? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String else {
            return nil
        }
        
        let strengthData = data["strengthMetrics"] as? [String: Any] ?? [:]
        let bodyData = data["bodyMetrics"] as? [String: Any] ?? [:]
        let cardioData = data["cardioMetrics"] as? [String: Any] ?? [:]
        let recordsData = data["personalRecords"] as? [[String: Any]] ?? []
        let personalRecords = recordsData.compactMap { PersonalRecord.fromFirestore($0) }
        
        return UserAnalytics(
            id: id,
            userId: userId,
            totalWorkouts: data["totalWorkouts"] as? Int ?? 0,
            totalVolume: data["totalVolume"] as? Double ?? 0,
            totalDuration: data["totalDuration"] as? TimeInterval ?? 0,
            workoutsThisWeek: data["workoutsThisWeek"] as? Int ?? 0,
            workoutsThisMonth: data["workoutsThisMonth"] as? Int ?? 0,
            averageWorkoutDuration: data["averageWorkoutDuration"] as? TimeInterval ?? 0,
            lastWorkoutDate: (data["lastWorkoutDate"] as? Timestamp)?.dateValue(),
            strengthMetrics: StrengthMetrics.fromFirestore(strengthData) ?? StrengthMetrics(),
            bodyMetrics: BodyMetrics.fromFirestore(bodyData) ?? BodyMetrics(),
            cardioMetrics: CardioMetrics.fromFirestore(cardioData) ?? CardioMetrics(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            currentStreak: data["currentStreak"] as? Int ?? 0,
            personalRecords: personalRecords
        )
    }
}

// MARK: - Workout Analytics Entry
struct WorkoutAnalyticsEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let workoutId: String
    let date: Date
    let duration: TimeInterval
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
    let averageRPE: Double
    let muscleGroups: [String]
    let exercises: [String]
    let workoutType: String
    let caloriesBurned: Double
    let personalRecords: [PersonalRecord]
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "workoutId": workoutId,
            "date": Timestamp(date: date),
            "duration": duration,
            "totalVolume": totalVolume,
            "totalSets": totalSets,
            "totalReps": totalReps,
            "averageRPE": averageRPE,
            "muscleGroups": muscleGroups,
            "exercises": exercises,
            "workoutType": workoutType,
            "caloriesBurned": caloriesBurned,
            "personalRecords": personalRecords.map { $0.toDictionary() }
        ]
    }
}

// MARK: - Strength Metrics
struct StrengthMetrics: Codable {
    var benchPressMax: Double
    var squatMax: Double
    var deadliftMax: Double
    var overheadPressMax: Double
    var totalLifted: Double
    var strengthScore: Double
    
    init(
        benchPressMax: Double = 0,
        squatMax: Double = 0,
        deadliftMax: Double = 0,
        overheadPressMax: Double = 0,
        totalLifted: Double = 0,
        strengthScore: Double = 0
    ) {
        self.benchPressMax = benchPressMax
        self.squatMax = squatMax
        self.deadliftMax = deadliftMax
        self.overheadPressMax = overheadPressMax
        self.totalLifted = totalLifted
        self.strengthScore = strengthScore
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "benchPressMax": benchPressMax,
            "squatMax": squatMax,
            "deadliftMax": deadliftMax,
            "overheadPressMax": overheadPressMax,
            "totalLifted": totalLifted,
            "strengthScore": strengthScore
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> StrengthMetrics? {
        return StrengthMetrics(
            benchPressMax: data["benchPressMax"] as? Double ?? 0,
            squatMax: data["squatMax"] as? Double ?? 0,
            deadliftMax: data["deadliftMax"] as? Double ?? 0,
            overheadPressMax: data["overheadPressMax"] as? Double ?? 0,
            totalLifted: data["totalLifted"] as? Double ?? 0,
            strengthScore: data["strengthScore"] as? Double ?? 0
        )
    }
}

// MARK: - Body Metrics
struct BodyMetrics: Codable {
    var weight: Double?
    var bodyFatPercentage: Double?
    var muscleMass: Double?
    var height: Double?
    var bmi: Double?
    var measurements: [BodyMeasurement]
    
    init(
        weight: Double? = nil,
        bodyFatPercentage: Double? = nil,
        muscleMass: Double? = nil,
        height: Double? = nil,
        bmi: Double? = nil,
        measurements: [BodyMeasurement] = []
    ) {
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.muscleMass = muscleMass
        self.height = height
        self.bmi = bmi
        self.measurements = measurements
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "weight": weight as Any,
            "bodyFatPercentage": bodyFatPercentage as Any,
            "muscleMass": muscleMass as Any,
            "height": height as Any,
            "bmi": bmi as Any,
            "measurements": measurements.map { $0.toDictionary() }
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> BodyMetrics? {
        let measurementsData = data["measurements"] as? [[String: Any]] ?? []
        let measurements = measurementsData.compactMap { BodyMeasurement.fromFirestore($0) }
        
        return BodyMetrics(
            weight: data["weight"] as? Double,
            bodyFatPercentage: data["bodyFatPercentage"] as? Double,
            muscleMass: data["muscleMass"] as? Double,
            height: data["height"] as? Double,
            bmi: data["bmi"] as? Double,
            measurements: measurements
        )
    }
}

// MARK: - Cardio Metrics
struct CardioMetrics: Codable {
    var totalDistance: Double
    var totalTime: TimeInterval
    var averagePace: Double
    var maxHeartRate: Int
    var averageHeartRate: Int
    var vo2Max: Double?
    
    init(
        totalDistance: Double = 0,
        totalTime: TimeInterval = 0,
        averagePace: Double = 0,
        maxHeartRate: Int = 0,
        averageHeartRate: Int = 0,
        vo2Max: Double? = nil
    ) {
        self.totalDistance = totalDistance
        self.totalTime = totalTime
        self.averagePace = averagePace
        self.maxHeartRate = maxHeartRate
        self.averageHeartRate = averageHeartRate
        self.vo2Max = vo2Max
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "totalDistance": totalDistance,
            "totalTime": totalTime,
            "averagePace": averagePace,
            "maxHeartRate": maxHeartRate,
            "averageHeartRate": averageHeartRate,
            "vo2Max": vo2Max as Any
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> CardioMetrics? {
        return CardioMetrics(
            totalDistance: data["totalDistance"] as? Double ?? 0,
            totalTime: data["totalTime"] as? TimeInterval ?? 0,
            averagePace: data["averagePace"] as? Double ?? 0,
            maxHeartRate: data["maxHeartRate"] as? Int ?? 0,
            averageHeartRate: data["averageHeartRate"] as? Int ?? 0,
            vo2Max: data["vo2Max"] as? Double
        )
    }
}

// MARK: - Body Measurement
struct BodyMeasurement: Identifiable, Codable {
    let id: String
    let type: MeasurementType
    let value: Double
    let unit: String
    let date: Date
    
    init(id: String = UUID().uuidString, type: MeasurementType, value: Double, unit: String, date: Date = Date()) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.date = date
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "value": value,
            "unit": unit,
            "date": Timestamp(date: date)
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> BodyMeasurement? {
        guard let id = data["id"] as? String,
              let typeString = data["type"] as? String,
              let type = MeasurementType(rawValue: typeString),
              let value = data["value"] as? Double,
              let unit = data["unit"] as? String,
              let date = (data["date"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        return BodyMeasurement(id: id, type: type, value: value, unit: unit, date: date)
    }
}

enum MeasurementType: String, CaseIterable, Codable {
    case chest = "chest"
    case waist = "waist"
    case hips = "hips"
    case bicep = "bicep"
    case thigh = "thigh"
    case calf = "calf"
    case neck = "neck"
    case forearm = "forearm"
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .waist: return "Waist"
        case .hips: return "Hips"
        case .bicep: return "Bicep"
        case .thigh: return "Thigh"
        case .calf: return "Calf"
        case .neck: return "Neck"
        case .forearm: return "Forearm"
        }
    }
}

// MARK: - Personal Record
struct PersonalRecord: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let exerciseName: String
    let type: PRType
    let value: Double
    let date: Date
    
    init(id: String = UUID().uuidString, exerciseId: String, exerciseName: String, type: PRType, value: Double, date: Date) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.type = type
        self.value = value
        self.date = date
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "exerciseId": exerciseId,
            "exerciseName": exerciseName,
            "type": type.rawValue,
            "value": value,
            "date": Timestamp(date: date)
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> PersonalRecord? {
        guard let id = data["id"] as? String,
              let exerciseId = data["exerciseId"] as? String,
              let exerciseName = data["exerciseName"] as? String,
              let typeString = data["type"] as? String,
              let type = PRType(rawValue: typeString),
              let value = data["value"] as? Double,
              let date = (data["date"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        return PersonalRecord(id: id, exerciseId: exerciseId, exerciseName: exerciseName, type: type, value: value, date: date)
    }
}

enum PRType: String, CaseIterable, Codable {
    case oneRepMax = "1rm"
    case volume = "volume"
    case reps = "reps"
    case distance = "distance"
    case time = "time"
    
    var displayName: String {
        switch self {
        case .oneRepMax: return "1 Rep Max"
        case .volume: return "Volume"
        case .reps: return "Reps"
        case .distance: return "Distance"
        case .time: return "Time"
        }
    }
    
    var unit: String {
        switch self {
        case .oneRepMax: return "lbs"
        case .volume: return "lbs"
        case .reps: return "reps"
        case .distance: return "miles"
        case .time: return "sec"
        }
    }
}

// MARK: - Progress Snapshot
struct ProgressSnapshot: Identifiable, Codable {
    let id: String
    let userId: String
    let date: Date
    let totalWorkouts: Int
    let totalVolume: Double
    let averageWorkoutDuration: TimeInterval
    let strengthMetrics: StrengthMetrics
    let bodyMetrics: BodyMetrics
    let cardioMetrics: CardioMetrics
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "date": Timestamp(date: date),
            "totalWorkouts": totalWorkouts,
            "totalVolume": totalVolume,
            "averageWorkoutDuration": averageWorkoutDuration,
            "strengthMetrics": strengthMetrics.toDictionary(),
            "bodyMetrics": bodyMetrics.toDictionary(),
            "cardioMetrics": cardioMetrics.toDictionary()
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> ProgressSnapshot? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let date = (data["date"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        let strengthData = data["strengthMetrics"] as? [String: Any] ?? [:]
        let bodyData = data["bodyMetrics"] as? [String: Any] ?? [:]
        let cardioData = data["cardioMetrics"] as? [String: Any] ?? [:]
        
        return ProgressSnapshot(
            id: id,
            userId: userId,
            date: date,
            totalWorkouts: data["totalWorkouts"] as? Int ?? 0,
            totalVolume: data["totalVolume"] as? Double ?? 0,
            averageWorkoutDuration: data["averageWorkoutDuration"] as? TimeInterval ?? 0,
            strengthMetrics: StrengthMetrics.fromFirestore(strengthData) ?? StrengthMetrics(),
            bodyMetrics: BodyMetrics.fromFirestore(bodyData) ?? BodyMetrics(),
            cardioMetrics: CardioMetrics.fromFirestore(cardioData) ?? CardioMetrics()
        )
    }
}

// MARK: - Progress Data Point
struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalVolume: Double
    let totalWorkouts: Int
    let averageDuration: TimeInterval
}

// MARK: - Fitness Goal
struct FitnessGoal: Identifiable, Codable {
    let id: String
    var userId: String
    let type: GoalType
    let title: String
    let description: String
    let targetValue: Double
    let currentProgress: Double
    let targetDate: Date
    let createdAt: Date
    var isCompleted: Bool
    var completedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        userId: String = "",
        type: GoalType,
        title: String,
        description: String,
        targetValue: Double,
        currentProgress: Double = 0,
        targetDate: Date,
        createdAt: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.currentProgress = currentProgress
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentProgress / targetValue * 100, 100)
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "description": description,
            "targetValue": targetValue,
            "currentProgress": currentProgress,
            "targetDate": Timestamp(date: targetDate),
            "createdAt": Timestamp(date: createdAt),
            "isCompleted": isCompleted,
            "completedAt": completedAt != nil ? Timestamp(date: completedAt!) : nil as Any
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> FitnessGoal? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let typeString = data["type"] as? String,
              let type = GoalType(rawValue: typeString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let targetValue = data["targetValue"] as? Double,
              let targetDate = (data["targetDate"] as? Timestamp)?.dateValue(),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        return FitnessGoal(
            id: id,
            userId: userId,
            type: type,
            title: title,
            description: description,
            targetValue: targetValue,
            currentProgress: data["currentProgress"] as? Double ?? 0,
            targetDate: targetDate,
            createdAt: createdAt,
            isCompleted: data["isCompleted"] as? Bool ?? false,
            completedAt: (data["completedAt"] as? Timestamp)?.dateValue()
        )
    }
}

enum GoalType: String, CaseIterable, Codable {
    case workoutCount = "workout_count"
    case totalVolume = "total_volume"
    case weeklyWorkouts = "weekly_workouts"
    case weightLoss = "weight_loss"
    case strengthGoal = "strength_goal"
    case cardioGoal = "cardio_goal"
    
    var displayName: String {
        switch self {
        case .workoutCount: return "Workout Count"
        case .totalVolume: return "Total Volume"
        case .weeklyWorkouts: return "Weekly Workouts"
        case .weightLoss: return "Weight Goal"
        case .strengthGoal: return "Strength Goal"
        case .cardioGoal: return "Cardio Goal"
        }
    }
    
    var icon: String {
        switch self {
        case .workoutCount: return "number.circle"
        case .totalVolume: return "scalemass"
        case .weeklyWorkouts: return "calendar"
        case .weightLoss: return "figure.stand"
        case .strengthGoal: return "dumbbell"
        case .cardioGoal: return "heart"
        }
    }
}

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: String
    var userId: String
    let type: AchievementType
    let title: String
    let description: String
    let icon: String
    let rarity: AchievementRarity
    let earnedAt: Date
    let value: Double?
    
    init(
        id: String = UUID().uuidString,
        userId: String = "",
        type: AchievementType,
        title: String,
        description: String,
        icon: String,
        rarity: AchievementRarity = .common,
        earnedAt: Date = Date(),
        value: Double? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.description = description
        self.icon = icon
        self.rarity = rarity
        self.earnedAt = earnedAt
        self.value = value
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "description": description,
            "icon": icon,
            "rarity": rarity.rawValue,
            "earnedAt": Timestamp(date: earnedAt),
            "value": value as Any
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> Achievement? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let typeString = data["type"] as? String,
              let type = AchievementType(rawValue: typeString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let icon = data["icon"] as? String,
              let rarityString = data["rarity"] as? String,
              let rarity = AchievementRarity(rawValue: rarityString),
              let earnedAt = (data["earnedAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        return Achievement(
            id: id,
            userId: userId,
            type: type,
            title: title,
            description: description,
            icon: icon,
            rarity: rarity,
            earnedAt: earnedAt,
            value: data["value"] as? Double
        )
    }
    
    // MARK: - Achievement Factory Methods
    static func firstWorkout() -> Achievement {
        return Achievement(
            type: .firstWorkout,
            title: "Getting Started",
            description: "Completed your first workout",
            icon: "star.fill",
            rarity: .common
        )
    }
    
    static func tenWorkouts() -> Achievement {
        return Achievement(
            type: .workoutStreak,
            title: "Dedicated",
            description: "Completed 10 workouts",
            icon: "flame.fill",
            rarity: .uncommon,
            value: 10
        )
    }
    
    static func fiftyWorkouts() -> Achievement {
        return Achievement(
            type: .workoutStreak,
            title: "Committed",
            description: "Completed 50 workouts",
            icon: "medal.fill",
            rarity: .rare,
            value: 50
        )
    }
    
    static func hundredWorkouts() -> Achievement {
        return Achievement(
            type: .workoutStreak,
            title: "Elite Athlete",
            description: "Completed 100 workouts",
            icon: "trophy.fill",
            rarity: .legendary,
            value: 100
        )
    }
    
    static func volumeMilestone(volume: Double) -> Achievement {
        let title: String
        let rarity: AchievementRarity
        
        if volume >= 100000 {
            title = "Volume Monster"
            rarity = .legendary
        } else if volume >= 50000 {
            title = "Heavy Lifter"
            rarity = .rare
        } else {
            title = "Volume Builder"
            rarity = .uncommon
        }
        
        return Achievement(
            type: .volumeMilestone,
            title: title,
            description: "Lifted \(Int(volume)) total pounds",
            icon: "scalemass.fill",
            rarity: rarity,
            value: volume
        )
    }
    
    static func weeklyConsistency() -> Achievement {
        return Achievement(
            type: .consistency,
            title: "Weekly Warrior",
            description: "3+ workouts this week",
            icon: "calendar.badge.checkmark",
            rarity: .common
        )
    }
    
    static func monthlyConsistency() -> Achievement {
        return Achievement(
            type: .consistency,
            title: "Monthly Master",
            description: "12+ workouts this month",
            icon: "calendar.badge.plus",
            rarity: .rare
        )
    }
}

enum AchievementType: String, CaseIterable, Codable {
    case firstWorkout = "first_workout"
    case workoutStreak = "workout_streak"
    case volumeMilestone = "volume_milestone"
    case personalRecord = "personal_record"
    case consistency = "consistency"
    case strengthMilestone = "strength_milestone"
    case cardioMilestone = "cardio_milestone"
}

enum AchievementRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
}