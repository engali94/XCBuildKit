// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCBuildKit",
    platforms: [
          .macOS(.v13)
      ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "XCBuildKit",
            targets: ["XCBuildKit"]),
    ],
    dependencies: [
          .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0")
      ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "XCBuildKit",
            dependencies: ["Rainbow"]
        ),
        .testTarget(
            name: "XCBuildKitTests",
            dependencies: ["XCBuildKit"]
        ),
    ]
)