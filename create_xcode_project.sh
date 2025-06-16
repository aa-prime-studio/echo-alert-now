#!/bin/bash

# SignalAir iOS Project Generator
# This script creates a complete Xcode project for SignalAir

set -e  # Exit on any error

PROJECT_NAME="SignalAir"
PROJECT_DIR="SignalAir-iOS"
BUNDLE_ID="com.signalair.app"

echo "🚀 Creating SignalAir iOS Project..."

# Create project directory
rm -rf "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "SignalAir"
mkdir -p "SignalAir/App"
mkdir -p "SignalAir/Features/Signal"
mkdir -p "SignalAir/Features/Chat"
mkdir -p "SignalAir/Features/Game"
mkdir -p "SignalAir/Features/Settings"
mkdir -p "SignalAir/Features/Legal"
mkdir -p "SignalAir/Services"
mkdir -p "SignalAir/Shared/Models"

echo "📝 Creating Swift files..."

# Create Info.plist
cat > "SignalAir/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF

# Call other scripts to create Swift files
echo "📱 Creating App files..."
../create_app_files.sh

echo "📊 Creating Model files..."
../create_model_files.sh

echo "⚙️ Creating Service files..."
../create_service_files.sh

echo "🎯 Creating Feature files..."
../create_feature_files.sh
../create_remaining_features.sh
../create_legal_purchase_files.sh

# Create Xcode project
echo "🔨 Creating Xcode project..."
python3 ../create_xcodeproj.py

echo "✅ SignalAir iOS Project created successfully!"
echo "📱 You can now:"
echo "   1. Open SignalAir.xcodeproj in Xcode for preview and testing"
echo "   2. Open this folder in Cursor for code editing"
echo "   3. Files will sync automatically between both editors"
echo ""
echo "🎯 Project location: $(pwd)" 