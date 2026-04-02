#!/bin/bash
set -e

OUTPUT_DIR="build/xcframeworks"
DERIVED_DATA="build/DerivedData"
ARCHIVES="build/archives"
mkdir -p "$OUTPUT_DIR"

LIBRARIES=(
  #FRCore FRAuth FRAuthenticator FRProximity
  #FRDeviceBinding FRFacebookSignIn FRGoogleSignIn
  FRCaptchaEnterprise
  #PingProtect
)

for LIB in "${LIBRARIES[@]}"; do
  echo "=== Building $LIB ==="

  # Archive for iOS device
  xcodebuild archive \
    -project "$LIB/$LIB.xcodeproj" \
    -scheme "$LIB" \
    -configuration "Release" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVES/${LIB}-iOS" \
    -derivedDataPath "$DERIVED_DATA" \
    SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

  # Archive for iOS Simulator
  xcodebuild archive \
    -project "$LIB/$LIB.xcodeproj" \
    -scheme "$LIB" \
    -configuration "Release" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$ARCHIVES/${LIB}-iOS-Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

  # Create XCFramework
  xcodebuild -create-xcframework \
    -archive "$ARCHIVES/${LIB}-iOS.xcarchive" -framework "${LIB}.framework" \
    -archive "$ARCHIVES/${LIB}-iOS-Simulator.xcarchive" -framework "${LIB}.framework" \
    -output "$OUTPUT_DIR/${LIB}.xcframework"

  echo "=== $LIB.xcframework created ==="
done
