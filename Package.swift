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
        .library(name: "PingProtect", targets: ["PingProtect"])
    ],
    dependencies: [
        .package(name: "Facebook", url: "https://github.com/facebook/facebook-ios-sdk.git", .exact("16.0.1")),
        .package(name: "GoogleSignIn", url: "https://github.com/google/GoogleSignIn-iOS.git", .exact("7.0.0")),
        .package(name: "JOSESwift", url: "https://github.com/airsidemobile/JOSESwift.git", .exact("2.4.0")),
        .package(name: "PingOneSignals", url: "https://github.com/pingidentity/pingone-signals-sdk-ios.git", .exact("5.2.0"))
    ],
    targets: [
        .target(name: "cFRCore", dependencies: [], path: "FRCore/FRCore/SharedC/Sources"),
        .target(name: "cFRAuthenticator", dependencies: [], path: "FRAuthenticator/FRAuthenticator/SharedC/Sources"),
        .target(name: "FRCore", dependencies: [.target(name: "cFRCore")], path: "FRCore/FRCore", exclude: ["Info.plist", "FRCore.h", "SharedC/Sources/include/JBUtil.h", "SharedC/Sources/JBUtil.c", "SharedC/FRCore.modulemap"]),
        .target(name: "FRAuth", dependencies: [.target(name: "FRCore"), .product(name: "JOSESwift", package: "JOSESwift")], path: "FRAuth/FRAuth", exclude: ["Info.plist", "FRAuth.h"]),
        .target(name: "FRProximity", dependencies: [.target(name: "FRAuth")], path: "FRProximity/FRProximity", exclude: ["Info.plist", "FRProximity.h"]),
        .target(name: "FRAuthenticator", dependencies: [.target(name: "FRCore"), .target(name: "cFRAuthenticator")], path: "FRAuthenticator/FRAuthenticator", exclude: ["Info.plist", "FRAuthenticator.h", "SharedC/Sources/include/base32.h", "SharedC/Sources/base32.c", "SharedC/FRAuthenticator.modulemap"]),
        .target(name: "FRUI", dependencies: [.target(name: "FRDeviceBinding")], path: "FRUI/FRUI", exclude: ["Info.plist", "FRUI.h"]),
        .target(name: "FRFacebookSignIn", dependencies: [.target(name: "FRAuth"), .product(name: "FacebookLogin", package: "Facebook")], path: "FRFacebookSignIn/FRFacebookSignIn/Sources"),
        .target(name: "FRGoogleSignIn", dependencies: [.target(name: "FRAuth"), .product(name: "GoogleSignIn", package: "GoogleSignIn")], path: "FRGoogleSignIn/FRGoogleSignIn/Sources"),
        .target(name: "FRDeviceBinding", dependencies: [.target(name: "FRAuth"), .product(name: "JOSESwift", package: "JOSESwift")], path: "FRDeviceBinding/FRDeviceBinding/Sources"),
        .target(name: "PingProtect", dependencies: [.target(name: "FRAuth"), .product(name: "PingOneSignals", package: "PingOneSignals")], path: "PingProtect/PingProtect/Sources")
    ]
)
