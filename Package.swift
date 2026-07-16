// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConvEngineChat",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ConvEngineChat", targets: ["ConvEngineChat"])
    ],
    targets: [
        .target(
            name: "ConvEngineChat",
            path: "Sources/ConvEngineChat"
        ),
        .testTarget(
            name: "ConvEngineChatTests",
            dependencies: ["ConvEngineChat"],
            path: "Tests/ConvEngineChatTests"
        )
    ]
)
