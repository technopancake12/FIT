import SwiftUI

struct EnhancedExerciseSearchView: View {
    @StateObject private var openWorkoutService = OpenWorkoutService.shared
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedMuscles: Set<String> = []
    @State private var selectedEquipment: Equipment?
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            mainContent
        }
        .task {
            await loadInitialData()
        }
        .onChange(of: searchText) {
            if searchText.isEmpty {
                performSearch()
            }
        }
    }
    
    private var mainContent: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                searchHeader
                contentArea
            }
        }
        .navigationTitle("Exercise Database")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showFilters) {
            filtersSheet
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.1),
                Color(red: 0.1, green: 0.1, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var searchHeader: some View {
        VStack(spacing: 16) {
            searchBar
            if hasActiveFilters {
                activeFilters
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var searchBar: some View {
        HStack {
            searchField
            filterButton
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Search exercises...", text: $searchText)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .onSubmit {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(searchFieldBackground)
    }
    
    private var searchFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var filterButton: some View {
        Button(action: { showFilters.toggle() }) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(showFilters ? 1.0 : 0.3))
                )
        }
    }
    
    private var activeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = selectedCategory {
                    FilterChip(
                        title: category.safeName,
                        onRemove: { selectedCategory = nil }
                    )
                }
                
                ForEach(Array(selectedMuscles), id: \.id) { muscle in
                    FilterChip(
                        title: muscle.safeName,
                        onRemove: { selectedMuscles.remove(muscle) }
                    )
                }
                
                if let equipment = selectedEquipment {
                    FilterChip(
                        title: equipment.safeName,
                        onRemove: { selectedEquipment = nil }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var contentArea: some View {
        Group {
            if isLoading {
                loadingView
            } else {
                exercisesList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Searching exercises...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(exercises, id: \.id) { exercise in
                    ExerciseCard(exercise: exercise)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private var filtersSheet: some View {
        ExerciseFiltersView(
            selectedCategory: $selectedCategory,
            selectedMuscles: $selectedMuscles,
            selectedEquipment: $selectedEquipment,
            onApply: {
                showFilters = false
                performSearch()
            }
        )
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || !selectedMuscles.isEmpty || selectedEquipment != nil
    }
    
    private func loadInitialData() async {
        do {
            isLoading = true
            try await openWorkoutService.fetchExercises()
            exercises = openWorkoutService.exercises
            isLoading = false
        } catch {
            print("Error loading exercises: \(error)")
            isLoading = false
        }
    }
    
    private func performSearch() {
        Task {
            do {
                isLoading = true
                exercises = try await openWorkoutService.searchExercises(query: searchText)
                isLoading = false
            } catch {
                print("Error searching exercises: \(error)")
                isLoading = false
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    @State private var exerciseImages: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            musclesSection
            equipmentSection
        }
        .padding(16)
        .background(cardBackground)
        .task {
            await loadExerciseImages()
        }
    }
    
    private var headerSection: some View {
        HStack {
            exerciseInfo
            Spacer()
            exerciseImage
        }
    }
    
    private var exerciseInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(exercise.category)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    private var exerciseImage: some View {
        if let firstImage = exerciseImages.first {
            AsyncImage(url: URL(string: firstImage)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                imagePlaceholder
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.1))
            .overlay(
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.6))
            )
    }
    
    @ViewBuilder
    private var musclesSection: some View {
        if !exercise.primaryMuscles.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Primary Muscles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                musclesList
            }
        }
    }
    
    private var musclesList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                    muscleTag(muscle)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    private func muscleTag(_ muscle: String) -> some View {
        Text(muscle)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.3))
            )
    }
    
    @ViewBuilder
    private var equipmentSection: some View {
        if exercise.equipment != "None" && !exercise.equipment.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Equipment")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                equipmentList
            }
        }
    }
    
    private var equipmentList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                equipmentTag(exercise.equipment)
            }
            .padding(.horizontal, 1)
        }
    }
    
    private func equipmentTag(_ equipment: String) -> some View {
        Text(equipment)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.3))
            )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private func loadExerciseImages() async {
        // OpenWorkout API doesn't provide exercise images yet
        // This will be implemented when the API supports it
        exerciseImages = []
    }
}

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.8))
        )
    }
}

#Preview {
    EnhancedExerciseSearchView()
}