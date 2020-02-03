// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IndexDetailViewController",
    platforms: [
        .macOS(.v10_14), .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "IndexDetailViewController",
            targets: ["IndexDetailViewController"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.4.0"),
         .package(url: "https://github.com/elegantchaos/LayoutExtensions.git", from: "1.0.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "IndexDetailViewController",
            dependencies: ["Logger", "LayoutExtensions"]),
        .testTarget(
            name: "IndexDetailViewControllerTests",
            dependencies: ["IndexDetailViewController"]),
    ]
)
