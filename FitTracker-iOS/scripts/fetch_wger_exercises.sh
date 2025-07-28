#!/usr/bin/env bash

# Fetch all exercises from wger API
# This script downloads all English-language exercises and saves them to a JSON file

set -e  # Exit on any error

# Configuration
API_BASE="https://wger.de/api/v2"
OUTPUT_FILE="wger_exercises.json"
API_KEY="c5bf06de75b1642db24c405fbbb05a0c779a0f0e"  # Replace with your actual API key
PAGE=1
TEMP_FILE="temp_exercises.json"

echo "🚀 Starting wger exercise fetch..."

# Clear output file
> "$OUTPUT_FILE"

# Create a temporary file to store all exercises
> "$TEMP_FILE"

echo "📥 Fetching exercises from wger API..."

while true; do
    echo "  Fetching page $PAGE..."
    
    # Make API request with authentication
    response=$(curl -s -H "Authorization: Token $API_KEY" \
                    -H "Accept: application/json" \
                    "$API_BASE/exercise/?language=2&page=$PAGE&limit=50")
    
    # Check if response is valid JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        echo "❌ Invalid JSON response on page $PAGE"
        echo "Response: $response"
        exit 1
    fi
    
    # Extract results and append to temp file
    result_count=$(echo "$response" | jq '.results | length')
    if [ "$result_count" -eq 0 ]; then
        echo "  No more results on page $PAGE"
        break
    fi
    
    echo "$response" | jq '.results[]' >> "$TEMP_FILE"
    echo "  ✅ Added $result_count exercises from page $PAGE"
    
    # Check if there's a next page
    next_url=$(echo "$response" | jq -r '.next')
    if [ "$next_url" = "null" ] || [ -z "$next_url" ]; then
        echo "  No more pages available"
        break
    fi
    
    PAGE=$((PAGE + 1))
    
    # Rate limiting - be respectful to the API
    sleep 0.5
done

# Combine all exercises into a single JSON array
echo "📝 Combining all exercises..."
echo '[' > "$OUTPUT_FILE"
cat "$TEMP_FILE" | paste -sd ',' - >> "$OUTPUT_FILE"
echo ']' >> "$OUTPUT_FILE"

# Clean up temp file
rm "$TEMP_FILE"

# Count total exercises
total_exercises=$(jq length "$OUTPUT_FILE")
echo "✅ Successfully fetched $total_exercises exercises"
echo "📁 Data saved to: $OUTPUT_FILE"

# Display some sample data
echo ""
echo "📊 Sample exercise data:"
jq '.[0:3] | .[] | {id, name, category: .category.name}' "$OUTPUT_FILE"

echo ""
echo "🎯 Next steps:"
echo "1. Import to SQLite: sqlite3 exercises.db '.read import_wger.sql'"
echo "2. Import to DuckDB: duckdb exercises.duckdb 'CREATE TABLE exercises AS SELECT * FROM read_json_auto(\"$OUTPUT_FILE\");'" 