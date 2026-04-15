#!/bin/bash

# Generate version using timestamp
VERSION=$(date +%s)

echo "Updating version to $VERSION..."

# Update version in index.html
# Adjusted to flutter_bootstrap.js since that is the entry point being versioned in this project
sed -i '' "s/flutter_bootstrap.js?v=[^\"]*/flutter_bootstrap.js?v=$VERSION/g" web/index.html

echo "Building Flutter web..."
flutter build web

echo "Deploying to Firebase..."
firebase deploy

echo "Done 🚀 Version: $VERSION"
