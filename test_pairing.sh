#!/bin/bash
set -e

echo "🚀 Setting up two simulators for pairing test..."

# Device IDs
DEVICE1="iPhone 14 Pro"
DEVICE2="iPhone 15"

# Boot both simulators
echo "📱 Booting $DEVICE1..."
xcrun simctl boot "$DEVICE1" 2>/dev/null || echo "$DEVICE1 already booted"

echo "📱 Booting $DEVICE2..."
xcrun simctl boot "$DEVICE2" 2>/dev/null || echo "$DEVICE2 already booted"

# Build app
echo "🔨 Building app..."
bazel build //modules/test_valdi:DatesApp

# Extract IPA
echo "📦 Extracting IPA..."
cd bazel-bin/modules/test_valdi
rm -rf app_payload
unzip -q DatesApp.ipa -d app_payload

# Install on both devices
echo "📲 Installing on $DEVICE1..."
xcrun simctl install "$DEVICE1" app_payload/Payload/DatesApp.app

echo "📲 Installing on $DEVICE2..."
xcrun simctl install "$DEVICE2" app_payload/Payload/DatesApp.app

# Open Simulator app
echo "🚀 Opening Simulator..."
open -a Simulator

# Launch on both
echo "▶️  Launching on $DEVICE1..."
xcrun simctl launch "$DEVICE1" com.dates.app

echo "▶️  Launching on $DEVICE2..."
xcrun simctl launch "$DEVICE2" com.dates.app

echo ""
echo "✅ Both simulators are ready!"
echo ""
echo "📋 Testing instructions:"
echo "1. $DEVICE1: Login as user1@test.com / password123"
echo "2. $DEVICE1: Tap heart icon → Create Invitation"
echo "3. $DEVICE2: Login as user2@test.com / password123"
echo "4. $DEVICE2: Tap heart icon → Enter Partner's Code"
echo "5. Both devices should show 'Paired' status"
echo "6. Create a date on either device"
echo "7. Wait 10 seconds (auto-sync)"
echo "8. Verify it appears on both devices"
echo ""
echo "💡 Backend must be running: cd backend && go run ./cmd/dates-api/"
