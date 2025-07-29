import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private let errorHandler = ErrorHandlingService.shared
    private let timeout: TimeInterval = 30.0
    
    // MARK: - Collections
    private let usersCollection = "users"
    private let workoutsCollection = "workouts"
    private let exercisesCollection = "exercises"
    private let mealsCollection = "meals"
    private let socialPostsCollection = "social_posts"
    private let followsCollection = "follows"
    private let likesCollection = "likes"
    private let commentsCollection = "comments"
    private let challengesCollection = "challenges"
    
    private init() {
        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // MARK: - Error Handling Helpers
    private func executeWithRetry<T>(
        context: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        do {
            return try await withTimeout(timeout: timeout) {
                try await operation()
            }
        } catch {
            errorHandler.handleError(error, context: context)
            throw error
        }
    }
    
    private func withTimeout<T>(
        timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AppError.timeout("Operation timed out after \(timeout) seconds")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func validateUserPermission(for userId: String) throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw AppError.authenticationFailed("User not authenticated")
        }
        
        guard currentUserId == userId else {
            throw AppError.unauthorized("You don't have permission to access this user's data")
        }
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - User Management
    func createUserProfile(_ user: User) async throws {
        try await executeWithRetry(context: "createUserProfile") {
            // Validate user data
            guard !user.username.isEmpty else {
                throw AppError.validationError("Username cannot be empty")
            }
            
            guard !user.displayName.isEmpty else {
                throw AppError.validationError("Display name cannot be empty")
            }
            
            // Check if username is already taken
            let existingUser = try await self.db.collection(self.usersCollection)
                .whereField("username", isEqualTo: user.username)
                .getDocuments()
            
            if !existingUser.documents.isEmpty {
                throw AppError.validationError("Username '\(user.username)' is already taken")
            }
            
            let userData: [String: Any] = [
                "id": user.id,
                "username": user.username,
                "displayName": user.displayName,
                "avatar": user.avatar as Any,
                "bio": user.bio as Any,
                "stats": [
                    "workouts": user.stats.workouts,
                    "followers": user.stats.followers,
                    "following": user.stats.following,
                    "totalVolume": user.stats.totalVolume
                ],
                "joinDate": user.joinDate,
                "isVerified": user.isVerified as Any,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            try await self.db.collection(self.usersCollection).document(user.id).setData(userData)
        }
    }
    
    func getUserProfile(userId: String) async throws -> User? {
        return try await executeWithRetry(context: "getUserProfile") {
            let document = try await self.db.collection(self.usersCollection).document(userId).getDocument()
            
            guard let data = document.data() else { return nil }
            
            return User(
                id: data["id"] as? String ?? userId,
                username: data["username"] as? String ?? "",
                displayName: data["displayName"] as? String ?? "",
                avatar: data["avatar"] as? String,
                bio: data["bio"] as? String,
                stats: UserStats(
                    workouts: (data["stats"] as? [String: Any])?["workouts"] as? Int ?? 0,
                    followers: (data["stats"] as? [String: Any])?["followers"] as? Int ?? 0,
                    following: (data["stats"] as? [String: Any])?["following"] as? Int ?? 0,
                    totalVolume: (data["stats"] as? [String: Any])?["totalVolume"] as? Double ?? 0.0
                ),
                joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
                isVerified: data["isVerified"] as? Bool
            )
        }
    }
    
    func updateUserProfile(_ user: User) async throws {
        let userData: [String: Any] = [
            "username": user.username,
            "displayName": user.displayName,
            "avatar": user.avatar as Any,
            "bio": user.bio as Any,
            "stats": [
                "workouts": user.stats.workouts,
                "followers": user.stats.followers,
                "following": user.stats.following,
                "totalVolume": user.stats.totalVolume
            ],
            "isVerified": user.isVerified as Any,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection(usersCollection).document(user.id).updateData(userData)
    }
    
    // MARK: - Social Features
    func followUser(userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        let batch = db.batch()
        
        // Add follow relationship
        let followRef = db.collection(followsCollection).document()
        batch.setData([
            "followerId": currentUserId,
            "followingId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: followRef)
        
        // Update follower count
        let userRef = db.collection(usersCollection).document(userId)
        batch.updateData(["stats.followers": FieldValue.increment(Int64(1))], forDocument: userRef)
        
        // Update following count
        let currentUserRef = db.collection(usersCollection).document(currentUserId)
        batch.updateData(["stats.following": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
        
        try await batch.commit()
    }
    
    func unfollowUser(userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        let followQuery = db.collection(followsCollection)
            .whereField("followerId", isEqualTo: currentUserId)
            .whereField("followingId", isEqualTo: userId)
        
        let snapshot = try await followQuery.getDocuments()
        
        let batch = db.batch()
        
        // Remove follow relationship
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Update follower count
        let userRef = db.collection(usersCollection).document(userId)
        batch.updateData(["stats.followers": FieldValue.increment(Int64(-1))], forDocument: userRef)
        
        // Update following count
        let currentUserRef = db.collection(usersCollection).document(currentUserId)
        batch.updateData(["stats.following": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
        
        try await batch.commit()
    }
    
    func getFollowedUsers() async throws -> [String] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        let snapshot = try await db.collection(followsCollection)
            .whereField("followerId", isEqualTo: currentUserId)
            .getDocuments()
        
        return snapshot.documents.compactMap { $0.data()["followingId"] as? String }
    }
    
    func isFollowing(userId: String) async throws -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        let snapshot = try await db.collection(followsCollection)
            .whereField("followerId", isEqualTo: currentUserId)
            .whereField("followingId", isEqualTo: userId)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Social Posts
    func createSocialPost(_ post: SocialPost) async throws {
        let postData: [String: Any] = [
            "id": post.id,
            "userId": post.userId,
            "type": post.type.rawValue,
            "content": post.content,
            "photos": post.photos,
            "workoutData": post.workoutData?.toDictionary() ?? NSNull(),
            "achievementData": post.achievementData?.toDictionary() ?? NSNull(),
            "likes": post.likes,
            "likedBy": post.likedBy,
            "comments": post.comments.map { $0.toDictionary() },
            "createdAt": post.createdAt,
            "location": post.location as Any,
            "tags": post.tags,
            "visibility": post.visibility.rawValue
        ]
        
        try await db.collection(socialPostsCollection).document(post.id).setData(postData)
    }
    
    func getFeedPosts(limit: Int = 20) async throws -> [SocialPost] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        // Get followed users
        let followedUsers = try await getFollowedUsers()
        var userIds = followedUsers
        userIds.append(currentUserId) // Include own posts
        
        if userIds.isEmpty {
            return []
        }
        
        let snapshot = try await db.collection(socialPostsCollection)
            .whereField("userId", in: userIds)
            .whereField("visibility", isEqualTo: PostVisibility.public.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            SocialPost.fromFirestore(document.data())
        }
    }
    
    func likePost(postId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        let postRef = db.collection(socialPostsCollection).document(postId)
        
        try await db.runTransaction { transaction, errorPointer in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = postDocument.data() else {
                let error = NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            var likedBy = data["likedBy"] as? [String] ?? []
            var likes = data["likes"] as? Int ?? 0
            
            if !likedBy.contains(currentUserId) {
                likedBy.append(currentUserId)
                likes += 1
                
                transaction.updateData([
                    "likedBy": likedBy,
                    "likes": likes
                ], forDocument: postRef)
            }
            
            return nil
        }
    }
    
    func unlikePost(postId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        let postRef = db.collection(socialPostsCollection).document(postId)
        
        try await db.runTransaction { transaction, errorPointer in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = postDocument.data() else {
                let error = NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            var likedBy = data["likedBy"] as? [String] ?? []
            var likes = data["likes"] as? Int ?? 0
            
            if let index = likedBy.firstIndex(of: currentUserId) {
                likedBy.remove(at: index)
                likes = max(0, likes - 1)
                
                transaction.updateData([
                    "likedBy": likedBy,
                    "likes": likes
                ], forDocument: postRef)
            }
            
            return nil
        }
    }
    
    // MARK: - Workouts
    func saveWorkout(_ workout: EnhancedWorkout) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        let workoutData: [String: Any] = [
            "id": workout.id,
            "userId": currentUserId,
            "name": workout.name,
            "date": workout.date,
            "exercises": workout.exercises.map { $0.toDictionary() },
            "duration": workout.duration as Any,
            "completed": workout.completed,
            "notes": workout.notes as Any,
            "templateId": workout.templateId as Any,
            "tags": workout.tags,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection(workoutsCollection).document(workout.id).setData(workoutData)
        
        // Update user stats
        if workout.completed {
            let userRef = db.collection(usersCollection).document(currentUserId)
            try await userRef.updateData([
                "stats.workouts": FieldValue.increment(Int64(1)),
                "stats.totalVolume": FieldValue.increment(Int64(workout.totalVolume))
            ])
        }
    }
    
    func getUserWorkouts(userId: String, limit: Int = 50) async throws -> [EnhancedWorkout] {
        let snapshot = try await db.collection(workoutsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            EnhancedWorkout.fromFirestore(document.data())
        }
    }
    
    // MARK: - Meals
    func saveMeal(_ meal: MealEntry) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { throw AuthError.noUser }
        
        let mealData: [String: Any] = [
            "id": meal.id,
            "userId": currentUserId,
            "date": meal.date,
            "mealType": meal.mealType.rawValue,
            "foods": meal.foods.map { $0.toDictionary() },
            "notes": meal.notes as Any,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection(mealsCollection).document(meal.id).setData(mealData)
    }
    
    func getUserMeals(userId: String, startDate: Date, endDate: Date) async throws -> [MealEntry] {
        let snapshot = try await db.collection(mealsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            MealEntry.fromFirestore(document.data())
        }
    }
    
    // MARK: - Real-time Listeners
    func listenToFeedPosts(completion: @escaping ([SocialPost]) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let followedUsers = try await getFollowedUsers()
                var userIds = followedUsers
                userIds.append(currentUserId)
                
                if !userIds.isEmpty {
                    let listener = db.collection(socialPostsCollection)
                        .whereField("userId", in: userIds)
                        .whereField("visibility", isEqualTo: PostVisibility.public.rawValue)
                        .order(by: "createdAt", descending: true)
                        .limit(to: 50)
                        .addSnapshotListener { snapshot, error in
                            if let error = error {
                                print("Error listening to feed posts: \(error)")
                                return
                            }
                            
                            let posts = snapshot?.documents.compactMap { document in
                                SocialPost.fromFirestore(document.data())
                            } ?? []
                            
                            DispatchQueue.main.async {
                                completion(posts)
                            }
                        }
                    
                    listeners.append(listener)
                }
            } catch {
                print("Error setting up feed listener: \(error)")
            }
        }
    }
    
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Search
    func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
        let snapshot = try await db.collection(usersCollection)
            .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("username", isLessThan: query.lowercased() + "z")
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return User(
                id: data["id"] as? String ?? "",
                username: data["username"] as? String ?? "",
                displayName: data["displayName"] as? String ?? "",
                avatar: data["avatar"] as? String,
                bio: data["bio"] as? String,
                stats: UserStats(
                    workouts: (data["stats"] as? [String: Any])?["workouts"] as? Int ?? 0,
                    followers: (data["stats"] as? [String: Any])?["followers"] as? Int ?? 0,
                    following: (data["stats"] as? [String: Any])?["following"] as? Int ?? 0,
                    totalVolume: (data["stats"] as? [String: Any])?["totalVolume"] as? Double ?? 0.0
                ),
                joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
                isVerified: data["isVerified"] as? Bool
            )
        }
    }
    
    // MARK: - Error Handling and Retry Logic
    private func withErrorHandling<T>(
        context: String,
        maxRetries: Int = 3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if !shouldRetryError(error) || attempt == maxRetries {
                    errorHandler.handleError(error, context: context)
                    throw error
                }
                
                // Exponential backoff with jitter
                let delay = min(pow(2.0, Double(attempt - 1)) + Double.random(in: 0...1), 30.0)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? AppError.unknown("Unknown error in \(context)")
    }
    
    private func shouldRetryError(_ error: Error) -> Bool {
        let nsError = error as NSError
        switch nsError.domain {
            case "FIRFirestoreErrorDomain":
                switch nsError.code {
                case 14: // UNAVAILABLE
                    return true
                case 4: // DEADLINE_EXCEEDED
                    return true
                case 2: // UNKNOWN
                    return true
                default:
                    return false
                }
            case NSURLErrorDomain:
                switch nsError.code {
                case NSURLErrorTimedOut,
                     NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost:
                    return true
                default:
                    return false
                }
            default:
                return false
            }
        }
        return false
    }
    
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AppError.timeout("Operation timed out after \(seconds) seconds")
            }
            
            guard let result = try await group.next() else {
                throw AppError.timeout("Operation timed out")
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // Note: removeAllListeners() is already defined as a public method


// MARK: - Extensions for Firestore Conversion
extension WorkoutData {
    func toDictionary() -> [String: Any] {
        return [
            "exerciseName": exerciseName,
            "weight": weight,
            "reps": reps,
            "sets": sets,
            "duration": duration as Any
        ]
    }
}

extension AchievementData {
    func toDictionary() -> [String: Any] {
        return [
            "type": type,
            "title": title,
            "description": description,
            "value": value
        ]
    }
}

extension Comment {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "content": content,
            "createdAt": createdAt,
            "likes": likes,
            "likedBy": likedBy
        ]
    }
}

extension FoodEntry {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "food": [
                "id": food.id,
                "name": food.name,
                "brand": food.brand as Any,
                "barcode": food.barcode as Any,
                "calories": food.calories,
                "protein": food.protein,
                "carbs": food.carbs,
                "fat": food.fat,
                "fiber": food.fiber as Any,
                "sugar": food.sugar as Any,
                "sodium": food.sodium as Any,
                "category": food.category,
                "servingSize": food.servingSize as Any,
                "servingUnit": food.servingUnit as Any,
                "isVerified": food.isVerified,
                "imageUrl": food.imageUrl as Any
            ],
            "actualServingSize": actualServingSize
        ]
    }
}

extension EnhancedWorkoutExercise {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "exerciseId": exerciseId,
            "name": name,
            "category": category,
            "primaryMuscles": primaryMuscles,
            "secondaryMuscles": secondaryMuscles,
            "equipment": equipment,
            "sets": sets.map { $0.toDictionary() },
            "notes": notes as Any,
            "targetSets": targetSets as Any,
            "targetReps": targetReps as Any,
            "targetWeight": targetWeight as Any,
            "restTime": restTime as Any,
            "imageUrls": imageUrls
        ]
    }
}

extension EnhancedWorkoutSet {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "reps": reps,
            "weight": weight,
            "restTime": restTime as Any,
            "completed": completed,
            "rpe": rpe as Any,
            "notes": notes as Any,
            "duration": duration as Any,
            "timestamp": timestamp
        ]
    }
}

// MARK: - Firestore to Model Conversion
extension SocialPost {
    static func fromFirestore(_ data: [String: Any]) -> SocialPost? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let typeString = data["type"] as? String,
              let type = PostType(rawValue: typeString),
              let content = data["content"] as? String,
              let createdAt = data["createdAt"] as? Date,
              let visibilityString = data["visibility"] as? String,
              let visibility = PostVisibility(rawValue: visibilityString) else {
            return nil
        }
        
        return SocialPost(
            id: id,
            userId: userId,
            type: type,
            content: content,
            photos: data["photos"] as? [String] ?? [],
            workoutData: WorkoutData.fromFirestore(data["workoutData"] as? [String: Any]),
            achievementData: AchievementData.fromFirestore(data["achievementData"] as? [String: Any]),
            likes: data["likes"] as? Int ?? 0,
            likedBy: data["likedBy"] as? [String] ?? [],
            comments: Comment.fromFirestoreArray(data["comments"] as? [[String: Any]] ?? []),
            createdAt: createdAt,
            location: data["location"] as? String,
            tags: data["tags"] as? [String] ?? [],
            visibility: visibility
        )
    }
}

extension WorkoutData {
    static func fromFirestore(_ data: [String: Any]?) -> WorkoutData? {
        guard let data = data,
              let exerciseName = data["exerciseName"] as? String,
              let weight = data["weight"] as? Double,
              let reps = data["reps"] as? Int,
              let sets = data["sets"] as? Int else {
            return nil
        }
        
        return WorkoutData(
            exerciseName: exerciseName,
            weight: weight,
            reps: reps,
            sets: sets,
            duration: data["duration"] as? TimeInterval
        )
    }
}

extension AchievementData {
    static func fromFirestore(_ data: [String: Any]?) -> AchievementData? {
        guard let data = data,
              let type = data["type"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let value = data["value"] as? String else {
            return nil
        }
        
        return AchievementData(type: type, title: title, description: description, value: value)
    }
}

extension Comment {
    static func fromFirestoreArray(_ dataArray: [[String: Any]]) -> [Comment] {
        return dataArray.compactMap { data -> Comment? in
            guard let id = data["id"] as? String,
                  let userId = data["userId"] as? String,
                  let content = data["content"] as? String,
                  let createdAt = data["createdAt"] as? Date else {
                return nil
            }
            
            return Comment(
                id: id,
                userId: userId,
                content: content,
                createdAt: createdAt,
                likes: data["likes"] as? Int ?? 0,
                likedBy: data["likedBy"] as? [String] ?? [], replies: [Comment]?
            )
        }
    }
}

extension MealEntry {
    static func fromFirestore(_ data: [String: Any]) -> MealEntry? {
        guard let id = data["id"] as? String,
              let date = data["date"] as? Date,
              let mealTypeString = data["mealType"] as? String,
              let mealType = MealType(rawValue: mealTypeString),
              let foodsData = data["foods"] as? [[String: Any]] else {
            return nil
        }
        
        let foods = foodsData.compactMap { FoodEntry.fromFirestore($0) }
        
        return MealEntry(
            id: id,
            date: date,
            mealType: mealType,
            foods: foods,
            notes: data["notes"] as? String
        )
    }
}

extension FoodEntry {
    static func fromFirestore(_ data: [String: Any]) -> FoodEntry? {
        guard let id = data["id"] as? String,
              let foodData = data["food"] as? [String: Any],
              let actualServingSize = data["actualServingSize"] as? Double else {
            return nil
        }
        
        guard let food = Food.fromFirestore(foodData) else { return nil }
        
        return FoodEntry(id: id, food: food, servingSize: actualServingSize)
    }
}

extension Food {
    static func fromFirestore(_ data: [String: Any]) -> Food? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let calories = data["calories"] as? Double,
              let protein = data["protein"] as? Double,
              let carbs = data["carbs"] as? Double,
              let fat = data["fat"] as? Double,
              let category = data["category"] as? String,
              let isVerified = data["isVerified"] as? Bool else {
            return nil
        }
        
        return Food(
            id: id,
            name: name,
            brand: data["brand"] as? String,
            barcode: data["barcode"] as? String,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: data["fiber"] as? Double,
            sugar: data["sugar"] as? Double,
            sodium: data["sodium"] as? Double,
            category: category,
            servingSize: data["servingSize"] as? Double,
            servingUnit: data["servingUnit"] as? String,
            isVerified: isVerified,
            imageUrl: data["imageUrl"] as? String
        )
    }
}

extension EnhancedWorkout {
    static func fromFirestore(_ data: [String: Any]) -> EnhancedWorkout? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let date = data["date"] as? Date,
              let completed = data["completed"] as? Bool,
              let exercisesData = data["exercises"] as? [[String: Any]] else {
            return nil
        }
        
        let exercises = exercisesData.compactMap { EnhancedWorkoutExercise.fromFirestore($0) }
        
        return EnhancedWorkout(
            id: id,
            name: name,
            date: date,
            exercises: exercises,
            duration: data["duration"] as? TimeInterval,
            completed: completed,
            notes: data["notes"] as? String,
            templateId: data["templateId"] as? String,
            tags: data["tags"] as? [String] ?? []
        )
    }
}

extension EnhancedWorkoutExercise {
    static func fromFirestore(_ data: [String: Any]) -> EnhancedWorkoutExercise? {
        guard let id = data["id"] as? String,
              let exerciseId = data["exerciseId"] as? String,
              let name = data["name"] as? String,
              let setsData = data["sets"] as? [[String: Any]] else {
            return nil
        }
        
        let sets = setsData.compactMap { EnhancedWorkoutSet.fromFirestore($0) }
        
        return EnhancedWorkoutExercise(
            id: id,
            exerciseId: exerciseId,
            name: name,
            category: data["category"] as? String ?? "",
            primaryMuscles: data["primaryMuscles"] as? [String] ?? [],
            secondaryMuscles: data["secondaryMuscles"] as? [String] ?? [],
            equipment: data["equipment"] as? String ?? "",
            sets: sets,
            notes: data["notes"] as? String,
            targetSets: data["targetSets"] as? Int,
            targetReps: data["targetReps"] as? Int,
            targetWeight: data["targetWeight"] as? Double,
            restTime: data["restTime"] as? TimeInterval,
            imageUrls: data["imageUrls"] as? [String] ?? []
        )
    }
}

extension EnhancedWorkoutSet {
    static func fromFirestore(_ data: [String: Any]) -> EnhancedWorkoutSet? {
        guard let id = data["id"] as? String,
              let reps = data["reps"] as? Int,
              let weight = data["weight"] as? Double,
              let completed = data["completed"] as? Bool,
              let timestamp = data["timestamp"] as? Date else {
            return nil
        }
        
        return EnhancedWorkoutSet(
            id: id,
            reps: reps,
            weight: weight,
            restTime: data["restTime"] as? TimeInterval,
            completed: completed,
            rpe: data["rpe"] as? Int,
            notes: data["notes"] as? String,
            duration: data["duration"] as? TimeInterval,
            timestamp: timestamp
        )
    }
}
