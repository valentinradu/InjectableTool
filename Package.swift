// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ToledoTool",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(name: "ToledoTool",
                    targets: ["ToledoTool"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            .upToNextMajor(from: "0.50600.1")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "ToledoTool",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "ToledoToolTests",
            dependencies: ["ToledoTool"]
        ),
    ]
)
