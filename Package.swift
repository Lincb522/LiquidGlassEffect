// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LiquidGlassEffect",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "LiquidGlassEffect",
            targets: ["LiquidGlassEffect"]
        ),
    ],
    targets: [
        .target(
            name: "LiquidGlassEffect",
            path: "Sources/LiquidGlassEffect",
            resources: [
                .process("LiquidGlassShader.metal")
            ]
        ),
    ]
)
