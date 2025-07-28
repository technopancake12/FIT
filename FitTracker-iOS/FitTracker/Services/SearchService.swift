import Foundation
import Firebase
import FirebaseFirestore

class SearchService: ObservableObject {
    static let shared = SearchService()
    
    private let db = Firestore.firestore()
    private let firebaseManager = FirebaseManager.shared
    private let wgerService = WgerAPIService.shared
    
    private init() {}
    
    // MARK: - Advanced Search
    func performAdvancedSearch(
        query: String,
        type: SearchType,
        filters: SearchFilters
    ) async throws -> SearchResults {
        var results = SearchResults()
        
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch type {
        case .all:
            // Search all categories in parallel
            async let users = searchUsers(query: normalizedQuery, filters: filters)
            async let workouts = searchWorkouts(query: normalizedQuery, filters: filters)
            async let exercises = searchExercises(query: normalizedQuery, filters: filters)
            async let posts = searchPosts(query: normalizedQuery, filters: filters)
            
            results.users = try await users
            results.workouts = try await workouts
            results.exercises = try await exercises
            results.posts = try await posts
            
        case .users:
            results.users = try await searchUsers(query: normalizedQuery, filters: filters)
            
        case .workouts:
            results.workouts = try await searchWorkouts(query: normalizedQuery, filters: filters)
            
        case .exercises:
            results.exercises = try await searchExercises(query: normalizedQuery, filters: filters)
            
        case .posts:
            results.posts = try await searchPosts(query: normalizedQuery, filters: filters)
        }
        
        return results
    }
    
    // MARK: - User Search
    private func searchUsers(query: String, filters: SearchFilters) async throws -> [User] {
        var firebaseQuery = db.collection("users").limit(to: 50)
        
        // Apply filters
        if let isVerified = filters.isVerified {
            firebaseQuery = firebaseQuery.whereField("isVerified", isEqualTo: isVerified)
        }
        
        // Firestore doesn't support full-text search, so we'll do client-side filtering
        let snapshot = try await firebaseQuery.getDocuments()
        
        let allUsers = snapshot.documents.compactMap { document -> User? in
            let data = document.data()
            return User(
                id: data["id"] as? String ?? document.documentID,
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
        
        // Client-side filtering and ranking
        let filteredUsers = allUsers.filter { user in
            let searchFields = [
                user.username,
                user.displayName,
                user.bio ?? ""
            ].joined(separator: " ").lowercased()
            
            return searchFields.contains(query)
        }
        
        // Rank results by relevance
        return rankUserResults(filteredUsers, query: query)
    }
    
    private func rankUserResults(_ users: [User], query: String) -> [User] {
        return users.sorted { user1, user2 in
            let score1 = calculateUserRelevanceScore(user1, query: query)
            let score2 = calculateUserRelevanceScore(user2, query: query)
            return score1 > score2
        }
    }
    
    private func calculateUserRelevanceScore(_ user: User, query: String) -> Double {
        var score = 0.0
        
        // Exact username match gets highest score
        if user.username.lowercased() == query {
            score += 100.0
        } else if user.username.lowercased().hasPrefix(query) {
            score += 50.0
        } else if user.username.lowercased().contains(query) {
            score += 25.0
        }
        
        // Display name match
        if user.displayName.lowercased().contains(query) {
            score += 20.0
        }
        
        // Bio match
        if user.bio?.lowercased().contains(query) == true {
            score += 10.0
        }
        
        // Boost verified users
        if user.isVerified == true {
            score += 5.0
        }
        
        // Boost users with more followers
        score += Double(user.stats.followers) * 0.01
        
        return score
    }
    
    // MARK: - Workout Search
    private func searchWorkouts(query: String, filters: SearchFilters) async throws -> [EnhancedWorkout] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        var firebaseQuery = db.collection("workouts")
            .whereField("userId", isEqualTo: currentUserId)
            .limit(to: 50)
        
        // Apply date range filter
        if let dateRange = filters.dateRange {
            firebaseQuery = firebaseQuery
                .whereField("date", isGreaterThanOrEqualTo: dateRange.lowerBound)
                .whereField("date", isLessThanOrEqualTo: dateRange.upperBound)
        }
        
        let snapshot = try await firebaseQuery.getDocuments()
        
        let allWorkouts = snapshot.documents.compactMap { document -> EnhancedWorkout? in
            return EnhancedWorkout.fromFirestore(document.data())
        }
        
        // Client-side filtering
        let filteredWorkouts = allWorkouts.filter { workout in
            let searchFields = [
                workout.name,
                workout.notes ?? "",
                workout.exercises.map { $0.name }.joined(separator: " "),
                workout.tags.joined(separator: " ")
            ].joined(separator: " ").lowercased()
            
            var matches = searchFields.contains(query)
            
            // Apply additional filters
            if let workoutType = filters.workoutType {
                matches = matches && workout.tags.contains(workoutType.lowercased())
            }
            
            if let muscleGroup = filters.muscleGroup {
                let workoutMuscles = workout.exercises.flatMap { $0.primaryMuscles }
                matches = matches && workoutMuscles.contains { $0.lowercased().contains(muscleGroup.lowercased()) }
            }
            
            return matches
        }
        
        return filteredWorkouts.sorted { $0.date > $1.date }
    }
    
    // MARK: - Exercise Search
    private func searchExercises(query: String, filters: SearchFilters) async throws -> [WgerExercise] {
        // Use WGER API for exercise search
        let exercises = try await wgerService.searchExercises(query: query)
        
        var filteredExercises = exercises
        
        // Apply filters
        if let muscleGroup = filters.muscleGroup {
            filteredExercises = filteredExercises.filter { exercise in
                exercise.muscles.contains { muscle in
                    muscle.safeName.lowercased().contains(muscleGroup.lowercased())
                }
            }
        }
        
        if !filters.equipment.isEmpty {
            filteredExercises = filteredExercises.filter { exercise in
                exercise.equipment.contains { equipment in
                    filters.equipment.contains { filter in
                        equipment.safeName.lowercased().contains(filter.lowercased())
                    }
                }
            }
        }
        
        return filteredExercises
    }
    
    // MARK: - Post Search
    private func searchPosts(query: String, filters: SearchFilters) async throws -> [SocialPost] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        // Get followed users for filtering
        let followedUsers = try await firebaseManager.getFollowedUsers()
        var userIds = followedUsers
        userIds.append(currentUserId)
        
        if userIds.isEmpty {
            return []
        }
        
        // Search posts from followed users and self
        var firebaseQuery = db.collection("social_posts")
            .whereField("userId", in: userIds)
            .whereField("visibility", isEqualTo: "public")
            .limit(to: 100)
        
        // Apply date range filter
        if let dateRange = filters.dateRange {
            firebaseQuery = firebaseQuery
                .whereField("createdAt", isGreaterThanOrEqualTo: dateRange.lowerBound)
                .whereField("createdAt", isLessThanOrEqualTo: dateRange.upperBound)
        }
        
        let snapshot = try await firebaseQuery.getDocuments()
        
        let allPosts = snapshot.documents.compactMap { document -> SocialPost? in
            return SocialPost.fromFirestore(document.data())
        }
        
        // Client-side filtering
        let filteredPosts = allPosts.filter { post in
            let searchFields = [
                post.content,
                post.tags.joined(separator: " "),
                post.workoutData?.exerciseName ?? ""
            ].joined(separator: " ").lowercased()
            
            return searchFields.contains(query)
        }
        
        return filteredPosts.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Auto-complete Suggestions
    func getSearchSuggestions(for query: String, type: SearchType) async throws -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch type {
        case .all, .users:
            // Get user suggestions
            let userSuggestions = try await getUserSuggestions(query: normalizedQuery)
            suggestions.append(contentsOf: userSuggestions)
            
        case .exercises:
            // Get exercise suggestions
            let exerciseSuggestions = try await getExerciseSuggestions(query: normalizedQuery)
            suggestions.append(contentsOf: exerciseSuggestions)
            
        case .workouts:
            // Get workout name suggestions
            let workoutSuggestions = try await getWorkoutSuggestions(query: normalizedQuery)
            suggestions.append(contentsOf: workoutSuggestions)
            
        case .posts:
            // Get hashtag suggestions
            let hashtagSuggestions = try await getHashtagSuggestions(query: normalizedQuery)
            suggestions.append(contentsOf: hashtagSuggestions)
        }
        
        return Array(suggestions.prefix(10))
    }
    
    private func getUserSuggestions(query: String) async throws -> [SearchSuggestion] {
        let users = try await searchUsers(query: query, filters: SearchFilters())
        return users.prefix(5).map { user in
            SearchSuggestion(
                text: user.username,
                type: .user,
                subtitle: user.displayName,
                imageUrl: user.avatar
            )
        }
    }
    
    private func getExerciseSuggestions(query: String) async throws -> [SearchSuggestion] {
        let exercises = try await searchExercises(query: query, filters: SearchFilters())
        return exercises.prefix(5).map { exercise in
            SearchSuggestion(
                text: exercise.safeName,
                type: .exercise,
                subtitle: exercise.safeCategory,
                imageUrl: nil
            )
        }
    }
    
    private func getWorkoutSuggestions(query: String) async throws -> [SearchSuggestion] {
        let workouts = try await searchWorkouts(query: query, filters: SearchFilters())
        let uniqueNames = Set(workouts.map { $0.name })
        
        return uniqueNames.prefix(5).map { name in
            SearchSuggestion(
                text: name,
                type: .workout,
                subtitle: nil,
                imageUrl: nil
            )
        }
    }
    
    private func getHashtagSuggestions(query: String) async throws -> [SearchSuggestion] {
        // In a real implementation, this would query a hashtags collection
        // For now, return popular hashtags that match the query
        let popularHashtags = [
            "pushday", "pullday", "legday", "cardio", "strength",
            "deadlift", "squat", "benchpress", "protein", "gains",
            "morningworkout", "homegym", "motivation", "progress"
        ]
        
        let matchingHashtags = popularHashtags.filter { $0.contains(query) }
        
        return matchingHashtags.prefix(5).map { hashtag in
            SearchSuggestion(
                text: "#\(hashtag)",
                type: .hashtag,
                subtitle: nil,
                imageUrl: nil
            )
        }
    }
    
    // MARK: - Search Analytics
    func logSearchEvent(query: String, type: SearchType, resultsCount: Int) {
        // Log search analytics for improving search functionality
        let searchEvent: [String: Any] = [
            "query": query,
            "type": type.rawValue,
            "resultsCount": resultsCount,
            "timestamp": FieldValue.serverTimestamp(),
            "userId": Auth.auth().currentUser?.uid ?? "anonymous"
        ]
        
        db.collection("search_analytics").addDocument(data: searchEvent)
    }
    
    // MARK: - Search History
    func saveSearchToHistory(_ query: String, type: SearchType) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let searchHistoryData: [String: Any] = [
            "query": query,
            "type": type.rawValue,
            "timestamp": FieldValue.serverTimestamp(),
            "userId": currentUserId
        ]
        
        db.collection("search_history").addDocument(data: searchHistoryData)
    }
    
    func getSearchHistory(limit: Int = 10) async throws -> [SearchHistoryItem] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        let snapshot = try await db.collection("search_history")
            .whereField("userId", isEqualTo: currentUserId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let query = data["query"] as? String,
                  let typeString = data["type"] as? String,
                  let type = SearchType(rawValue: typeString),
                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                return nil
            }
            
            return SearchHistoryItem(
                query: query,
                type: type,
                timestamp: timestamp
            )
        }
    }
}

// MARK: - Supporting Types
struct SearchSuggestion {
    let text: String
    let type: SuggestionType
    let subtitle: String?
    let imageUrl: String?
    
    enum SuggestionType {
        case user
        case exercise
        case workout
        case hashtag
    }
}

struct SearchHistoryItem {
    let query: String
    let type: SearchType
    let timestamp: Date
}

// MARK: - WGER API Extension
extension WgerAPIService {
    func searchExercises(query: String) async throws -> [WgerExercise] {
        var exercises: [WgerExercise] = []
        
        do {
            // Search exercises by name (mock implementation)
            // In reality, this would make an API call to WGER
            exercises = try await getExercises(page: 1, limit: 50)
            
            // Filter exercises that match the query
            exercises = exercises.filter { exercise in
                exercise.safeName.lowercased().contains(query.lowercased()) ||
                exercise.safeDescription.lowercased().contains(query.lowercased())
            }
        } catch {
            print("Error searching WGER exercises: \(error)")
            // Return empty array on error
        }
        
        return exercises
    }
}