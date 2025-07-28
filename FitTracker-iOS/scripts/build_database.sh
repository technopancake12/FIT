#!/usr/bin/env bash

# Master script to fetch data and build local database
# This script runs both wger and Open Food Facts fetchers, then builds SQLite/DuckDB

set -e  # Exit on any error

echo "🏗️  FitTracker Database Builder"
echo "================================"

# Check dependencies
echo "🔍 Checking dependencies..."
for cmd in jq curl wget sqlite3; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is required but not installed."
        case $cmd in
            jq) echo "   macOS: brew install jq";;
            curl) echo "   Usually pre-installed";;
            wget) echo "   macOS: brew install wget";;
            sqlite3) echo "   macOS: brew install sqlite3";;
        esac
        exit 1
    fi
done
echo "✅ All dependencies found"

# Create data directory
mkdir -p data
cd data

# Fetch wger exercises
echo ""
echo "🏋️  Fetching wger exercises..."
if [ -f "wger_exercises.json" ]; then
    echo "📁 Found existing wger data, skipping fetch"
    echo "   To re-fetch, delete wger_exercises.json and run again"
else
    bash ../scripts/fetch_wger_exercises.sh
fi

# Fetch Open Food Facts US data
echo ""
echo "🍎 Fetching Open Food Facts US data..."
if [ -f "us_products_final.json" ]; then
    echo "📁 Found existing Open Food Facts data, skipping fetch"
    echo "   To re-fetch, delete us_products_final.json and run again"
else
    bash ../scripts/fetch_openfoodfacts_us.sh
fi

# Build SQLite database
echo ""
echo "🗄️  Building SQLite database..."
sqlite3 fittracker.db << 'EOF'
-- Create exercises table
CREATE TABLE IF NOT EXISTS exercises (
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

-- Create foods table
CREATE TABLE IF NOT EXISTS foods (
    code TEXT PRIMARY KEY,
    product_name TEXT,
    generic_name TEXT,
    brands TEXT,
    categories TEXT,
    image_front_url TEXT,
    image_nutrition_url TEXT,
    energy_kcal_100g REAL,
    fat_100g REAL,
    saturated_fat_100g REAL,
    carbohydrates_100g REAL,
    sugars_100g REAL,
    fiber_100g REAL,
    proteins_100g REAL,
    salt_100g REAL,
    sodium_100g REAL,
    nutriscore_grade TEXT,
    nova_group INTEGER,
    serving_size TEXT,
    ingredients_text TEXT,
    allergens_tags TEXT,
    traces_tags TEXT,
    nutrition_data_per TEXT,
    nutrition_grade_fr TEXT,
    ecoscore_grade TEXT,
    last_modified_t INTEGER,
    created_t INTEGER
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exercises_category ON exercises(category_id);
CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name);
CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(product_name);
CREATE INDEX IF NOT EXISTS idx_foods_brands ON foods(brands);
CREATE INDEX IF NOT EXISTS idx_foods_categories ON foods(categories);
CREATE INDEX IF NOT EXISTS idx_foods_energy ON foods(energy_kcal_100g);

-- Import wger exercises
.mode json
.import wger_exercises.json exercises_temp

-- Transform and insert exercises data
INSERT INTO exercises (
    id, name, description, category_id, category_name, 
    equipment, muscles, muscles_secondary, language, license, license_author, created_at
)
SELECT 
    id,
    name,
    description,
    category->>'$.id' as category_id,
    category->>'$.name' as category_name,
    json_group_array(equipment->>'$.name') as equipment,
    json_group_array(muscles->>'$.name') as muscles,
    json_group_array(muscles_secondary->>'$.name') as muscles_secondary,
    language,
    license,
    license_author,
    creation_date
FROM exercises_temp
GROUP BY id;

-- Clean up temp table
DROP TABLE exercises_temp;

-- Import Open Food Facts data
.import us_products_final.json foods_temp

-- Transform and insert foods data
INSERT INTO foods (
    code, product_name, generic_name, brands, categories,
    image_front_url, image_nutrition_url,
    energy_kcal_100g, fat_100g, saturated_fat_100g,
    carbohydrates_100g, sugars_100g, fiber_100g,
    proteins_100g, salt_100g, sodium_100g,
    nutriscore_grade, nova_group, serving_size,
    ingredients_text, allergens_tags, traces_tags,
    nutrition_data_per, nutrition_grade_fr, ecoscore_grade,
    last_modified_t, created_t
)
SELECT 
    code,
    product_name,
    generic_name,
    brands,
    categories,
    image_front_url,
    image_nutrition_url,
    nutriments->>'$.energy_kcal_100g' as energy_kcal_100g,
    nutriments->>'$.fat_100g' as fat_100g,
    nutriments->>'$.saturated_fat_100g' as saturated_fat_100g,
    nutriments->>'$.carbohydrates_100g' as carbohydrates_100g,
    nutriments->>'$.sugars_100g' as sugars_100g,
    nutriments->>'$.fiber_100g' as fiber_100g,
    nutriments->>'$.proteins_100g' as proteins_100g,
    nutriments->>'$.salt_100g' as salt_100g,
    nutriments->>'$.sodium_100g' as sodium_100g,
    nutriscore_grade,
    nova_group,
    serving_size,
    ingredients_text,
    allergens_tags,
    traces_tags,
    nutrition_data_per,
    nutrition_grade_fr,
    ecoscore_grade,
    last_modified_t,
    created_t
FROM foods_temp;

-- Clean up temp table
DROP TABLE foods_temp;

-- Show statistics
SELECT 'Exercises' as table_name, COUNT(*) as count FROM exercises
UNION ALL
SELECT 'Foods' as table_name, COUNT(*) as count FROM foods;
EOF

echo "✅ SQLite database created: data/fittracker.db"

# Build DuckDB database (optional)
if command -v duckdb &> /dev/null; then
    echo ""
    echo "🦆 Building DuckDB database..."
    duckdb fittracker.duckdb << 'EOF'
-- Create exercises table
CREATE TABLE exercises AS 
SELECT * FROM read_json_auto('wger_exercises.json');

-- Create foods table  
CREATE TABLE foods AS 
SELECT * FROM read_json_auto('us_products_final.json');

-- Show statistics
SELECT 'Exercises' as table_name, COUNT(*) as count FROM exercises
UNION ALL
SELECT 'Foods' as table_name, COUNT(*) as count FROM foods;
EOF
    echo "✅ DuckDB database created: data/fittracker.duckdb"
else
    echo "⚠️  DuckDB not found, skipping DuckDB database creation"
    echo "   Install with: brew install duckdb"
fi

# Generate Swift models
echo ""
echo "📱 Generating Swift models..."
cat > ../FitTracker/Models/DatabaseModels.swift << 'EOF'
import Foundation

// MARK: - Database Exercise Model
struct DatabaseExercise: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let categoryId: Int?
    let categoryName: String?
    let equipment: String?
    let muscles: String?
    let musclesSecondary: String?
    let language: Int?
    let license: Int?
    let licenseAuthor: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language, license
        case categoryId = "category_id"
        case categoryName = "category_name"
        case equipment, muscles
        case musclesSecondary = "muscles_secondary"
        case licenseAuthor = "license_author"
        case createdAt = "created_at"
    }
    
    func toLocalExercise() -> Exercise {
        return Exercise(
            id: String(id),
            name: name,
            category: categoryName ?? "General",
            primaryMuscles: muscles?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            secondaryMuscles: musclesSecondary?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            equipment: equipment ?? "None",
            difficulty: .intermediate,
            instructions: [description ?? "No instructions available"],
            tips: [],
            alternatives: []
        )
    }
}

// MARK: - Database Food Model
struct DatabaseFood: Codable, Identifiable {
    let code: String
    let productName: String?
    let genericName: String?
    let brands: String?
    let categories: String?
    let imageFrontUrl: String?
    let imageNutritionUrl: String?
    let energyKcal100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fiber100g: Double?
    let proteins100g: Double?
    let salt100g: Double?
    let sodium100g: Double?
    let nutriscoreGrade: String?
    let novaGroup: Int?
    let servingSize: String?
    let ingredientsText: String?
    let allergensTags: String?
    let tracesTags: String?
    let nutritionDataPer: String?
    let nutritionGradeFr: String?
    let ecoscoreGrade: String?
    let lastModifiedT: Int?
    let createdT: Int?
    
    var id: String { code }
    
    enum CodingKeys: String, CodingKey {
        case code, brands, categories
        case productName = "product_name"
        case genericName = "generic_name"
        case imageFrontUrl = "image_front_url"
        case imageNutritionUrl = "image_nutrition_url"
        case energyKcal100g = "energy_kcal_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated_fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case proteins100g = "proteins_100g"
        case salt100g = "salt_100g"
        case sodium100g = "sodium_100g"
        case nutriscoreGrade = "nutriscore_grade"
        case novaGroup = "nova_group"
        case servingSize = "serving_size"
        case ingredientsText = "ingredients_text"
        case allergensTags = "allergens_tags"
        case tracesTags = "traces_tags"
        case nutritionDataPer = "nutrition_data_per"
        case nutritionGradeFr = "nutrition_grade_fr"
        case ecoscoreGrade = "ecoscore_grade"
        case lastModifiedT = "last_modified_t"
        case createdT = "created_t"
    }
    
    func toLocalFood() -> Food {
        return Food(
            name: productName ?? genericName ?? "Unknown Product",
            brand: brands,
            barcode: code,
            calories: energyKcal100g ?? 0,
            protein: proteins100g ?? 0,
            carbs: carbohydrates100g ?? 0,
            fat: fat100g ?? 0,
            fiber: fiber100g,
            sugar: sugars100g,
            sodium: sodium100g,
            category: categories ?? "General",
            servingSize: nil,
            servingUnit: "g",
            isVerified: true,
            imageUrl: imageFrontUrl
        )
    }
}
EOF

echo "✅ Swift models generated: FitTracker/Models/DatabaseModels.swift"

# Create database service
echo ""
echo "🔧 Creating database service..."
cat > ../FitTracker/Services/LocalDatabaseService.swift << 'EOF'
import Foundation
import SQLite3

class LocalDatabaseService: ObservableObject {
    static let shared = LocalDatabaseService()
    
    private var database: OpaquePointer?
    private let databasePath: String
    
    @Published var exercises: [DatabaseExercise] = []
    @Published var foods: [DatabaseFood] = []
    @Published var isLoading = false
    
    private init() {
        // Get the path to the database file in the app bundle
        if let bundlePath = Bundle.main.path(forResource: "fittracker", ofType: "db") {
            databasePath = bundlePath
        } else {
            // Fallback to documents directory for development
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            databasePath = documentsPath.appendingPathComponent("fittracker.db").path
        }
        
        openDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Management
    private func openDatabase() {
        if sqlite3_open(databasePath, &database) != SQLITE_OK {
            print("Error opening database: \(databasePath)")
            return
        }
        print("Database opened successfully: \(databasePath)")
    }
    
    private func closeDatabase() {
        if let db = database {
            sqlite3_close(db)
        }
    }
    
    // MARK: - Exercise Queries
    func searchExercises(query: String, category: String? = nil) async throws -> [DatabaseExercise] {
        var sql = """
            SELECT * FROM exercises 
            WHERE name LIKE ? OR description LIKE ?
        """
        var params: [String] = ["%\(query)%", "%\(query)%"]
        
        if let category = category, !category.isEmpty {
            sql += " AND category_name LIKE ?"
            params.append("%\(category)%")
        }
        
        sql += " ORDER BY name LIMIT 50"
        
        return try await executeQuery(sql: sql, params: params) { statement in
            try self.parseExercise(from: statement)
        }
    }
    
    func getExercisesByCategory(_ category: String) async throws -> [DatabaseExercise] {
        let sql = "SELECT * FROM exercises WHERE category_name LIKE ? ORDER BY name"
        return try await executeQuery(sql: sql, params: ["%\(category)%"]) { statement in
            try self.parseExercise(from: statement)
        }
    }
    
    func getExerciseCategories() async throws -> [String] {
        let sql = "SELECT DISTINCT category_name FROM exercises WHERE category_name IS NOT NULL ORDER BY category_name"
        return try await executeQuery(sql: sql, params: []) { statement in
            String(cString: sqlite3_column_text(statement, 0))
        }
    }
    
    // MARK: - Food Queries
    func searchFoods(query: String, category: String? = nil) async throws -> [DatabaseFood] {
        var sql = """
            SELECT * FROM foods 
            WHERE product_name LIKE ? OR generic_name LIKE ? OR brands LIKE ?
        """
        var params: [String] = ["%\(query)%", "%\(query)%", "%\(query)%"]
        
        if let category = category, !category.isEmpty {
            sql += " AND categories LIKE ?"
            params.append("%\(category)%")
        }
        
        sql += " ORDER BY product_name LIMIT 50"
        
        return try await executeQuery(sql: sql, params: params) { statement in
            try self.parseFood(from: statement)
        }
    }
    
    func getFoodByBarcode(_ barcode: String) async throws -> DatabaseFood? {
        let sql = "SELECT * FROM foods WHERE code = ?"
        let results = try await executeQuery(sql: sql, params: [barcode]) { statement in
            try self.parseFood(from: statement)
        }
        return results.first
    }
    
    func getFoodCategories() async throws -> [String] {
        let sql = "SELECT DISTINCT categories FROM foods WHERE categories IS NOT NULL ORDER BY categories"
        return try await executeQuery(sql: sql, params: []) { statement in
            String(cString: sqlite3_column_text(statement, 0))
        }
    }
    
    // MARK: - Helper Methods
    private func executeQuery<T>(sql: String, params: [String], parser: (OpaquePointer) throws -> T) async throws -> [T] {
        guard let db = database else {
            throw DatabaseError.databaseNotOpen
        }
        
        var statement: OpaquePointer?
        var results: [T] = []
        
        defer {
            sqlite3_finalize(statement)
        }
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            throw DatabaseError.prepareFailed
        }
        
        // Bind parameters
        for (index, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), param, -1, nil)
        }
        
        // Execute and parse results
        while sqlite3_step(statement) == SQLITE_ROW {
            let result = try parser(statement!)
            results.append(result)
        }
        
        return results
    }
    
    private func parseExercise(from statement: OpaquePointer) throws -> DatabaseExercise {
        return DatabaseExercise(
            id: Int(sqlite3_column_int(statement, 0)),
            name: String(cString: sqlite3_column_text(statement, 1)),
            description: sqlite3_column_text(statement, 2).map { String(cString: $0) },
            categoryId: sqlite3_column_type(statement, 3) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 3)),
            categoryName: sqlite3_column_text(statement, 4).map { String(cString: $0) },
            equipment: sqlite3_column_text(statement, 5).map { String(cString: $0) },
            muscles: sqlite3_column_text(statement, 6).map { String(cString: $0) },
            musclesSecondary: sqlite3_column_text(statement, 7).map { String(cString: $0) },
            language: sqlite3_column_type(statement, 8) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 8)),
            license: sqlite3_column_type(statement, 9) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 9)),
            licenseAuthor: sqlite3_column_text(statement, 10).map { String(cString: $0) },
            createdAt: sqlite3_column_text(statement, 11).map { String(cString: $0) }
        )
    }
    
    private func parseFood(from statement: OpaquePointer) throws -> DatabaseFood {
        return DatabaseFood(
            code: String(cString: sqlite3_column_text(statement, 0)),
            productName: sqlite3_column_text(statement, 1).map { String(cString: $0) },
            genericName: sqlite3_column_text(statement, 2).map { String(cString: $0) },
            brands: sqlite3_column_text(statement, 3).map { String(cString: $0) },
            categories: sqlite3_column_text(statement, 4).map { String(cString: $0) },
            imageFrontUrl: sqlite3_column_text(statement, 5).map { String(cString: $0) },
            imageNutritionUrl: sqlite3_column_text(statement, 6).map { String(cString: $0) },
            energyKcal100g: sqlite3_column_type(statement, 7) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 7),
            fat100g: sqlite3_column_type(statement, 8) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 8),
            saturatedFat100g: sqlite3_column_type(statement, 9) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 9),
            carbohydrates100g: sqlite3_column_type(statement, 10) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 10),
            sugars100g: sqlite3_column_type(statement, 11) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 11),
            fiber100g: sqlite3_column_type(statement, 12) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 12),
            proteins100g: sqlite3_column_type(statement, 13) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 13),
            salt100g: sqlite3_column_type(statement, 14) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 14),
            sodium100g: sqlite3_column_type(statement, 15) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 15),
            nutriscoreGrade: sqlite3_column_text(statement, 16).map { String(cString: $0) },
            novaGroup: sqlite3_column_type(statement, 17) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 17)),
            servingSize: sqlite3_column_text(statement, 18).map { String(cString: $0) },
            ingredientsText: sqlite3_column_text(statement, 19).map { String(cString: $0) },
            allergensTags: sqlite3_column_text(statement, 20).map { String(cString: $0) },
            tracesTags: sqlite3_column_text(statement, 21).map { String(cString: $0) },
            nutritionDataPer: sqlite3_column_text(statement, 22).map { String(cString: $0) },
            nutritionGradeFr: sqlite3_column_text(statement, 23).map { String(cString: $0) },
            ecoscoreGrade: sqlite3_column_text(statement, 24).map { String(cString: $0) },
            lastModifiedT: sqlite3_column_type(statement, 25) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 25)),
            createdT: sqlite3_column_type(statement, 26) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 26))
        )
    }
}

// MARK: - Database Errors
enum DatabaseError: Error, LocalizedError {
    case databaseNotOpen
    case prepareFailed
    case executionFailed
    
    var errorDescription: String? {
        switch self {
        case .databaseNotOpen:
            return "Database is not open"
        case .prepareFailed:
            return "Failed to prepare SQL statement"
        case .executionFailed:
            return "Failed to execute SQL statement"
        }
    }
}
EOF

echo "✅ Database service created: FitTracker/Services/LocalDatabaseService.swift"

echo ""
echo "🎉 Database build completed!"
echo ""
echo "📊 Summary:"
echo "   - SQLite database: data/fittracker.db"
if command -v duckdb &> /dev/null; then
    echo "   - DuckDB database: data/fittracker.duckdb"
fi
echo "   - Swift models: FitTracker/Models/DatabaseModels.swift"
echo "   - Database service: FitTracker/Services/LocalDatabaseService.swift"
echo ""
echo "🚀 Next steps:"
echo "1. Copy fittracker.db to your Xcode project bundle"
echo "2. Use LocalDatabaseService in your SwiftUI views"
echo "3. Test with sample queries" 