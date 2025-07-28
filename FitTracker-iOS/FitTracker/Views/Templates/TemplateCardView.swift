import SwiftUI

struct TemplateCardView: View {
    let template: WorkoutTemplate
    let showOwner: Bool
    let onTap: () -> Void
    let onUse: () -> Void
    let onShare: (() -> Void)?
    let onFavorite: (() -> Void)?
    
    @EnvironmentObject private var templateService: WorkoutTemplateService
    @State private var showingShareSheet = false
    
    var isFavorited: Bool {
        templateService.favoriteTemplates.contains { $0.id == template.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    if showOwner {
                        Text("by @username") // Would need to fetch username
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Favorite button
                if let onFavorite = onFavorite {
                    Button(action: onFavorite) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .foregroundColor(isFavorited ? .red : .secondary)
                            .font(.title3)
                    }
                }
            }
            
            // Description
            if let description = template.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Stats Row
            HStack(spacing: 16) {
                StatItem(
                    icon: "dumbbell",
                    value: "\(template.totalExercises)",
                    label: "exercises"
                )
                
                StatItem(
                    icon: "clock",
                    value: template.estimatedDuration?.formattedDuration ?? "N/A",
                    label: "duration"
                )
                
                StatItem(
                    icon: "star.fill",
                    value: String(format: "%.1f", template.averageRating),
                    label: "rating"
                )
                
                Spacer()
            }
            
            // Tags and Category
            HStack {
                CategoryBadge(category: template.category)
                
                DifficultyBadge(difficulty: template.difficulty)
                
                Spacer()
                
                Text("\(template.usageCount) uses")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tags
            if !template.tags.isEmpty {
                TagsView(tags: Array(template.tags.prefix(3)))
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Use Template") {
                    onUse()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("Details") {
                    onTap()
                }
                .buttonStyle(.bordered)
                
                if let onShare = onShare {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CategoryBadge: View {
    let category: WorkoutCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .clipShape(Capsule())
    }
}

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficultyColor.opacity(0.1))
            .foregroundColor(difficultyColor)
            .clipShape(Capsule())
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .yellow
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(UIColor.systemGray6))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Extensions
extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}