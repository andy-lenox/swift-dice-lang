// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DiceLang",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DiceLang",
            targets: ["DiceLang"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // No external dependencies currently
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "DiceLang",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "DiceLangTests",
            dependencies: ["DiceLang"],
            path: "Tests"),
    ]
)