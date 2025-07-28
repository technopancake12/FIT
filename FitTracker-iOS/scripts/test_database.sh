#!/usr/bin/env bash

# Test script to verify database setup and show sample queries

set -e

echo "🧪 FitTracker Database Test"
echo "============================"

# Check if database exists
if [ ! -f "data/fittracker.db" ]; then
    echo "❌ Database not found. Please run ./scripts/build_database.sh first."
    exit 1
fi

echo "✅ Database found: data/fittracker.db"

# Test basic queries
echo ""
echo "📊 Database Statistics:"
sqlite3 data/fittracker.db << 'EOF'
.headers on
.mode column
SELECT 'Exercises' as table_name, COUNT(*) as count FROM exercises
UNION ALL
SELECT 'Foods' as table_name, COUNT(*) as count FROM foods;
EOF

echo ""
echo "🏋️  Sample Exercises:"
sqlite3 data/fittracker.db << 'EOF'
.headers on
.mode column
SELECT name, category_name, equipment 
FROM exercises 
WHERE name LIKE '%curl%' 
ORDER BY name 
LIMIT 5;
EOF

echo ""
echo "🍎 Sample Foods:"
sqlite3 data/fittracker.db << 'EOF'
.headers on
.mode column
SELECT product_name, brands, energy_kcal_100g, proteins_100g, carbohydrates_100g, fat_100g
FROM foods 
WHERE product_name LIKE '%apple%' 
ORDER BY product_name 
LIMIT 5;
EOF

echo ""
echo "📋 Exercise Categories:"
sqlite3 data/fittracker.db << 'EOF'
.headers on
.mode column
SELECT category_name, COUNT(*) as count
FROM exercises 
WHERE category_name IS NOT NULL 
GROUP BY category_name 
ORDER BY count DESC 
LIMIT 10;
EOF

echo ""
echo "🔍 Search Test - Exercises with 'squat':"
sqlite3 data/fittracker.db << 'EOF'
.headers on
.mode column
SELECT name, category_name, muscles
FROM exercises 
WHERE name LIKE '%squat%' 
ORDER BY name 
LIMIT 3;
EOF

echo ""
echo "🔍 Search Test - Foods with 'chicken':"
sqlite3 data/fittracker.db << 'EOF'
.headers on
.mode column
SELECT product_name, brands, energy_kcal_100g
FROM foods 
WHERE product_name LIKE '%chicken%' 
ORDER BY product_name 
LIMIT 3;
EOF

echo ""
echo "✅ Database test completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "1. Copy data/fittracker.db to your Xcode project bundle"
echo "2. Use LocalDatabaseService in your SwiftUI views"
echo "3. Test the LocalDatabaseDemoView" 