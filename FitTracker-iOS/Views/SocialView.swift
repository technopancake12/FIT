import SwiftUI

struct SocialView: View {
    @StateObject private var socialService = SocialService()
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Create Post Prompt
                    CreatePostPromptCard {
                        showCreatePost = true
                    }
                    
                    // Feed
                    if socialService.feed.isEmpty {
                        EmptyFeedView {
                            showCreatePost = true
                        }
                    } else {
                        ForEach(socialService.feed) { feedItem in
                            PostCard(
                                feedItem: feedItem,
                                socialService: socialService
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(socialService: socialService, isPresented: $showCreatePost)
            }
        }
        .onAppear {
            socialService.updateFeed()
        }
    }
}

// MARK: - Create Post Prompt Card
struct CreatePostPromptCard: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Avatar placeholder
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("Y")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                
                Button(action: onTap) {
                    HStack {
                        Text("Share your workout progress...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(25)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onTap) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Empty Feed View
struct EmptyFeedView: View {
    let onCreatePost: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No posts yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Follow other users or create your first post to see content here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create First Post") {
                onCreatePost()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    SocialView()
}