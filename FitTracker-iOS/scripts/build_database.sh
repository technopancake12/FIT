#!/usr/bin/env bash
# Simplified master script for building FitTracker DuckDB database only

set -e

echo "🏗️  FitTracker DuckDB Database Builder"
echo "======================================"

# Ensure duckdb and jq are installed
for cmd in duckdb jq curl wget gunzip; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is required but not installed."
        exit 1
    fi
done
echo "✅ All dependencies found"

# Prepare data directory
mkdir -p data
cd data

# Step 1: Fetch wger exercises
echo ""
echo "🏋️  Fetching wger exercises..."
if [ ! -f "wger_exercises.json" ]; then
    bash ../scripts/fetch_wger_exercises.sh
else
    echo "📁 Existing wger_exercises.json found, skipping."
fi

# Step 2: Fetch Open Food Facts
echo ""
echo "🍎 Fetching Open Food Facts US data..."
if [ ! -f "us_products_final.json" ]; then
    bash ../scripts/fetch_openfoodfacts_us.sh
else
    echo "📁 Existing us_products_final.json found, skipping."
fi

# Step 3: Build DuckDB
echo ""
echo "🦆 Building DuckDB database..."
duckdb fittracker.duckdb <<EOF
-- Overwrite existing tables
DROP TABLE IF EXISTS exercises;
DROP TABLE IF EXISTS foods;

-- Load JSON data
CREATE TABLE exercises AS 
SELECT * FROM read_json_auto('wger_exercises.json');

CREATE TABLE foods AS 
SELECT * FROM read_json_auto('us_products_final.json');

-- Create basic indexes (DuckDB creates implicit indexes)
-- Optional: we skip indexing to keep things simple

-- Count entries
SELECT 'exercises' AS table, COUNT(*) FROM exercises
UNION ALL
SELECT 'foods', COUNT(*) FROM foods;
EOF

echo ""
echo "✅ DuckDB database created at: data/fittracker.duckdb"
echo "🎉 You're ready to integrate with Swift using DuckDB C/Swift bindings or convert to SQLite if needed."
