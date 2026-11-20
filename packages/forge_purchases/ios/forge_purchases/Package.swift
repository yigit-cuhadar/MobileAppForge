// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "forge_purchases",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "forge-purchases", targets: ["forge_purchases"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "forge_purchases",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
