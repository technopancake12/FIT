import Foundation
import UserNotifications
import Firebase
import FirebaseMessaging

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var fcmToken: String?
    @Published var hasPermission = false
    
    private override init() {
        super.init()
        setupMessaging()
    }
    
    // MARK: - Setup
    private func setupMessaging() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // Configure notification categories
        configureNotificationCategories()
    }
    
    // MARK: - Permission Request
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                self.hasPermission = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Token Management
    func updateFCMToken() async {
        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
            }
            
            // Save token to Firestore for the current user
            if let currentUserId = Auth.auth().currentUser?.uid {
                try await saveFCMToken(token, for: currentUserId)
            }
        } catch {
            print("Error fetching FCM token: \(error)")
        }
    }
    
    private func saveFCMToken(_ token: String, for userId: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token,
            "lastTokenUpdate": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Notification Categories
    private func configureNotificationCategories() {
        let likeAction = UNNotificationAction(
            identifier: "LIKE_ACTION",
            title: "❤️ Like",
            options: []
        )
        
        let commentAction = UNNotificationAction(
            identifier: "COMMENT_ACTION",
            title: "💬 Comment",
            options: [.foreground]
        )
        
        let followAction = UNNotificationAction(
            identifier: "FOLLOW_BACK_ACTION",
            title: "👥 Follow Back",
            options: []
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "👀 View",
            options: [.foreground]
        )
        
        // Social interaction category
        let socialCategory = UNNotificationCategory(
            identifier: "SOCIAL_INTERACTION",
            actions: [likeAction, commentAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Follow notification category
        let followCategory = UNNotificationCategory(
            identifier: "FOLLOW_NOTIFICATION",
            actions: [followAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Workout reminder category
        let workoutReminderCategory = UNNotificationCategory(
            identifier: "WORKOUT_REMINDER",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            socialCategory,
            followCategory,
            workoutReminderCategory
        ])
    }
    
    // MARK: - Send Notifications
    func sendNotification(
        to userId: String,
        type: NotificationType,
        title: String,
        body: String,
        data: [String: Any] = [:]
    ) async {
        do {
            // Get user's FCM token from Firestore
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(userId).getDocument()
            
            guard let fcmToken = userDoc.data()?["fcmToken"] as? String else {
                print("No FCM token found for user: \(userId)")
                return
            }
            
            // Create notification payload
            let payload: [String: Any] = [
                "to": fcmToken,
                "notification": [
                    "title": title,
                    "body": body,
                    "sound": "default",
                    "badge": 1
                ],
                "data": data.merging([
                    "type": type.rawValue,
                    "timestamp": Int(Date().timeIntervalSince1970)
                ]) { _, new in new },
                "apns": [
                    "payload": [
                        "aps": [
                            "category": type.category,
                            "mutable-content": 1
                        ]
                    ]
                ]
            ]
            
            // Send via FCM
            try await sendFCMNotification(payload: payload)
            
        } catch {
            print("Error sending notification: \(error)")
        }
    }
    
    private func sendFCMNotification(payload: [String: Any]) async throws {
        guard let url = URL(string: "https://fcm.googleapis.com/fcm/send") else {
            throw NotificationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=YOUR_SERVER_KEY", forHTTPHeaderField: "Authorization") // Replace with your server key
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw NotificationError.sendFailed(httpResponse.statusCode)
        }
    }
    
    // MARK: - Social Notification Helpers
    func notifyLike(postId: String, likerUserId: String, postOwnerUserId: String, likerUsername: String) async {
        guard likerUserId != postOwnerUserId else { return } // Don't notify self
        
        await sendNotification(
            to: postOwnerUserId,
            type: .like,
            title: "New Like",
            body: "\(likerUsername) liked your post",
            data: [
                "postId": postId,
                "likerUserId": likerUserId,
                "action": "like"
            ]
        )
    }
    
    func notifyComment(postId: String, commenterUserId: String, postOwnerUserId: String, commenterUsername: String, commentText: String) async {
        guard commenterUserId != postOwnerUserId else { return } // Don't notify self
        
        let truncatedComment = String(commentText.prefix(50)) + (commentText.count > 50 ? "..." : "")
        
        await sendNotification(
            to: postOwnerUserId,
            type: .comment,
            title: "New Comment",
            body: "\(commenterUsername): \(truncatedComment)",
            data: [
                "postId": postId,
                "commenterUserId": commenterUserId,
                "action": "comment"
            ]
        )
    }
    
    func notifyFollow(followerId: String, followingId: String, followerUsername: String) async {
        await sendNotification(
            to: followingId,
            type: .follow,
            title: "New Follower",
            body: "\(followerUsername) started following you",
            data: [
                "followerId": followerId,
                "action": "follow"
            ]
        )
    }
    
    func notifyWorkoutReminder(userId: String, workoutName: String) async {
        await sendNotification(
            to: userId,
            type: .workoutReminder,
            title: "Workout Reminder",
            body: "Time for your \(workoutName) workout!",
            data: [
                "action": "workout_reminder",
                "workoutName": workoutName
            ]
        )
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String,
        categoryIdentifier: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let category = categoryIdentifier {
            content.categoryIdentifier = category
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error)")
            }
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadgeCount() {
        updateBadgeCount(0)
    }
}

// MARK: - Messaging Delegate
extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        DispatchQueue.main.async {
            self.fcmToken = token
        }
        
        // Save to Firestore
        if let currentUserId = Auth.auth().currentUser?.uid {
            Task {
                try await saveFCMToken(token, for: currentUserId)
            }
        }
    }
}

// MARK: - Notification Center Delegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is active
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        handleNotificationAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String,
              let type = NotificationType(rawValue: typeString) else {
            return
        }
        
        DispatchQueue.main.async {
            switch actionIdentifier {
            case "LIKE_ACTION":
                self.handleLikeAction(userInfo: userInfo)
            case "COMMENT_ACTION":
                self.handleCommentAction(userInfo: userInfo)
            case "FOLLOW_BACK_ACTION":
                self.handleFollowBackAction(userInfo: userInfo)
            case "VIEW_ACTION", UNNotificationDefaultActionIdentifier:
                self.handleViewAction(type: type, userInfo: userInfo)
            default:
                break
            }
        }
    }
    
    private func handleLikeAction(userInfo: [AnyHashable: Any]) {
        guard let postId = userInfo["postId"] as? String else { return }
        
        Task {
            try await FirebaseManager.shared.likePost(postId: postId)
        }
    }
    
    private func handleCommentAction(userInfo: [AnyHashable: Any]) {
        // Navigate to comment view
        NotificationCenter.default.post(
            name: .navigateToComments,
            object: userInfo["postId"]
        )
    }
    
    private func handleFollowBackAction(userInfo: [AnyHashable: Any]) {
        guard let followerId = userInfo["followerId"] as? String else { return }
        
        Task {
            try await FirebaseManager.shared.followUser(userId: followerId)
        }
    }
    
    private func handleViewAction(type: NotificationType, userInfo: [AnyHashable: Any]) {
        switch type {
        case .like, .comment:
            if let postId = userInfo["postId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToPost,
                    object: postId
                )
            }
        case .follow:
            if let followerId = userInfo["followerId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToProfile,
                    object: followerId
                )
            }
        case .workoutReminder:
            NotificationCenter.default.post(
                name: .navigateToWorkouts,
                object: nil
            )
        }
    }
}

// MARK: - Supporting Types
enum NotificationType: String, CaseIterable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
    case workoutReminder = "workout_reminder"
    
    var category: String {
        switch self {
        case .like, .comment:
            return "SOCIAL_INTERACTION"
        case .follow:
            return "FOLLOW_NOTIFICATION"
        case .workoutReminder:
            return "WORKOUT_REMINDER"
        }
    }
}

enum NotificationError: Error {
    case invalidURL
    case sendFailed(Int)
    case noToken
    case invalidPayload
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToComments = Notification.Name("navigateToComments")
    static let navigateToPost = Notification.Name("navigateToPost")
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToWorkouts = Notification.Name("navigateToWorkouts")
}