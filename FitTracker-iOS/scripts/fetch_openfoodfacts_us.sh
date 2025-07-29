#!/usr/bin/env bash
# Download and filter Open Food Facts to get up to 50,000 US-origin food items

set -e

DATA_URL="https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz"
COMPRESSED="openfoodfacts-products.jsonl.gz"
EXTRACTED="openfoodfacts-products.jsonl"
FINAL_JSON="us_products_final.json"
MAX_PRODUCTS=50000

echo "🚀 Starting Open Food Facts fetch..."

# Check required tools
for cmd in jq wget gunzip grep; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Missing required tool: $cmd"
        exit 1
    fi
done

# Download if needed
if [ ! -f "$COMPRESSED" ]; then
    echo "📥 Downloading large dataset (~2GB)..."
    wget --progress=bar:force "$DATA_URL"
fi

# Extract if needed
if [ ! -f "$EXTRACTED" ]; then
    echo "📦 Extracting JSONL..."
    gunzip -k "$COMPRESSED"
fi

echo "🔍 Filtering for US products (up to $MAX_PRODUCTS entries)..."

> "$FINAL_JSON"
echo "[" >> "$FINAL_JSON"

COUNT=0
while IFS= read -r line && [ $COUNT -lt $MAX_PRODUCTS ]; do
    echo "$line" | grep '"countries_tags":[^]]*"us"' &> /dev/null || continue

    echo "$line" | jq -c '{
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
    }' | sed 's/$/,/' >> "$FINAL_JSON"

    COUNT=$((COUNT + 1))
    if (( COUNT % 5000 == 0 )); then
        echo "  ✅ Processed $COUNT..."
    fi
done < "$EXTRACTED"

# Remove last comma and close array
sed -i '' -e '$ s/,$//' "$FINAL_JSON"
echo "]" >> "$FINAL_JSON"

echo "✅ Fetched $COUNT US food items"
