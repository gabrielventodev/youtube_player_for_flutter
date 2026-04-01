#!/bin/bash
# Build the KMP shared framework for iOS
# Run this on macOS before building the iOS Flutter app

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/shared"
IOS_DIR="$SCRIPT_DIR/ios"

echo "Building Shared frameworks for iOS..."
cd "$SHARED_DIR"
./gradlew linkReleaseFrameworkIosArm64 linkReleaseFrameworkIosSimulatorArm64 linkReleaseFrameworkIosX64

echo "Creating XCFramework..."
mkdir -p "$IOS_DIR/Frameworks"
rm -rf "$IOS_DIR/Frameworks/Shared.xcframework"

xcodebuild -create-xcframework \
  -framework "$SHARED_DIR/build/bin/iosArm64/releaseFramework/Shared.framework" \
  -framework "$SHARED_DIR/build/bin/iosSimulatorArm64/releaseFramework/Shared.framework" \
  -output "$IOS_DIR/Frameworks/Shared.xcframework"

echo "Done! Shared.xcframework is ready at ios/Frameworks/"
