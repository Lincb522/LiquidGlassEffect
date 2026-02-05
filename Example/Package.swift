// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LiquidGlassDemo",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LiquidGlassDemo",
            targets: ["LiquidGlassDemo"]
        ),
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .target(
            name: "LiquidGlassDemo",
            dependencies: ["LiquidGlassEffect"],
            path: "LiquidGlassDemo"
        ),
    ]
)
