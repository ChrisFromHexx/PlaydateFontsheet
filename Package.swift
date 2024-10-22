// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "fontsheet",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "fontsheet",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
           
        ),
    ]
)
