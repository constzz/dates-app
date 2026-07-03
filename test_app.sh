#!/bin/bash
# Test script for DatesApp on iOS Simulator

set -e

DEVICE="iPhone 14 Pro"
APP_PATH="/tmp/dates_app"
IPA_PATH="bazel-bin/modules/test_valdi/DatesApp.ipa"
BUNDLE_ID="com.dates.app"

echo "🔨 Building app..."
bazel build //modules/test_valdi:DatesApp

echo "📦 Extracting .ipa..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH"
cd "$APP_PATH"
unzip -q "$OLDPWD/$IPA_PATH"

echo "📱 Booting simulator..."
xcrun simctl boot "$DEVICE" 2>/dev/null || echo "Simulator already booted"

echo "🚀 Opening Simulator.app..."
open -a Simulator

echo "📲 Installing app..."
xcrun simctl install "$DEVICE" "$APP_PATH/Payload/DatesApp.app"

echo "▶️  Launching app..."
xcrun simctl launch "$DEVICE" "$BUNDLE_ID"

echo "✅ DatesApp is now running on $DEVICE"
echo "   Bundle ID: $BUNDLE_ID"
