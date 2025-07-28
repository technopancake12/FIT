# FitTracker Local Database - Quick Start

## 🚀 One-Command Setup

```bash
# Install dependencies (macOS)
brew install jq curl wget sqlite3 duckdb

# Run the complete setup
./scripts/build_database.sh
```

This will fetch ~1000+ exercises and ~50,000+ US foods, creating a local SQLite database.

## 📱 Swift Integration

### 1. Add Database to Xcode Project

1. Copy `data/fittracker.db` to your Xcode project
2. Add it to your app bundle in Xcode

### 2. Use LocalDatabaseService

```swift
import SwiftUI

struct ExerciseSearchView: View {
    @StateObject private var dbService = LocalDatabaseService.shared
    @State private var exercises: [DatabaseExercise] = []
    
    var body: some View {
        List(exercises) { exercise in
            Text(exercise.name)
        }
        .onAppear {
            Task {
                exercises = try await dbService.searchExercises(query: "curl")
            }
        }
    }
}
```

### 3. Convert to Local Models

```swift
// Database model → Local model
let localExercise = databaseExercise.toLocalExercise()
let localFood = databaseFood.toLocalFood()
```

## 🔍 Sample Queries

```swift
// Search exercises
let exercises = try await dbService.searchExercises(query: "squat")

// Search foods  
let foods = try await dbService.searchFoods(query: "apple")

// Get by barcode
let food = try await dbService.getFoodByBarcode("049000006596")

// Get categories
let categories = try await dbService.getExerciseCategories()
```

## 🧪 Test Your Setup

```bash
# Test database queries
./scripts/test_database.sh

# Try the demo view
# Add LocalDatabaseDemoView() to your app
```

## 📁 Generated Files

- `data/fittracker.db` - SQLite database
- `FitTracker/Models/DatabaseModels.swift` - Swift models
- `FitTracker/Services/LocalDatabaseService.swift` - Database service
- `FitTracker/Views/LocalDatabaseDemoView.swift` - Demo UI

## ⚡ Performance

- **Query speed**: <100ms for most searches
- **Database size**: ~50-100 MB
- **Offline**: Works without internet
- **Fast**: No API calls needed

## 🔄 Update Data

```bash
# Re-fetch all data
rm data/wger_exercises.json data/us_products_final.json
./scripts/build_database.sh

# Update only exercises
rm data/wger_exercises.json
./scripts/fetch_wger_exercises.sh
```

## 🆚 vs API Services

| Feature | Local Database | API Services |
|---------|---------------|--------------|
| Speed | ⚡ Very Fast | 🐌 Slower |
| Offline | ✅ Yes | ❌ No |
| Data Freshness | 📅 Periodic | 🔄 Real-time |
| Network Usage | ❌ None | 📡 Required |
| Setup | 🔧 One-time | ✅ Ready |

---

**Need help?** See `DATABASE_SETUP.md` for detailed documentation. 