// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "Pies",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Pies",
            targets: ["Pies"]),
    ],
    targets: [
        .target(
            name: "Pies",
            dependencies: [],
            path: "Sources/Pies"),
        .testTarget(
            name: "PiesTests",
            dependencies: ["Pies"],
            path: "Tests/PiesTests"),
    ]
)
