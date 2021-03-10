// swift-tools-version:5.3
import PackageDescription

let package = Package (
    name: "ForgeRock-iOS-SDK",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "FRCore", targets: ["FRCore"]),
        .library(name: "FRAuth", targets: ["FRAuth"]),
        .library(name: "FRProximity", targets: ["FRProximity"]),
        .library(name: "FRAuthenticator", targets: ["FRAuthenticator"]),
        .library(name: "FRUI", targets: ["FRUI"])
    ],
    targets: [
        .target(name: "cFRAuth", dependencies: [], path: "FRAuth/FRAuth/SharedC/Sources"),
        .target(name: "cFRAuthenticator", dependencies: [], path: "FRAuthenticator/FRAuthenticator/SharedC/Sources"),
        .target(name: "FRCore", path: "FRCore/FRCore", exclude: ["Info.plist", "FRCore.h"]),
        .target(name: "FRAuth", dependencies: [.target(name: "FRCore"), .target(name: "cFRAuth")], path: "FRAuth/FRAuth", exclude: ["Info.plist", "FRAuth.h", "SharedC/Sources/include/JBUtil.h", "SharedC/Sources/JBUtil.c", "SharedC/FRAuth.modulemap"]),
        .target(name: "FRProximity", dependencies: [.target(name: "FRAuth")], path: "FRProximity/FRProximity", exclude: ["Info.plist", "FRProximity.h"]),
        .target(name: "FRAuthenticator", dependencies: [.target(name: "FRAuth"), .target(name: "cFRAuthenticator")], path: "FRAuthenticator/FRAuthenticator", exclude: ["Info.plist", "FRAuthenticator.h", "SharedC/Sources/include/base32.h", "SharedC/Sources/base32.c", "SharedC/FRAuthenticator.modulemap"]),
        .target(name: "FRUI", dependencies: [.target(name: "FRAuth")], path: "FRUI/FRUI", exclude: ["Info.plist", "FRUI.h"])
    ]
)
