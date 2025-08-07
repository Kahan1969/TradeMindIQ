#!/bin/bash

# Navigate to the correct directory
cd "/Users/kahangabar/Desktop/TradeMindIQ/tradem_app"

# Confirm we're in the right place
echo "Current directory: $(pwd)"
echo "Contents: $(ls -la package.json 2>/dev/null && echo "package.json found" || echo "package.json NOT found")"

# Start the development server
echo "Starting React development server..."
npm start
