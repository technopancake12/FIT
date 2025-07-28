#!/usr/bin/env bash

# Download and filter Open Food Facts data for US products only
# This script downloads the full dump and filters for US-origin foods

set -e  # Exit on any error

# Configuration
DATA_URL="https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz"
OUTPUT_FILE="us_products.jsonl"
FILTERED_FILE="us_products_filtered.jsonl"
FINAL_FILE="us_products_final.json"

echo "🚀 Starting Open Food Facts US data fetch..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed. Please install jq first."
    echo "   macOS: brew install jq"
    echo "   Ubuntu: sudo apt-get install jq"
    exit 1
fi

# Download the full dump if it doesn't exist
if [ ! -f "openfoodfacts-products.jsonl.gz" ]; then
    echo "📥 Downloading Open Food Facts full dump..."
    echo "   This is a large file (~2GB compressed, ~8GB uncompressed)"
    echo "   Download may take several minutes depending on your connection..."
    
    wget --progress=bar:force "$DATA_URL"
    echo "✅ Download completed"
else
    echo "📁 Found existing download: openfoodfacts-products.jsonl.gz"
fi

# Extract if needed
if [ ! -f "openfoodfacts-products.jsonl" ]; then
    echo "📦 Extracting compressed file..."
    gunzip -k openfoodfacts-products.jsonl.gz
    echo "✅ Extraction completed"
else
    echo "📁 Found existing extracted file: openfoodfacts-products.jsonl"
fi

echo "🔍 Filtering for US products..."

# Filter for US products and extract relevant fields
echo "   Processing products (this may take 10-30 minutes)..."
grep '"countries_tags":[^]]*"us"' openfoodfacts-products.jsonl | \
    jq -c '{
        code,
        product_name,
        generic_name,
        brands,
        categories,
        image_front_url,
        image_nutrition_url,
        nutriments: {
            energy_kcal_100g: .nutriments."energy-kcal_100g",
            fat_100g: .nutriments.fat_100g,
            saturated_fat_100g: .nutriments."saturated-fat_100g",
            carbohydrates_100g: .nutriments.carbohydrates_100g,
            sugars_100g: .nutriments.sugars_100g,
            fiber_100g: .nutriments.fiber_100g,
            proteins_100g: .nutriments.proteins_100g,
            salt_100g: .nutriments.salt_100g,
            sodium_100g: .nutriments.sodium_100g
        },
        nutriscore_grade,
        nova_group,
        serving_size,
        packaging_tags,
        ingredients_text,
        allergens_tags,
        traces_tags,
        nutrition_data_per,
        nutrition_grade_fr,
        ecoscore_grade,
        last_modified_t,
        created_t
    }' > "$FILTERED_FILE"

# Count total US products
total_products=$(wc -l < "$FILTERED_FILE")
echo "✅ Found $total_products US products"

# Convert to JSON array format for easier processing
echo "📝 Converting to JSON array format..."
echo '[' > "$FINAL_FILE"
cat "$FILTERED_FILE" | paste -sd ',' - >> "$FINAL_FILE"
echo ']' >> "$FINAL_FILE"

# Clean up intermediate files
rm "$FILTERED_FILE"

# Display statistics
echo ""
echo "📊 Data Statistics:"
echo "   Total US products: $total_products"
echo "   File size: $(du -h "$FINAL_FILE" | cut -f1)"

# Show sample data
echo ""
echo "📋 Sample product data:"
jq '.[0:3] | .[] | {code, product_name, brands, energy_kcal_100g: .nutriments.energy_kcal_100g}' "$FINAL_FILE"

echo ""
echo "🎯 Next steps:"
echo "1. Import to SQLite: sqlite3 foods.db '.read import_openfoodfacts.sql'"
echo "2. Import to DuckDB: duckdb foods.duckdb 'CREATE TABLE us_foods AS SELECT * FROM read_json_auto(\"$FINAL_FILE\");'"
echo "3. Use in Swift app with SQLite.swift or GRDB"

# Optional: Clean up large files
echo ""
read -p "🗑️  Remove large intermediate files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Cleaning up large files..."
    rm -f openfoodfacts-products.jsonl.gz openfoodfacts-products.jsonl
    echo "✅ Cleanup completed"
fi 