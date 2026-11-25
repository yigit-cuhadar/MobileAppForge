// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "forge_live_activity",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "forge-live-activity", targets: ["forge_live_activity"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "forge_live_activity",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
