import SwiftUI

struct WorkoutTemplatesView: View {
    @EnvironmentObject private var templateService: WorkoutTemplateService
    @State private var selectedTab: TemplateTab = .myTemplates
    @State private var showingCreateTemplate = false
    @State private var showingSearchFilters = false
    @State private var searchText = ""
    @State private var searchFilters = TemplateSearchFilters.empty()
    @State private var searchResults: [WorkoutTemplate] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                TemplateTabSelector(selectedTab: $selectedTab)
                
                // Search Bar (for Browse tab)
                if selectedTab == .browse {
                    SearchBar(
                        text: $searchText,
                        placeholder: "Search templates...",
                        onSearchChanged: performSearch,
                        onFiltersPressed: { showingSearchFilters = true }
                    )
                    .padding(.horizontal)
                }
                
                // Content
                TabView(selection: $selectedTab) {
                    MyTemplatesView()
                        .tag(TemplateTab.myTemplates)
                    
                    BrowseTemplatesView(
                        searchText: searchText,
                        searchResults: searchResults,
                        isSearching: isSearching
                    )
                    .tag(TemplateTab.browse)
                    
                    FavoriteTemplatesView()
                        .tag(TemplateTab.favorites)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == .myTemplates {
                        Button(action: { showingCreateTemplate = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView()
            }
            .sheet(isPresented: $showingSearchFilters) {
                TemplateSearchFiltersView(filters: $searchFilters) {
                    performSearch()
                }
            }
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    private func loadInitialData() {
        Task {
            do {
                try await templateService.getUserTemplates()
                try await templateService.getPublicTemplates()
                try await templateService.getFavoriteTemplates()
            } catch {
                print("Error loading templates: \(error)")
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = templateService.publicTemplates
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await templateService.searchTemplates(query: searchText, filters: searchFilters)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                }
                print("Search error: \(error)")
            }
        }
    }
}

// MARK: - Tab Selector
struct TemplateTabSelector: View {
    @Binding var selectedTab: TemplateTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TemplateTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

enum TemplateTab: CaseIterable {
    case myTemplates, browse, favorites
    
    var title: String {
        switch self {
        case .myTemplates: return "My Templates"
        case .browse: return "Browse"
        case .favorites: return "Favorites"
        }
    }
    
    var icon: String {
        switch self {
        case .myTemplates: return "doc.text"
        case .browse: return "magnifyingglass"
        case .favorites: return "heart"
        }
    }
}

// MARK: - My Templates View
struct MyTemplatesView: View {
    @EnvironmentObject private var templateService: WorkoutTemplateService
    @State private var showingTemplateDetail: WorkoutTemplate?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if templateService.userTemplates.isEmpty {
                    EmptyTemplatesView(
                        icon: "doc.text",
                        title: "No Templates Yet",
                        message: "Create your first workout template to get started!",
                        actionTitle: "Create Template"
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(templateService.userTemplates) { template in
                        TemplateCardView(
                            template: template,
                            showOwner: false,
                            onTap: { showingTemplateDetail = template },
                            onUse: { useTemplate(template) },
                            onShare: { shareTemplate(template) }
                        )
                    }
                }
            }
            .padding()
        }
        .refreshable {
            do {
                try await templateService.getUserTemplates()
            } catch {
                print("Error refreshing templates: \(error)")
            }
        }
        .sheet(item: $showingTemplateDetail) { template in
            TemplateDetailView(template: template)
        }
    }
    
    private func useTemplate(_ template: WorkoutTemplate) {
        Task {
            do {
                let workout = try await templateService.useTemplate(template)
                // Navigate to workout view
                NotificationCenter.default.post(
                    name: .startWorkoutFromTemplate,
                    object: workout
                )
            } catch {
                print("Error using template: \(error)")
            }
        }
    }
    
    private func shareTemplate(_ template: WorkoutTemplate) {
        Task {
            do {
                let shareCode = try await templateService.shareTemplateViaCode(template.id)
                // Show share sheet
                NotificationCenter.default.post(
                    name: .shareTemplate,
                    object: shareCode
                )
            } catch {
                print("Error sharing template: \(error)")
            }
        }
    }
}

// MARK: - Browse Templates View
struct BrowseTemplatesView: View {
    let searchText: String
    let searchResults: [WorkoutTemplate]
    let isSearching: Bool
    
    @EnvironmentObject private var templateService: WorkoutTemplateService
    @State private var showingTemplateDetail: WorkoutTemplate?
    
    var displayTemplates: [WorkoutTemplate] {
        if searchText.isEmpty {
            return templateService.publicTemplates
        } else {
            return searchResults
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if displayTemplates.isEmpty {
                    EmptyTemplatesView(
                        icon: "magnifyingglass",
                        title: searchText.isEmpty ? "No Public Templates" : "No Results",
                        message: searchText.isEmpty ? 
                            "Be the first to share a workout template!" :
                            "Try adjusting your search or filters",
                        actionTitle: searchText.isEmpty ? nil : "Clear Search"
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(displayTemplates) { template in
                        TemplateCardView(
                            template: template,
                            showOwner: true,
                            onTap: { showingTemplateDetail = template },
                            onUse: { useTemplate(template) },
                            onFavorite: { toggleFavorite(template) }
                        )
                    }
                }
            }
            .padding()
        }
        .refreshable {
            do {
                try await templateService.getPublicTemplates()
            } catch {
                print("Error refreshing public templates: \(error)")
            }
        }
        .sheet(item: $showingTemplateDetail) { template in
            TemplateDetailView(template: template)
        }
    }
    
    private func useTemplate(_ template: WorkoutTemplate) {
        Task {
            do {
                let workout = try await templateService.useTemplate(template)
                NotificationCenter.default.post(
                    name: .startWorkoutFromTemplate,
                    object: workout
                )
            } catch {
                print("Error using template: \(error)")
            }
        }
    }
    
    private func toggleFavorite(_ template: WorkoutTemplate) {
        Task {
            do {
                if templateService.favoriteTemplates.contains(where: { $0.id == template.id }) {
                    try await templateService.removeFromFavorites(template.id)
                } else {
                    try await templateService.addToFavorites(template.id)
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
}

// MARK: - Favorite Templates View
struct FavoriteTemplatesView: View {
    @EnvironmentObject private var templateService: WorkoutTemplateService
    @State private var showingTemplateDetail: WorkoutTemplate?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if templateService.favoriteTemplates.isEmpty {
                    EmptyTemplatesView(
                        icon: "heart",
                        title: "No Favorites Yet",
                        message: "Save templates you like to access them quickly!",
                        actionTitle: nil
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(templateService.favoriteTemplates) { template in
                        TemplateCardView(
                            template: template,
                            showOwner: true,
                            onTap: { showingTemplateDetail = template },
                            onUse: { useTemplate(template) },
                            onFavorite: { removeFromFavorites(template) }
                        )
                    }
                }
            }
            .padding()
        }
        .refreshable {
            do {
                try await templateService.getFavoriteTemplates()
            } catch {
                print("Error refreshing favorites: \(error)")
            }
        }
        .sheet(item: $showingTemplateDetail) { template in
            TemplateDetailView(template: template)
        }
    }
    
    private func useTemplate(_ template: WorkoutTemplate) {
        Task {
            do {
                let workout = try await templateService.useTemplate(template)
                NotificationCenter.default.post(
                    name: .startWorkoutFromTemplate,
                    object: workout
                )
            } catch {
                print("Error using template: \(error)")
            }
        }
    }
    
    private func removeFromFavorites(_ template: WorkoutTemplate) {
        Task {
            do {
                try await templateService.removeFromFavorites(template.id)
            } catch {
                print("Error removing from favorites: \(error)")
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyTemplatesView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle {
                Button(actionTitle) {
                    // Handle action
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearchChanged: () -> Void
    let onFiltersPressed: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: text) { _ in
                        onSearchChanged()
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onSearchChanged()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            
            Button(action: onFiltersPressed) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startWorkoutFromTemplate = Notification.Name("startWorkoutFromTemplate")
    static let shareTemplate = Notification.Name("shareTemplate")
}