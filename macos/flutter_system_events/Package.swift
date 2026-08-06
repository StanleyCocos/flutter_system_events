// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_system_events",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "flutter-system-events", targets: ["flutter_system_events"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_system_events",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        )
    ]
)
