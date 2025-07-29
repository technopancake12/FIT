#!/usr/bin/env bash
# Fetch up to 1000 English-language exercises from the wger API

set -e

API_BASE="https://wger.de/api/v2"
API_KEY="c5bf06de75b1642db24c405fbbb05a0c779a0f0e"
OUTPUT_FILE="wger_exercises.json"
MAX_RESULTS=1000
PAGE=1
COUNT=0

echo "🚀 Fetching up to $MAX_RESULTS exercises from wger..."

> "$OUTPUT_FILE"
echo "[" >> "$OUTPUT_FILE"

while [ $COUNT -lt $MAX_RESULTS ]; do
    echo "  ⏳ Page $PAGE..."

    response=$(curl -s -H "Authorization: Token $API_KEY" \
                    -H "Accept: application/json" \
                    "$API_BASE/exercise/?language=2&page=$PAGE&limit=50")

    results=$(echo "$response" | jq '.results')
    result_count=$(echo "$results" | jq length)

    if [ "$result_count" -eq 0 ]; then
        echo "  ✅ No more results."
        break
    fi

    remaining=$((MAX_RESULTS - COUNT))
    to_take=$((result_count < remaining ? result_count : remaining))

    # Take up to the remaining needed
    echo "$results" | jq -c ".[:$to_take][]" | sed 's/$/,/' >> "$OUTPUT_FILE"
    COUNT=$((COUNT + to_take))

    if [ "$result_count" -lt 50 ]; then
        break
    fi

    PAGE=$((PAGE + 1))
    sleep 0.5
done

# Remove last comma and close JSON array
sed -i '' -e '$ s/,$//' "$OUTPUT_FILE"
echo "]" >> "$OUTPUT_FILE"

echo "✅ Fetched $COUNT exercises"
