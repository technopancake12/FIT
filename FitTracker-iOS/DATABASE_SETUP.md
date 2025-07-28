# FitTracker Database Setup

This guide explains how to set up a local database for FitTracker using data from **wger** (exercises) and **Open Food Facts** (US foods only).

## 🎯 Overview

The database setup process:
1. **Fetches exercise data** from wger API (all English exercises)
2. **Downloads and filters** Open Food Facts data for US products only
3. **Builds SQLite database** for fast local queries
4. **Generates Swift models** and services for iOS integration

## 📋 Prerequisites

Install required tools:

```bash
# macOS
brew install jq curl wget sqlite3 duckdb

# Ubuntu/Debian
sudo apt-get install jq curl wget sqlite3
# Note: DuckDB installation varies by platform
```

## 🚀 Quick Start

Run the master script to fetch all data and build the database:

```bash
./scripts/build_database.sh
```

This will:
- ✅ Fetch ~1000+ exercises from wger
- ✅ Download and filter ~50,000+ US food products
- ✅ Create SQLite database (`data/fittracker.db`)
- ✅ Generate Swift models and services
- ⏱️ Total time: 15-45 minutes (mostly downloading Open Food Facts)

## 📁 Generated Files

After running the script, you'll have:

```
FitTracker-iOS/
├── data/
│   ├── wger_exercises.json          # Raw exercise data
│   ├── us_products_final.json       # Filtered US food data
│   ├── fittracker.db               # SQLite database
│   └── fittracker.duckdb           # DuckDB database (optional)
├── FitTracker/
│   ├── Models/
│   │   └── DatabaseModels.swift    # Swift models for database
│   └── Services/
│       └── LocalDatabaseService.swift # Database service
└── scripts/
    ├── fetch_wger_exercises.sh     # wger data fetcher
    ├── fetch_openfoodfacts_us.sh   # Open Food Facts fetcher
    └── build_database.sh           # Master script
```

## 🔧 Individual Scripts

### 1. Fetch wger Exercises

```bash
./scripts/fetch_wger_exercises.sh
```

**What it does:**
- Fetches all English exercises from wger API
- Handles pagination automatically
- Saves to `wger_exercises.json`
- ⏱️ Time: ~2-5 minutes

**Sample output:**
```json
[
  {
    "id": 345,
    "name": "Barbell Curl",
    "description": "Stand with your feet shoulder-width apart...",
    "category": {"id": 10, "name": "Abs"},
    "muscles": [{"id": 6, "name": "Biceps brachii"}],
    "equipment": [{"id": 1, "name": "Barbell"}]
  }
]
```

### 2. Fetch Open Food Facts US Data

```bash
./scripts/fetch_openfoodfacts_us.sh
```

**What it does:**
- Downloads full Open Food Facts dump (~2GB compressed)
- Filters for US-origin products only
- Extracts relevant nutrition fields
- Saves to `us_products_final.json`
- ⏱️ Time: 10-30 minutes (download + processing)

**Sample output:**
```json
[
  {
    "code": "049000006596",
    "product_name": "Coca-Cola Classic",
    "brands": "Coca-Cola",
    "nutriments": {
      "energy_kcal_100g": 42,
      "fat_100g": 0,
      "carbohydrates_100g": 10.6,
      "proteins_100g": 0
    }
  }
]
```

## 🗄️ Database Schema

### Exercises Table
```sql
CREATE TABLE exercises (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category_id INTEGER,
    category_name TEXT,
    equipment TEXT,
    muscles TEXT,
    muscles_secondary TEXT,
    language INTEGER,
    license INTEGER,
    license_author TEXT,
    created_at TEXT
);
```

### Foods Table
```sql
CREATE TABLE foods (
    code TEXT PRIMARY KEY,
    product_name TEXT,
    generic_name TEXT,
    brands TEXT,
    categories TEXT,
    image_front_url TEXT,
    energy_kcal_100g REAL,
    fat_100g REAL,
    carbohydrates_100g REAL,
    proteins_100g REAL,
    -- ... additional nutrition fields
);
```

## 📱 Swift Integration

### Using LocalDatabaseService

```swift
import SwiftUI

struct ExerciseSearchView: View {
    @StateObject private var dbService = LocalDatabaseService.shared
    @State private var searchText = ""
    @State private var exercises: [DatabaseExercise] = []
    
    var body: some View {
        List(exercises) { exercise in
            VStack(alignment: .leading) {
                Text(exercise.name)
                Text(exercise.categoryName ?? "General")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { newValue in
            Task {
                exercises = try await dbService.searchExercises(query: newValue)
            }
        }
    }
}
```

### Converting to Local Models

```swift
// Convert database model to local model
let localExercise = databaseExercise.toLocalExercise()
let localFood = databaseFood.toLocalFood()
```

## 🔍 Sample Queries

### SQLite Queries

```bash
# Connect to database
sqlite3 data/fittracker.db

# Count records
SELECT 'Exercises' as table_name, COUNT(*) as count FROM exercises
UNION ALL
SELECT 'Foods' as table_name, COUNT(*) as count FROM foods;

# Search exercises
SELECT name, category_name FROM exercises 
WHERE name LIKE '%curl%' 
ORDER BY name LIMIT 10;

# Search foods
SELECT product_name, brands, energy_kcal_100g 
FROM foods 
WHERE product_name LIKE '%apple%' 
ORDER BY product_name LIMIT 10;

# Get exercise categories
SELECT DISTINCT category_name FROM exercises 
WHERE category_name IS NOT NULL 
ORDER BY category_name;
```

### Swift Queries

```swift
// Search exercises
let exercises = try await dbService.searchExercises(query: "curl")

// Get exercises by category
let absExercises = try await dbService.getExercisesByCategory("Abs")

// Search foods
let foods = try await dbService.searchFoods(query: "apple")

// Get food by barcode
let food = try await dbService.getFoodByBarcode("049000006596")
```

## 🛠️ Customization

### Modify API Key

Edit `scripts/fetch_wger_exercises.sh`:
```bash
API_KEY="your_wger_api_key_here"
```

Get a free API key from: https://wger.de/en/software/api

### Filter Different Food Categories

Edit `scripts/fetch_openfoodfacts_us.sh`:
```bash
# Filter for specific categories
grep '"categories_tags":[^]]*"beverages"' openfoodfacts-products.jsonl | \
    grep '"countries_tags":[^]]*"us"' | \
    jq -c '{...}'
```

### Add More Nutrition Fields

Edit the jq filter in `fetch_openfoodfacts_us.sh`:
```bash
jq -c '{
    code,
    product_name,
    nutriments: {
        energy_kcal_100g: .nutriments."energy-kcal_100g",
        # Add more fields here
        vitamin_c_100g: .nutriments."vitamin-c_100g",
        calcium_100g: .nutriments."calcium_100g"
    }
}'
```

## 🔄 Updating Data

### Re-fetch All Data
```bash
rm data/wger_exercises.json data/us_products_final.json
./scripts/build_database.sh
```

### Update Only Exercises
```bash
rm data/wger_exercises.json
./scripts/fetch_wger_exercises.sh
# Re-run database build
```

### Update Only Foods
```bash
rm data/us_products_final.json
./scripts/fetch_openfoodfacts_us.sh
# Re-run database build
```

## 🚨 Troubleshooting

### Common Issues

**"jq command not found"**
```bash
brew install jq  # macOS
sudo apt-get install jq  # Ubuntu
```

**"wget command not found"**
```bash
brew install wget  # macOS
sudo apt-get install wget  # Ubuntu
```

**"Permission denied"**
```bash
chmod +x scripts/*.sh
```

**"Database not found"**
- Ensure `fittracker.db` is copied to your Xcode project bundle
- Check file path in `LocalDatabaseService.swift`

**"Open Food Facts download too slow"**
- The file is ~2GB compressed, ~8GB uncompressed
- Consider using a faster internet connection
- Download can be resumed if interrupted

### Performance Tips

1. **Use indexes** (already created in schema)
2. **Limit query results** (default: 50 items)
3. **Use async/await** for database queries
4. **Cache frequently used data** in memory

## 📊 Data Statistics

Typical database size:
- **Exercises**: ~1,000-2,000 records
- **Foods**: ~50,000-100,000 US products
- **SQLite file**: ~50-100 MB
- **Query speed**: <100ms for most searches

## 🔗 Resources

- [wger API Documentation](https://wger.readthedocs.io/)
- [Open Food Facts Data](https://wiki.openfoodfacts.org/Reusing_Open_Food_Facts_Data)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Swift SQLite3](https://developer.apple.com/documentation/sqlite3)

## 🤝 Contributing

To improve the database setup:

1. **Add more data sources** (USDA, etc.)
2. **Optimize queries** for better performance
3. **Add data validation** and error handling
4. **Create data update automation**

---

**Note**: This setup creates a local database for offline use. For real-time data, continue using the existing API services (`WgerAPIService` and `OpenFoodFactsService`). 