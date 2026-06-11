# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Cursor, GitHub Copilot, Gemini, etc.) when working with code in this repository. It follows the open AGENTS.md convention.

> **Note:** CLAUDE.md in this repository is a one-line redirect to AGENTS.md. Edit AGENTS.md only.

## Development Commands

### Building and Testing
```bash
# Run all tests (unit tests)
xcodebuild test \
  -scheme FRTestHost \
  -workspace e2e/FRExample.xcworkspace \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -derivedDataPath DerivedData \
  TEST_TARGET_SIGNING=YES \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults

# Build for iOS Simulator (example destination)
xcodebuild build \
  -scheme FRTestHost \
  -workspace e2e/FRExample.xcworkspace \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'

# Open the project in Xcode
open e2e/FRExample.xcworkspace
```

### Validation and Linting
```bash
# Validate podspec files
pod lib lint FRAuth.podspec
pod lib lint FRCore.podspec
# (Repeat for other modules: FRAuthenticator, FRDeviceBinding, FRUI, etc.)

# Swift Package Manager validation
swift build
```

### Module Testing
Individual modules can be tested by changing the scheme in the xcodebuild command:
- FRTestHost (contains all tests)
- Individual module tests are bundled within the FRTestHost scheme

## Architecture Overview

### Module Structure
The SDK is organized into multiple modular frameworks:

**Core Modules:**
- `FRCore`: Foundation layer with common utilities, networking, logging, keychain management
- `FRAuth`: Main authentication module with OIDC client, Journey integration, WebAuthn, OAuth2
- `FRAuthenticator`: Multi-factor authentication with TOTP and Push notifications

**Add-on Modules:**
- `FRDeviceBinding`: Device binding capabilities with cryptographic key pairs
- `FRProximity`: Location and BLE proximity features
- `FRCaptchaEnterprise`: Google reCAPTCHA Enterprise integration
- `PingProtect`: Ping Protect fraud detection integration

**Social Login Modules:**
- `FRGoogleSignIn`: Google Sign-In integration
- `FRFacebookSignIn`: Facebook Login integration

**UI Module (Deprecated):**
- `FRUI`: Pre-built UI components for Journey integration

### Key Directory Structure
```
FRCore/FRCore/
├── Authenticator/     # Certificate and key management
├── Error/            # Error handling
├── Keychain/         # Secure storage
├── Log/              # Logging framework
├── Network/          # HTTP client and networking

FRAuth/FRAuth/
├── AppIntegrity/     # App attestation
├── Authentication/   # Auth flows and session management
├── Authorization/    # OAuth2 and policy handling
├── Callbacks/        # Journey callback implementations
├── Device/           # Device profiling and collection
├── WebAuthn/         # WebAuthn authentication
```

### Package Management
The project supports both CocoaPods and Swift Package Manager:
- CocoaPods: Individual `.podspec` files for each module
- SPM: Centralized `Package.swift` with all module definitions
- Dependencies managed through Package.swift (JOSESwift, Facebook SDK, Google Sign-In, etc.)

### Testing Structure
- All tests are consolidated under `FRTestHost` scheme
- Unit tests located in each module's `Tests` directory
- E2E tests in `e2e/` directory with sample app
- Tests use XCTest framework
- Test configuration files in `FRTestHost/FRTestHost/SharedTestFiles/TestConfig/`

### Platform Requirements
- iOS 12.0+ deployment target
- Swift 5.0+
- Xcode 16.2+ for builds
- Supports both Swift Package Manager and CocoaPods integration

## Development Notes

### Branch Strategy
- `master`: Main production branch
- `develop`: Development branch for integration
- Create feature branches from `develop`
- PRs should target `develop` branch

### CI/CD
The project uses GitHub Actions for CI with:
- Automated builds and tests on PR/push
- Device farm testing with BitBar
- Slack notifications for build status
- Security scanning with Mend CLI