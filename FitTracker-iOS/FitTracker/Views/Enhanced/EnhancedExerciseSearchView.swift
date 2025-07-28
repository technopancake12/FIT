import SwiftUI

struct EnhancedExerciseSearchView: View {
    @StateObject private var wgerService = WgerAPIService.shared
    @State private var searchText = ""
    @State private var selectedCategory: WgerCategory?
    @State private var selectedMuscles: Set<WgerMuscle> = []
    @State private var selectedEquipment: WgerEquipment?
    @State private var exercises: [WgerExercise] = []
    @State private var isLoading = false
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search header
                    VStack(spacing: 16) {
                        // Search bar
                        HStack {
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
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
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
                        
                        // Active filters
                        if hasActiveFilters {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if let category = selectedCategory {
                                        FilterChip(
                                            title: category.name,
                                            onRemove: { selectedCategory = nil }
                                        )
                                    }
                                    
                                    ForEach(Array(selectedMuscles), id: \.id) { muscle in
                                        FilterChip(
                                            title: muscle.nameEn,
                                            onRemove: { selectedMuscles.remove(muscle) }
                                        )
                                    }
                                    
                                    if let equipment = selectedEquipment {
                                        FilterChip(
                                            title: equipment.name,
                                            onRemove: { selectedEquipment = nil }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Results
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            Text("Searching exercises...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
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
                }
            }
            .navigationTitle("Exercise Database")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showFilters) {
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
        }
        .task {
            await loadInitialData()
        }
        .onChange(of: searchText) { _ in
            if searchText.isEmpty {
                performSearch()
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || !selectedMuscles.isEmpty || selectedEquipment != nil
    }
    
    private func loadInitialData() async {
        do {
            isLoading = true
            exercises = try await wgerService.fetchExercises()
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
                exercises = try await wgerService.fetchExercises(
                    searchTerm: searchText.isEmpty ? nil : searchText,
                    category: selectedCategory?.id,
                    muscles: Array(selectedMuscles.map { $0.id }),
                    equipment: selectedEquipment?.id
                )
                isLoading = false
            } catch {
                print("Error searching exercises: \(error)")
                isLoading = false
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: WgerExercise
    @State private var exerciseImages: [WgerExerciseImage] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(exercise.category.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if let firstImage = exerciseImages.first {
                    AsyncImage(url: URL(string: firstImage.image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Muscles
            if !exercise.muscles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Primary Muscles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(exercise.muscles, id: \.id) { muscle in
                                Text(muscle.nameEn)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.green.opacity(0.3))
                                    )
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
            
            // Equipment
            if !exercise.equipment.isEmpty {
                HStack {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text(exercise.equipment.map { $0.name }.joined(separator: ", "))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Description preview
            if !exercise.description.isEmpty {
                Text(exercise.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .task {
            await loadExerciseImages()
        }
    }
    
    private func loadExerciseImages() async {
        do {
            exerciseImages = try await WgerAPIService.shared.fetchExerciseImages(for: exercise.exerciseBase)
        } catch {
            print("Error loading exercise images: \(error)")
        }
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