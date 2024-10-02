// swift-tools-version:5.3
import PackageDescription

let package = Package (
    name: "ForgeRock-iOS-SDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "FRCore", targets: ["FRCore"]),
        .library(name: "FRAuth", targets: ["FRAuth"]),
        .library(name: "FRProximity", targets: ["FRProximity"]),
        .library(name: "FRAuthenticator", targets: ["FRAuthenticator"]),
        .library(name: "FRUI", targets: ["FRUI"]),
        .library(name: "FRFacebookSignIn", targets: ["FRFacebookSignIn"]),
        .library(name: "FRGoogleSignIn", targets: ["FRGoogleSignIn"]),
        .library(name: "FRDeviceBinding", targets: ["FRDeviceBinding"]),
        .library(name: "FRCaptchaEnterprise", targets: ["FRCaptchaEnterprise"]),
        .library(name: "PingProtect", targets: ["PingProtect"])
    ],
    dependencies: [
        .package(name: "Facebook", url: "https://github.com/facebook/facebook-ios-sdk.git", .upToNextMinor(from: "16.0.1")),
        .package(name: "GoogleSignIn", url: "https://github.com/google/GoogleSignIn-iOS.git", .upToNextMinor(from: "7.1.0")),
        .package(name: "JOSESwift", url: "https://github.com/airsidemobile/JOSESwift.git", .upToNextMinor(from: "2.4.0")),
        .package(name: "PingOneSignals", url: "https://github.com/pingidentity/pingone-signals-sdk-ios.git", .upToNextMinor(from: "5.2.3")),
        .package(name: "RecaptchaEnterprise", url: "https://github.com/GoogleCloudPlatform/recaptcha-enterprise-mobile-sdk.git", .upToNextMinor(from: "18.6.0"))
    ],
    targets: [
        .target(name: "cFRCore", dependencies: [], path: "FRCore/FRCore/SharedC/Sources"),
        .target(name: "cFRAuthenticator", dependencies: [], path: "FRAuthenticator/FRAuthenticator/SharedC/Sources"),
        .target(name: "FRCore", dependencies: [.target(name: "cFRCore")], path: "FRCore/FRCore", exclude: ["Info.plist", "FRCore.h", "SharedC/Sources/include/JBUtil.h", "SharedC/Sources/JBUtil.c", "SharedC/FRCore.modulemap"], resources: [.copy("PrivacyInfo.xcprivacy")]),
        .target(name: "FRAuth", dependencies: [.target(name: "FRCore"), .product(name: "JOSESwift", package: "JOSESwift")], path: "FRAuth/FRAuth", exclude: ["Info.plist", "FRAuth.h"], resources: [.copy("PrivacyInfo.xcprivacy")]),
        .target(name: "FRProximity", dependencies: [.target(name: "FRAuth")], path: "FRProximity/FRProximity", exclude: ["Info.plist", "FRProximity.h"], resources: [.copy("PrivacyInfo.xcprivacy")]),
        .target(name: "FRAuthenticator", dependencies: [.target(name: "FRCore"), .target(name: "cFRAuthenticator")], path: "FRAuthenticator/FRAuthenticator", exclude: ["Info.plist", "FRAuthenticator.h", "SharedC/Sources/include/base32.h", "SharedC/Sources/base32.c", "SharedC/FRAuthenticator.modulemap"], resources: [.copy("PrivacyInfo.xcprivacy")]),
        .target(name: "FRUI", dependencies: [.target(name: "FRDeviceBinding")], path: "FRUI/FRUI", exclude: ["Info.plist", "FRUI.h"], resources: [.copy("PrivacyInfo.xcprivacy")]),
        .target(name: "FRFacebookSignIn", dependencies: [.target(name: "FRAuth"), .product(name: "FacebookLogin", package: "Facebook")], path: "FRFacebookSignIn/FRFacebookSignIn/Sources", resources: [.copy("../PrivacyInfo.xcprivacy")]),
        .target(name: "FRGoogleSignIn", dependencies: [.target(name: "FRAuth"), .product(name: "GoogleSignIn", package: "GoogleSignIn")], path: "FRGoogleSignIn/FRGoogleSignIn/Sources", resources: [.copy("../PrivacyInfo.xcprivacy")]),
        .target(name: "FRDeviceBinding", dependencies: [.target(name: "FRAuth"), .product(name: "JOSESwift", package: "JOSESwift")], path: "FRDeviceBinding/FRDeviceBinding/Sources", resources: [.copy("../PrivacyInfo.xcprivacy")]),
        .target(name: "FRCaptchaEnterprise", dependencies: [.target(name: "FRAuth"), .product(name: "RecaptchaEnterprise", package: "RecaptchaEnterprise")], path: "FRCaptchaEnterprise/FRCaptchaEnterprise/Sources", resources: [.copy("../PrivacyInfo.xcprivacy")]),
        .target(name: "PingProtect", dependencies: [.target(name: "FRAuth"), .product(name: "PingOneSignals", package: "PingOneSignals")], path: "PingProtect/PingProtect/Sources", resources: [.copy("../PrivacyInfo.xcprivacy")])
    ]
)
