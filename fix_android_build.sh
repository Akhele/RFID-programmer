#!/bin/bash

echo "🔧 Fixing Android build issues..."
echo ""

# Remove old Gradle caches
echo "1. Removing old Gradle caches..."
rm -rf ~/.gradle/caches/8.0
rm -rf android/.gradle

# Clean Flutter build
echo "2. Cleaning Flutter build..."
flutter clean

# Get dependencies
echo "3. Getting dependencies..."
flutter pub get

echo ""
echo "✅ Done! Now try running:"
echo "   flutter run"

