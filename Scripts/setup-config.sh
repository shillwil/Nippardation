#!/bin/bash

# This script helps set up xcconfig files from templates

echo "Setting up Xcode configuration files..."

CONFIG_DIR="${PROJECT_DIR:-$(dirname "$0")/../Nippardation/Configuration}"

# Function to copy template if config doesn't exist
copy_template() {
    local template="$1"
    local target="${template%.template}"
    
    if [ ! -f "$CONFIG_DIR/$target" ]; then
        echo "Creating $target from template..."
        cp "$CONFIG_DIR/$template" "$CONFIG_DIR/$target"
    else
        echo "$target already exists, skipping..."
    fi
}

# Copy all template files
copy_template "Staging.xcconfig.template"
copy_template "Production.xcconfig.template"
copy_template "Debug.xcconfig.template"

# Check if Shared.xcconfig exists (it doesn't have sensitive data)
if [ ! -f "$CONFIG_DIR/Shared.xcconfig" ]; then
    echo "Warning: Shared.xcconfig is missing!"
fi

echo ""
echo "Setup complete! Now you need to:"
echo "1. Edit the following files with your actual values:"
echo "   - $CONFIG_DIR/Staging.xcconfig"
echo "   - $CONFIG_DIR/Production.xcconfig"
echo "   - $CONFIG_DIR/Debug.xcconfig"
echo ""
echo "2. Replace these placeholders:"
echo "   - YOUR_BUNDLE_ID_HERE with your bundle identifier"
echo "   - YOUR_STAGING_API_URL_HERE with your staging API URL"
echo "   - YOUR_PRODUCTION_API_URL_HERE with your production API URL"
echo "   - YOUR_TEAM_ID_HERE with your Apple Developer Team ID"