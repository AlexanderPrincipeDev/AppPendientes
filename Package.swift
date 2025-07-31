// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "AppPendientes",
    products: [
        .library(name: "AppCore", targets: ["AppCore"]),
    ],
    targets: [
        .target(
            name: "AppCore",
            path: ".",
            sources: ["GamificationManager.swift"]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"],
            path: "Tests"
        )
    ]
)
