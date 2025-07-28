import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    let storage = Storage.storage()
    
    private init() {
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                self?.isAuthenticated = firebaseUser != nil
                if let firebaseUser = firebaseUser {
                    Task {
                        await self?.loadUserProfile(from: firebaseUser)
                    }
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Update profile
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // Create user document in Firestore
        try await createUserDocument(user: result.user, displayName: displayName)
    }
    
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - User Management
    private func createUserDocument(user: FirebaseAuth.User, displayName: String) async throws {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": displayName,
            "username": displayName.lowercased().replacingOccurrences(of: " ", with: "_"),
            "bio": NSNull(),
            "avatar": NSNull(),
            "createdAt": Timestamp(),
            "isVerified": false,
            "stats": [
                "workouts": 0,
                "followers": 0,
                "following": 0,
                "totalVolume": 0.0
            ]
        ]
        
        try await firestore.collection("users").document(user.uid).setData(userData)
    }
    
    private func loadUserProfile(from firebaseUser: FirebaseAuth.User) async {
        do {
            let document = try await firestore.collection("users").document(firebaseUser.uid).getDocument()

            // Safely cast the document data to a [String: Any] dictionary
            guard let data = document.data() else {
                print("No user data found")
                return
            }

            // Extract stats data safely
            let statsDict = data["stats"] as? [String: Any] ?? [:]
            let userStats = UserStats(
                workouts: statsDict["workouts"] as? Int ?? 0,
                followers: statsDict["followers"] as? Int ?? 0,
                following: statsDict["following"] as? Int ?? 0,
                totalVolume: statsDict["totalVolume"] as? Double ?? 0.0,
                totalWorkouts: statsDict["totalWorkouts"] as? Int ?? 0,
                currentStreak: statsDict["currentStreak"] as? Int ?? 0,
                totalPosts: statsDict["totalPosts"] as? Int ?? 0,
                points: statsDict["points"] as? Int ?? 0
            )
            
            // Create user with explicit parameters
            let user = User(
                id: data["uid"] as? String ?? firebaseUser.uid,
                username: data["username"] as? String ?? "",
                displayName: data["displayName"] as? String ?? firebaseUser.displayName ?? "",
                email: firebaseUser.email,
                avatar: data["avatar"] as? String,
                bio: data["bio"] as? String,
                stats: userStats,
                joinDate: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                isVerified: data["isVerified"] as? Bool
            )


            DispatchQueue.main.async { [weak self] in
                self?.currentUser = user
            }
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }

    
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = auth.currentUser else { throw AuthError.noUser }
        
        let changeRequest = user.createProfileChangeRequest()
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        try await changeRequest.commitChanges()
    }
    
    // MARK: - Firestore Operations
    func saveWorkout(_ workout: Workout) async throws {
        guard let userId = auth.currentUser?.uid else { throw AuthError.noUser }
        
        let workoutData = try JSONEncoder().encode(workout)
        let workoutDict = try JSONSerialization.jsonObject(with: workoutData) as! [String: Any]
        
        try await firestore
            .collection("users")
            .document(userId)
            .collection("workouts")
            .document(workout.id)
            .setData(workoutDict)
    }
    
    func fetchWorkouts() async throws -> [Workout] {
        guard let userId = auth.currentUser?.uid else { throw AuthError.noUser }
        
        let snapshot = try await firestore
            .collection("users")
            .document(userId)
            .collection("workouts")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            let data = try JSONSerialization.data(withJSONObject: doc.data())
            return try JSONDecoder().decode(Workout.self, from: data)
        }
    }
    
    func saveNutritionEntry(_ entry: MealEntry) async throws {
        guard let userId = auth.currentUser?.uid else { throw AuthError.noUser }
        
        let entryData = try JSONEncoder().encode(entry)
        let entryDict = try JSONSerialization.jsonObject(with: entryData) as! [String: Any]
        
        try await firestore
            .collection("users")
            .document(userId)
            .collection("nutrition")
            .document(entry.id)
            .setData(entryDict)
    }
    
    // MARK: - Social Features
    func createSocialPost(_ post: SocialPost) async throws {
        let postData = try JSONEncoder().encode(post)
        let postDict = try JSONSerialization.jsonObject(with: postData) as! [String: Any]
        
        try await firestore
            .collection("socialPosts")
            .document(post.id)
            .setData(postDict)
    }
    
    func fetchSocialFeed() async throws -> [SocialPost] {
        let snapshot = try await firestore
            .collection("socialPosts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            let data = try JSONSerialization.data(withJSONObject: doc.data())
            return try JSONDecoder().decode(SocialPost.self, from: data)
        }
    }
    
    // MARK: - Storage
    func uploadImage(_ image: UIImage, path: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return try await storageRef.downloadURL()
    }
}

// MARK: - Errors
enum AuthError: Error, LocalizedError {
    case noUser
    case invalidCredentials
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No authenticated user found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        }
    }
}

enum StorageError: Error, LocalizedError {
    case invalidImage
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .uploadFailed:
            return "Failed to upload image"
        }
    }
}
