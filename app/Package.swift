// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenPixel",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "OpenPixel", targets: ["OpenPixel"]),
        .library(name: "OpenPixelCore", targets: ["OpenPixelCore"]),
    ],
    dependencies: [
        // Automatic updates (https://sparkle-project.org, MIT licence).
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "OpenPixelCore",
            path: "Sources/OpenPixelCore"
            // Release builds use -O, which keeps Swift's bounds and overflow checks. Don't switch to
            // -Ounchecked: this module parses files from the internet.
        ),
        .executableTarget(
            name: "OpenPixel",
            dependencies: ["OpenPixelCore", .product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/OpenPixel",
            // Inside OpenPixel.app the framework lives in Contents/Frameworks.
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
    ]
)
