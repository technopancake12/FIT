import SwiftUI

// MARK: - Post Card
struct PostCard: View {
    let feedItem: FeedItem
    let socialService: SocialService
    
    @State private var showComments = false
    @State private var newComment = ""
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isFollowing: Bool
    
    init(feedItem: FeedItem, socialService: SocialService) {
        self.feedItem = feedItem
        self.socialService = socialService
        self._isLiked = State(initialValue: feedItem.isLiked)
        self._likesCount = State(initialValue: feedItem.post.likes)
        self._isFollowing = State(initialValue: feedItem.isFollowing)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post Header
                            SocialPostHeaderView(
                user: feedItem.user,
                post: feedItem.post,
                isFollowing: isFollowing,
                socialService: socialService,
                onFollowToggle: {
                    let newFollowState = socialService.followUser(userId: feedItem.user.id)
                    isFollowing = newFollowState
                }
            )
            
            // Post Content
            PostContentView(post: feedItem.post)
            
            // Post Actions
                            SocialPostActionsView(
                likesCount: likesCount,
                commentsCount: feedItem.post.comments.count,
                isLiked: isLiked,
                onLike: {
                    let newLikedState = socialService.likePost(postId: feedItem.post.id)
                    isLiked = newLikedState
                    likesCount += newLikedState ? 1 : -1
                },
                onComment: {
                    showComments.toggle()
                },
                onShare: {
                    // Handle share
                }
            )
            
            // Comments Section
            if showComments {
                CommentsSection(
                    post: feedItem.post,
                    newComment: $newComment,
                    socialService: socialService,
                    onAddComment: {
                        if !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let _ = socialService.addComment(postId: feedItem.post.id, content: newComment)
                            newComment = ""
                        }
                    }
                )
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Post Header View
struct SocialPostHeaderView: View {
    let user: User
    let post: SocialPost
    let isFollowing: Bool
    let socialService: SocialService
    let onFollowToggle: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(user.displayName.prefix(2).uppercased())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if user.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        // Post type indicator
                        switch post.type {
                        case .workout:
                            Image(systemName: "dumbbell")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        case .achievement:
                            Image(systemName: "trophy")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        case .progress:
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                                .foregroundColor(.green)
                        case .general:
                            EmptyView()
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("@\(user.username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(socialService.timeAgoString(from: post.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if user.id != socialService.getCurrentUser()?.id {
                    Button(action: onFollowToggle) {
                        HStack(spacing: 4) {
                            Image(systemName: isFollowing ? "person.badge.minus" : "person.badge.plus")
                                .font(.caption)
                            Text(isFollowing ? "Unfollow" : "Follow")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isFollowing ? Color(UIColor.systemGray5) : Color.blue)
                        .foregroundColor(isFollowing ? .primary : .white)
                        .cornerRadius(16)
                    }
                }
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Post Content View
struct PostContentView: View {
    let post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text content
            Text(post.content)
                .font(.subheadline)
                .padding(.horizontal)
            
            // Workout data
            if let workoutData = post.workoutData {
                WorkoutDataCard(workoutData: workoutData)
                    .padding(.horizontal)
            }
            
            // Achievement data
            if let achievementData = post.achievementData {
                AchievementDataCard(achievementData: achievementData)
                    .padding(.horizontal)
            }
            
            // Tags
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Workout Data Card
struct WorkoutDataCard: View {
    let workoutData: WorkoutData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workoutData.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    if workoutData.weight > 0 {
                        Text("\(Int(workoutData.weight))kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(workoutData.sets) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(workoutData.reps) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let duration = workoutData.duration {
                Text("\(Int(duration / 60))min")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Achievement Data Card
struct AchievementDataCard: View {
    let achievementData: AchievementData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievementData.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(achievementData.value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Post Actions View
struct SocialPostActionsView: View {
    let likesCount: Int
    let commentsCount: Int
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Like button
            Button(action: onLike) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(isLiked ? .red : .secondary)
                    
                    if likesCount > 0 {
                        Text("\(likesCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Comment button
            Button(action: onComment) {
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if commentsCount > 0 {
                        Text("\(commentsCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Share button
            Button(action: onShare) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Share")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Comments Section
struct CommentsSection: View {
    let post: SocialPost
    @Binding var newComment: String
    let socialService: SocialService
    let onAddComment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            // Add comment
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("Y")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                
                HStack(spacing: 8) {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            onAddComment()
                        }
                    
                    Button(action: onAddComment) {
                        Image(systemName: "paperplane.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal)
            
            // Comments list
            ForEach(post.comments) { comment in
                CommentView(
                    comment: comment,
                    postId: post.id,
                    socialService: socialService
                )
            }
        }
        .padding(.bottom)
        .background(Color(UIColor.systemGray6).opacity(0.3))
    }
}

// MARK: - Comment View
struct CommentView: View {
    let comment: Comment
    let postId: String
    let socialService: SocialService
    
    @State private var isLiked: Bool
    @State private var likesCount: Int
    
    init(comment: Comment, postId: String, socialService: SocialService) {
        self.comment = comment
        self.postId = postId
        self.socialService = socialService
        self._isLiked = State(initialValue: comment.likedBy.contains(socialService.getCurrentUser()?.id ?? ""))
        self._likesCount = State(initialValue: comment.likes)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            let user = socialService.getUser(userId: comment.userId)
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(user?.displayName.prefix(2).uppercased() ?? "U")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                // Comment bubble
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user?.displayName ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text(socialService.commentTimeString(from: comment.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(comment.content)
                        .font(.caption)
                }
                .padding(12)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                
                // Comment actions
                HStack(spacing: 16) {
                    Button {
                        let newLikedState = socialService.likeComment(postId: postId, commentId: comment.id)
                        isLiked = newLikedState
                        likesCount += newLikedState ? 1 : -1
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.caption2)
                                .foregroundColor(isLiked ? .red : .secondary)
                            
                            if likesCount > 0 {
                                Text("\(likesCount)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("Reply") {
                        // Handle reply
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.leading, 12)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Create Post View
struct SocialCreatePostView: View {
    let socialService: SocialService
    @Binding var isPresented: Bool
    
    @State private var content = ""
    @State private var postType: PostType = .general
    @State private var workoutData = WorkoutData(exerciseName: "", weight: 0, reps: 0, sets: 0, duration: nil)
    @State private var showWorkoutDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Post type selector
                    Picker("Post Type", selection: $postType) {
                        Text("General Post").tag(PostType.general)
                        Text("Workout").tag(PostType.workout)
                        Text("Progress Update").tag(PostType.progress)
                        Text("Achievement").tag(PostType.achievement)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Content text area
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's on your mind?")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Workout details (if workout post)
                    if postType == .workout {
                        WorkoutDetailsInput(workoutData: $workoutData)
                    }
                    
                    Spacer()
                    
                    // Create post button
                    Button("Post") {
                        let finalWorkoutData = postType == .workout ? workoutData : nil
                        
                        socialService.createPost(
                            type: postType,
                            content: content,
                            workoutData: finalWorkoutData,
                            tags: []
                        )
                        
                        isPresented = false
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Workout Details Input
struct WorkoutDetailsInput: View {
    @Binding var workoutData: WorkoutData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Exercise name", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onReceive([workoutData.exerciseName].publisher.first()) { newValue in
                        // Handle exercise name change
                    }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Sets", value: .constant(workoutData.sets), formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Reps", value: .constant(workoutData.reps), formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight (kg)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Weight", value: .constant(workoutData.weight), formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}