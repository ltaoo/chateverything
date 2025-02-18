// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "LLM",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "LLM",
            targets: ["LLM"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LLM",
            dependencies: []),
    ]
) 