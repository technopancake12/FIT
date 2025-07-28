import Foundation

class ExerciseDatabase: ObservableObject {
    static let shared = ExerciseDatabase()
    
    @Published private var exercises: [Exercise] = []
    
    private init() {
        loadExercises()
    }
    
    private func loadExercises() {
        exercises = [
            // Chest Exercises
            Exercise(
                id: "push-up",
                name: "Push-up",
                category: "Chest",
                primaryMuscles: ["Chest"],
                secondaryMuscles: ["Triceps", "Shoulders"],
                equipment: "Bodyweight",
                difficulty: .beginner,
                instructions: [
                    "Start in a plank position with hands shoulder-width apart",
                    "Lower your body until chest nearly touches the floor",
                    "Push back up to starting position",
                    "Keep core tight throughout the movement"
                ],
                tips: [
                    "Keep your body in a straight line",
                    "Don't let your hips sag or pike up",
                    "Control the descent for better muscle activation"
                ],
                alternatives: ["incline-push-up", "knee-push-up", "bench-press"]
            ),
            
            Exercise(
                id: "bench-press",
                name: "Bench Press",
                category: "Chest",
                primaryMuscles: ["Chest"],
                secondaryMuscles: ["Triceps", "Shoulders"],
                equipment: "Barbell",
                difficulty: .intermediate,
                instructions: [
                    "Lie on bench with eyes under the bar",
                    "Grip bar slightly wider than shoulder width",
                    "Lower bar to chest with control",
                    "Press bar back up to starting position"
                ],
                tips: [
                    "Keep feet flat on the floor",
                    "Maintain natural arch in lower back",
                    "Touch the bar to your chest lightly"
                ],
                alternatives: ["dumbbell-bench-press", "push-up", "incline-bench-press"]
            ),
            
            // Back Exercises
            Exercise(
                id: "pull-up",
                name: "Pull-up",
                category: "Back",
                primaryMuscles: ["Back"],
                secondaryMuscles: ["Biceps", "Shoulders"],
                equipment: "Pull-up Bar",
                difficulty: .intermediate,
                instructions: [
                    "Hang from bar with palms facing away",
                    "Pull yourself up until chin clears the bar",
                    "Lower yourself with control",
                    "Repeat for desired reps"
                ],
                tips: [
                    "Start from a dead hang",
                    "Engage your core",
                    "Don't swing or use momentum"
                ],
                alternatives: ["lat-pulldown", "assisted-pull-up", "bent-over-row"]
            ),
            
            Exercise(
                id: "bent-over-row",
                name: "Bent-over Row",
                category: "Back",
                primaryMuscles: ["Back"],
                secondaryMuscles: ["Biceps", "Shoulders"],
                equipment: "Barbell",
                difficulty: .intermediate,
                instructions: [
                    "Stand with feet hip-width apart holding barbell",
                    "Hinge at hips, keeping back straight",
                    "Pull bar to lower chest/upper abdomen",
                    "Lower bar with control"
                ],
                tips: [
                    "Keep core engaged",
                    "Don't round your back",
                    "Squeeze shoulder blades together at the top"
                ],
                alternatives: ["dumbbell-row", "seated-cable-row", "t-bar-row"]
            ),
            
            // Shoulder Exercises
            Exercise(
                id: "overhead-press",
                name: "Overhead Press",
                category: "Shoulders",
                primaryMuscles: ["Shoulders"],
                secondaryMuscles: ["Triceps", "Abs"],
                equipment: "Barbell",
                difficulty: .intermediate,
                instructions: [
                    "Stand with feet shoulder-width apart",
                    "Hold barbell at shoulder height",
                    "Press bar overhead until arms are fully extended",
                    "Lower bar back to shoulder height"
                ],
                tips: [
                    "Keep core tight",
                    "Don't arch your back excessively",
                    "Press the bar in a straight line"
                ],
                alternatives: ["dumbbell-shoulder-press", "seated-shoulder-press", "pike-push-up"]
            ),
            
            // Leg Exercises
            Exercise(
                id: "squat",
                name: "Squat",
                category: "Legs",
                primaryMuscles: ["Quadriceps", "Glutes"],
                secondaryMuscles: ["Hamstrings", "Abs"],
                equipment: "Bodyweight",
                difficulty: .beginner,
                instructions: [
                    "Stand with feet shoulder-width apart",
                    "Lower yourself as if sitting in a chair",
                    "Keep knees in line with toes",
                    "Push through heels to return to standing"
                ],
                tips: [
                    "Keep chest up and core engaged",
                    "Don't let knees cave inward",
                    "Go as low as mobility allows"
                ],
                alternatives: ["goblet-squat", "front-squat", "leg-press"]
            ),
            
            Exercise(
                id: "deadlift",
                name: "Deadlift",
                category: "Legs",
                primaryMuscles: ["Hamstrings", "Glutes", "Back"],
                secondaryMuscles: ["Quadriceps", "Abs"],
                equipment: "Barbell",
                difficulty: .intermediate,
                instructions: [
                    "Stand with feet hip-width apart, bar over mid-foot",
                    "Hinge at hips and knees to grip the bar",
                    "Keep back straight, chest up",
                    "Drive through heels to lift the bar up your legs"
                ],
                tips: [
                    "Keep the bar close to your body",
                    "Don't round your back",
                    "Fully extend hips and knees at the top"
                ],
                alternatives: ["romanian-deadlift", "sumo-deadlift", "trap-bar-deadlift"]
            ),
            
            Exercise(
                id: "lunge",
                name: "Lunge",
                category: "Legs",
                primaryMuscles: ["Quadriceps", "Glutes"],
                secondaryMuscles: ["Hamstrings", "Abs"],
                equipment: "Bodyweight",
                difficulty: .beginner,
                instructions: [
                    "Step forward with one leg",
                    "Lower until both knees are at 90 degrees",
                    "Push back to starting position",
                    "Repeat with other leg"
                ],
                tips: [
                    "Keep most weight on front leg",
                    "Don't let front knee go past toe",
                    "Keep torso upright"
                ],
                alternatives: ["reverse-lunge", "walking-lunge", "bulgarian-split-squat"]
            ),
            
            // Arms Exercises
            Exercise(
                id: "bicep-curl",
                name: "Bicep Curl",
                category: "Arms",
                primaryMuscles: ["Biceps"],
                secondaryMuscles: ["Forearms"],
                equipment: "Dumbbell",
                difficulty: .beginner,
                instructions: [
                    "Stand with dumbbells at your sides",
                    "Keep elbows at your sides",
                    "Curl weights up to shoulder level",
                    "Lower with control"
                ],
                tips: [
                    "Don't swing the weights",
                    "Keep elbows stationary",
                    "Control the negative portion"
                ],
                alternatives: ["hammer-curl", "cable-curl", "barbell-curl"]
            ),
            
            Exercise(
                id: "tricep-dip",
                name: "Tricep Dip",
                category: "Arms",
                primaryMuscles: ["Triceps"],
                secondaryMuscles: ["Shoulders", "Chest"],
                equipment: "Bench",
                difficulty: .intermediate,
                instructions: [
                    "Sit on edge of bench, hands beside hips",
                    "Slide off bench, supporting weight with arms",
                    "Lower yourself until elbows are at 90 degrees",
                    "Push back up to starting position"
                ],
                tips: [
                    "Keep elbows close to body",
                    "Don't go too low if it hurts shoulders",
                    "Keep legs straight for more difficulty"
                ],
                alternatives: ["close-grip-push-up", "overhead-tricep-extension"]
            )
        ]
    }
    
    func findExercise(by id: String) -> Exercise? {
        return exercises.first { $0.id == id }
    }
    
    func getExercisesByMuscleGroup(_ muscleGroup: String) -> [Exercise] {
        return exercises.filter { exercise in
            exercise.primaryMuscles.contains(muscleGroup) ||
            exercise.secondaryMuscles.contains(muscleGroup)
        }
    }
    
    func getExercisesByEquipment(_ equipment: String) -> [Exercise] {
        return exercises.filter { $0.equipment == equipment }
    }
    
    func getAlternativeExercises(for exerciseId: String) -> [Exercise] {
        guard let exercise = findExercise(by: exerciseId) else { return [] }
        
        return exercise.alternatives.compactMap { altId in
            findExercise(by: altId)
        }
    }
    
    func searchExercises(query: String = "", category: String? = nil, equipment: String? = nil) -> [Exercise] {
        let lowerQuery = query.lowercased()
        
        return exercises.filter { exercise in
            let matchesQuery = query.isEmpty ||
                exercise.name.lowercased().contains(lowerQuery) ||
                exercise.primaryMuscles.contains { $0.lowercased().contains(lowerQuery) } ||
                exercise.equipment.lowercased().contains(lowerQuery)
            
            let matchesCategory = category == nil ||
                exercise.category == category ||
                exercise.primaryMuscles.contains(category!)
            
            let matchesEquipment = equipment == nil ||
                exercise.equipment == equipment
            
            return matchesQuery && matchesCategory && matchesEquipment
        }
    }
    
    func getAllExercises() -> [Exercise] {
        return exercises
    }
    
    func getCategories() -> [String] {
        return Array(Set(exercises.map { $0.category })).sorted()
    }
    
    func getEquipmentTypes() -> [String] {
        return Array(Set(exercises.map { $0.equipment })).sorted()
    }
    
    func getMuscleGroups() -> [String] {
        var muscles = Set<String>()
        exercises.forEach { exercise in
            exercise.primaryMuscles.forEach { muscles.insert($0) }
            exercise.secondaryMuscles.forEach { muscles.insert($0) }
        }
        return Array(muscles).sorted()
    }
}